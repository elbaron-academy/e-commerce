"""Customer chat API (/api/v1/support/chat/).

The customer sees one continuous chat. Clients poll `GET chat/?after=<last id>`
every few seconds while the chat is open; it returns only new messages.
"""

from django.urls import NoReverseMatch, reverse
from drf_spectacular.utils import OpenApiParameter, extend_schema, inline_serializer
from rest_framework import serializers, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.core.exceptions import ApiError
from apps.core.i18n import t
from apps.orders.models import Order

from . import services
from .models import Conversation
from .serializers import ConversationRefSerializer, MessageSerializer, ReadSerializer, SendMessageSerializer

ChatState = inline_serializer(
    "ChatState",
    {
        "conversation": ConversationRefSerializer(allow_null=True),
        "messages": MessageSerializer(many=True),
        "has_older": serializers.BooleanField(),
        "unread": serializers.IntegerField(),
    },
)
ChatUnread = inline_serializer("ChatUnread", {"unread": serializers.IntegerField()})


def int_param(request, name: str) -> int | None:
    value = request.query_params.get(name)
    if value in (None, ""):
        return None
    try:
        return max(int(value), 0)
    except ValueError:
        raise ApiError(f"`{name}` must be a number.", field=name) from None


def inbox_url(request) -> str:
    try:
        return request.build_absolute_uri(reverse("admin:support_conversation_inbox"))
    except NoReverseMatch:
        return ""


class ChatView(APIView):
    """The signed-in customer's chat: latest messages, new ones (`after`) or older ones (`before`)."""

    permission_classes = [IsAuthenticated]

    @extend_schema(
        parameters=[
            OpenApiParameter("after", int, description="Only messages newer than this id (polling)"),
            OpenApiParameter("before", int, description="Older messages before this id (history)"),
        ],
        responses=ChatState,
    )
    def get(self, request):
        user = request.user
        messages, has_older = services.page(
            services.customer_messages(user), after=int_param(request, "after"), before=int_param(request, "before")
        )
        conversation = Conversation.objects.filter(customer=user).order_by("-id").first()
        return Response(
            {
                "conversation": ConversationRefSerializer(conversation).data if conversation else None,
                "messages": MessageSerializer(messages, many=True, context={"request": request}).data,
                "has_older": has_older,
                "unread": services.customer_unread(user),
            }
        )


class ChatMessageView(APIView):
    """Sends a message (text, a photo, or both). JSON, or multipart when there's a photo."""

    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "chat"

    @extend_schema(request=SendMessageSerializer, responses={201: MessageSerializer})
    def post(self, request):
        data = SendMessageSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        order = None
        if order_id := data.validated_data.get("order"):
            order = Order.objects.filter(pk=order_id, user=request.user).first()
            if order is None:
                raise ApiError(t("الطلب ده مش موجود.", "Order not found."), field="order")
        message = services.send_customer_message(
            request.user,
            body=data.validated_data["body"],
            image=data.validated_data.get("image"),
            order=order,
            inbox_url=inbox_url(request),
        )
        return Response(MessageSerializer(message, context={"request": request}).data, status=status.HTTP_201_CREATED)


class ChatReadView(APIView):
    """Marks staff messages as read, up to `message_id` (default: all)."""

    permission_classes = [IsAuthenticated]

    @extend_schema(request=ReadSerializer, responses=ChatUnread)
    def post(self, request):
        data = ReadSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        services.mark_read_by_customer(request.user, data.validated_data.get("message_id"))
        return Response({"unread": services.customer_unread(request.user)})


class ChatUnreadView(APIView):
    """Unread staff messages, for the badge on the chat button."""

    permission_classes = [IsAuthenticated]

    @extend_schema(responses=ChatUnread)
    def get(self, request):
        return Response({"unread": services.customer_unread(request.user)})
