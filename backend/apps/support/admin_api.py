"""Staff API for the support inbox (/api/v1/admin/support/conversations/).

Also used by the inbox page in the Django admin, so it accepts the admin session
(with its CSRF token) as well as JWT.
"""

from django.db.models import Count, F, Q
from django_filters import rest_framework as df
from drf_spectacular.utils import OpenApiParameter, extend_schema, extend_schema_field, inline_serializer
from rest_framework import filters, mixins, serializers, status, viewsets
from rest_framework.authentication import SessionAuthentication
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework_simplejwt.authentication import JWTAuthentication

from apps.accounts.models import User
from apps.core.exceptions import ApiError
from apps.core.pagination import AdminPagination
from apps.core.permissions import StaffModelPermissions, require_perms
from apps.orders.models import Order

from . import services
from .models import Conversation
from .serializers import MessageSerializer, ReadSerializer, SendMessageSerializer
from .views import int_param


def person(user) -> dict | None:
    if not user:
        return None
    return {"id": user.pk, "name": user.name, "phone": user.phone}


class PersonSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    phone = serializers.CharField()


class ConversationListAdminSerializer(serializers.ModelSerializer):
    customer = serializers.SerializerMethodField()
    assigned_to = serializers.SerializerMethodField()
    last_message = MessageSerializer(read_only=True)
    unread = serializers.IntegerField(read_only=True, help_text="Customer messages no one on staff has read")

    class Meta:
        model = Conversation
        fields = [
            "id",
            "status",
            "customer",
            "assigned_to",
            "last_message",
            "last_message_at",
            "unread",
            "staff_last_read",
            "customer_last_read",
            "created_at",
            "closed_at",
        ]

    @extend_schema_field(PersonSerializer)
    def get_customer(self, conversation) -> dict:
        return person(conversation.customer)

    @extend_schema_field(PersonSerializer(allow_null=True))
    def get_assigned_to(self, conversation) -> dict | None:
        return person(conversation.assigned_to)


class ConversationFilter(df.FilterSet):
    assigned = df.CharFilter(method="filter_assigned", help_text="`me`, `none` or a staff id")
    needs_reply = df.BooleanFilter(method="filter_needs_reply")
    customer = df.NumberFilter(field_name="customer_id")

    class Meta:
        model = Conversation
        fields = ["status"]

    def filter_assigned(self, qs, name, value):
        if value == "me":
            return qs.filter(assigned_to=self.request.user)
        if value == "none":
            return qs.filter(assigned_to__isnull=True)
        return qs.filter(assigned_to_id=value) if value.isdigit() else qs

    def filter_needs_reply(self, qs, name, value):
        needs = Q(**services.staff_unread_filter())
        return qs.filter(needs) if value else qs.exclude(needs)


class AssignSerializer(serializers.Serializer):
    user = serializers.IntegerField(allow_null=True, help_text="Staff id, or null to unassign")


class ConversationAdminViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    authentication_classes = [JWTAuthentication, SessionAuthentication]
    permission_classes = [StaffModelPermissions]
    pagination_class = AdminPagination
    serializer_class = ConversationListAdminSerializer
    filterset_class = ConversationFilter
    filter_backends = [df.DjangoFilterBackend, filters.SearchFilter]
    search_fields = ["customer__phone", "customer__name"]

    def get_queryset(self):
        return (
            Conversation.objects.select_related(
                "customer", "assigned_to", "last_message__sender", "last_message__order"
            )
            .annotate(
                unread=Count(
                    "messages",
                    filter=Q(messages__from_staff=False, messages__id__gt=F("staff_last_read")),
                )
            )
            .order_by(F("last_message_at").desc(nulls_last=True), "-id")
        )

    def detail_payload(self, conversation, *, after=None, before=None) -> dict:
        request = self.request
        messages, has_older = services.page(
            conversation.messages.select_related("sender", "order"), after=after, before=before
        )
        orders = Order.objects.filter(user_id=conversation.customer_id).order_by("-created_at")[:5]
        return {
            **ConversationListAdminSerializer(conversation, context={"request": request}).data,
            "messages": MessageSerializer(messages, many=True, context={"request": request}).data,
            "has_older": has_older,
            "orders": [
                {
                    "id": o.pk,
                    "number": o.number,
                    "status": o.status,
                    "total": o.total,
                    "created_at": o.created_at,
                }
                for o in orders
            ],
        }

    @extend_schema(
        parameters=[
            OpenApiParameter("after", int, description="Only messages newer than this id (polling)"),
            OpenApiParameter("before", int, description="Older messages before this id"),
        ],
        responses=inline_serializer(
            "ConversationAdminDetail",
            {
                "id": serializers.IntegerField(),
                "status": serializers.CharField(),
                "customer": PersonSerializer(),
                "assigned_to": PersonSerializer(allow_null=True),
                "messages": MessageSerializer(many=True),
                "has_older": serializers.BooleanField(),
                "orders": serializers.ListField(child=serializers.DictField()),
            },
        ),
    )
    def retrieve(self, request, *args, **kwargs):
        """The conversation with its latest messages, new ones (`after`) or older ones (`before`)."""
        return Response(
            self.detail_payload(
                self.get_object(), after=int_param(request, "after"), before=int_param(request, "before")
            )
        )

    @extend_schema(request=SendMessageSerializer, responses={201: MessageSerializer})
    @action(detail=True, methods=["post"], permission_classes=[require_perms("support.add_message")])
    def messages(self, request, pk=None):
        """Replies to the customer. Assigns the conversation to you if nobody has it."""
        conversation = self.get_object()
        data = SendMessageSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        order = None
        if order_id := data.validated_data.get("order"):
            order = Order.objects.filter(pk=order_id, user_id=conversation.customer_id).first()
            if order is None:
                raise ApiError("Order not found for this customer.", field="order")
        message = services.send_staff_message(
            conversation,
            request.user,
            body=data.validated_data["body"],
            image=data.validated_data.get("image"),
            order=order,
        )
        return Response(MessageSerializer(message, context={"request": request}).data, status=status.HTTP_201_CREATED)

    @extend_schema(request=ReadSerializer, responses={204: None})
    @action(detail=True, methods=["post"], permission_classes=[require_perms("support.view_conversation")])
    def read(self, request, pk=None):
        """Marks the customer's messages as read (shows them a double tick)."""
        data = ReadSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        services.mark_read_by_staff(self.get_object(), data.validated_data.get("message_id"))
        return Response(status=status.HTTP_204_NO_CONTENT)

    @extend_schema(request=AssignSerializer, responses=ConversationListAdminSerializer)
    @action(detail=True, methods=["post"], permission_classes=[require_perms("support.change_conversation")])
    def assign(self, request, pk=None):
        data = AssignSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        conversation = self.get_object()
        user_id = data.validated_data["user"]
        assignee = None
        if user_id is not None:
            assignee = User.objects.filter(pk=user_id, is_staff=True, is_active=True).first()
            if assignee is None:
                raise ApiError("Staff member not found.", field="user")
        conversation.assigned_to = assignee
        conversation.save(update_fields=["assigned_to", "updated_at"])
        return Response(self.get_serializer(self.get_queryset().get(pk=conversation.pk)).data)

    @extend_schema(request=None, responses=ConversationListAdminSerializer)
    @action(detail=True, methods=["post"], permission_classes=[require_perms("support.change_conversation")])
    def close(self, request, pk=None):
        """Ends the conversation. The customer's next message starts a new one."""
        conversation = services.close_conversation(self.get_object(), request.user)
        return Response(self.get_serializer(self.get_queryset().get(pk=conversation.pk)).data)

    @extend_schema(request=None, responses=ConversationListAdminSerializer)
    @action(detail=True, methods=["post"], permission_classes=[require_perms("support.change_conversation")])
    def reopen(self, request, pk=None):
        conversation = services.reopen_conversation(self.get_object())
        return Response(self.get_serializer(self.get_queryset().get(pk=conversation.pk)).data)

    @extend_schema(
        responses=inline_serializer(
            "SupportSummary",
            {
                "open": serializers.IntegerField(),
                "needs_reply": serializers.IntegerField(),
                "mine": serializers.IntegerField(),
            },
        )
    )
    @action(detail=False, methods=["get"])
    def summary(self, request):
        """Counts for the inbox badges."""
        open_qs = Conversation.objects.filter(status=Conversation.Status.OPEN)
        return Response(
            {
                "open": open_qs.count(),
                "needs_reply": Conversation.objects.filter(**services.staff_unread_filter()).count(),
                "mine": open_qs.filter(assigned_to=request.user).count(),
            }
        )
