"""Staff API for orders (AD-601) and the dashboard (BE-606)."""

from datetime import timedelta

from django.db.models import Avg, Count, F, Sum
from django.db.models.functions import TruncDate
from django.utils import timezone
from django_filters import rest_framework as df
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import filters, mixins, serializers, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.catalog.models import Variant
from apps.core.pagination import AdminPagination
from apps.core.permissions import StaffModelPermissions, require_perms

from .models import Order, OrderItem, OrderStatusHistory
from .serializers import OrderSerializer
from .services import transition


class OrderItemAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        exclude = ["order"]


class OrderHistoryAdminSerializer(serializers.ModelSerializer):
    actor = serializers.StringRelatedField()

    class Meta:
        model = OrderStatusHistory
        fields = ["status", "note", "actor", "created_at"]


class OrderAdminSerializer(serializers.ModelSerializer):
    customer = serializers.SerializerMethodField()
    items = OrderItemAdminSerializer(many=True, read_only=True)
    history = OrderHistoryAdminSerializer(many=True, read_only=True)
    allowed_transitions = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = "__all__"

    def get_customer(self, order) -> dict:
        return {"id": order.user_id, "phone": order.user.phone, "name": order.user.name}

    def get_allowed_transitions(self, order) -> list[str]:
        return sorted(order.allowed_transitions())


class OrderListAdminSerializer(serializers.ModelSerializer):
    customer = serializers.SerializerMethodField()
    items_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Order
        fields = [
            "id",
            "number",
            "status",
            "method",
            "payment_method",
            "payment_status",
            "total",
            "slot_date",
            "slot_start",
            "is_express",
            "created_at",
            "customer",
            "items_count",
        ]

    def get_customer(self, order) -> dict:
        return {"id": order.user_id, "phone": order.user.phone, "name": order.user.name}


class OrderFilter(df.FilterSet):
    date_from = df.DateFilter(field_name="created_at", lookup_expr="date__gte")
    date_to = df.DateFilter(field_name="created_at", lookup_expr="date__lte")
    customer = df.NumberFilter(field_name="user_id")

    class Meta:
        model = Order
        fields = ["status", "method", "payment_method", "payment_status", "slot_date", "is_express"]


class TransitionSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Order.Status.choices)
    note = serializers.CharField(max_length=300, required=False, allow_blank=True, default="")


class OrderAdminViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [StaffModelPermissions]
    pagination_class = AdminPagination
    filterset_class = OrderFilter
    filter_backends = [df.DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["number", "user__phone", "user__name"]
    ordering_fields = ["created_at", "total", "slot_date"]

    def get_queryset(self):
        qs = Order.objects.select_related("user")
        if self.action == "list":
            return qs.annotate(items_count=Count("items")).order_by("-created_at")
        return qs.prefetch_related("items", "history__actor")

    def get_serializer_class(self):
        return OrderListAdminSerializer if self.action == "list" else OrderAdminSerializer

    @extend_schema(request=TransitionSerializer, responses=OrderAdminSerializer)
    @action(detail=True, methods=["post"], permission_classes=[require_perms("orders.change_order")])
    def transition(self, request, pk=None):
        """Move the order to its next status. The customer gets an SMS for key steps."""
        data = TransitionSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        order = transition(
            self.get_object(), data.validated_data["status"], actor=request.user, note=data.validated_data["note"]
        )
        return Response(OrderAdminSerializer(self.get_queryset().get(pk=order.pk)).data)

    @action(detail=True, methods=["get"])
    def customer_view(self, request, pk=None):
        """The order exactly as the customer sees it."""
        return Response(OrderSerializer(self.get_object()).data)


PERIODS = {"today": 0, "7d": 6, "30d": 29, "90d": 89}


class DashboardView(APIView):
    """Sales, orders, average order value, open orders and stock alerts for a period."""

    permission_classes = [require_perms("orders.view_order")]

    @extend_schema(
        parameters=[OpenApiParameter("period", enum=list(PERIODS), default="7d")], responses={200: {"type": "object"}}
    )
    def get(self, request):
        period = request.query_params.get("period", "7d")
        days = PERIODS.get(period, 6)
        today = timezone.localdate()
        start = today - timedelta(days=days)
        orders = Order.objects.filter(created_at__date__gte=start)
        counted = orders.exclude(status__in=[Order.Status.CANCELLED, Order.Status.PENDING_PAYMENT])
        totals = counted.aggregate(sales=Sum("total"), count=Count("id"), average=Avg("total"))
        open_statuses = [
            Order.Status.PLACED,
            Order.Status.CONFIRMED,
            Order.Status.PREPARING,
            Order.Status.OUT_FOR_DELIVERY,
            Order.Status.READY_FOR_PICKUP,
        ]
        by_day = {
            row["day"]: row
            for row in counted.annotate(day=TruncDate("created_at"))
            .values("day")
            .annotate(sales=Sum("total"), orders=Count("id"))
        }
        top_products = (
            OrderItem.objects.filter(order__in=counted)
            .values("product_id", "name_ar", "name_en")
            .annotate(qty=Sum("qty"), revenue=Sum("line_total"))
            .order_by("-revenue")[:10]
        )
        low_stock = Variant.objects.filter(
            is_active=True, product__is_active=True, stock__lte=F("low_stock_threshold")
        ).select_related("product")
        return Response(
            {
                "period": period,
                "from": start,
                "to": today,
                "sales": totals["sales"] or 0,
                "orders": totals["count"],
                "average_order_value": round(totals["average"] or 0, 2),
                "open_orders": Order.objects.filter(status__in=open_statuses).count(),
                "pending_payment": Order.objects.filter(status=Order.Status.PENDING_PAYMENT).count(),
                "cancelled": orders.filter(status=Order.Status.CANCELLED).count(),
                "new_customers": User.objects.filter(is_staff=False, date_joined__date__gte=start).count(),
                "by_status": dict(orders.values_list("status").annotate(n=Count("id"))),
                "sales_by_day": [
                    {
                        "date": day,
                        "sales": by_day.get(day, {}).get("sales") or 0,
                        "orders": by_day.get(day, {}).get("orders") or 0,
                    }
                    for day in (start + timedelta(days=i) for i in range(days + 1))
                ],
                "top_products": list(top_products),
                "low_stock": [
                    {
                        "variant_id": v.pk,
                        "sku": v.sku,
                        "product": v.product.name_en,
                        "label": v.label_en,
                        "stock": v.stock,
                        "threshold": v.low_stock_threshold,
                    }
                    for v in low_stock[:50]
                ],
                "low_stock_count": low_stock.count(),
            }
        )
