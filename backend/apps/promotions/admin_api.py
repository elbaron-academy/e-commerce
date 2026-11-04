from django.db.models import Count, DecimalField, Sum, Value
from django.db.models.functions import Coalesce
from rest_framework import serializers, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.core.pagination import AdminPagination
from apps.core.permissions import StaffModelPermissions

from .models import Coupon


class CouponAdminSerializer(serializers.ModelSerializer):
    used_count = serializers.IntegerField(read_only=True)
    total_discount = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = Coupon
        fields = "__all__"

    def validate(self, attrs):
        ctype = attrs.get("type", getattr(self.instance, "type", None))
        value = attrs.get("value", getattr(self.instance, "value", 0))
        if ctype == Coupon.Type.PERCENT and not (0 < value <= 100):
            raise serializers.ValidationError({"value": "Percentage must be between 1 and 100."})
        if ctype == Coupon.Type.FIXED and value <= 0:
            raise serializers.ValidationError({"value": "Enter the amount off."})
        starts = attrs.get("starts_at", getattr(self.instance, "starts_at", None))
        ends = attrs.get("ends_at", getattr(self.instance, "ends_at", None))
        if starts and ends and ends <= starts:
            raise serializers.ValidationError({"ends_at": "The coupon must end after it starts."})
        return attrs


class CouponAdminViewSet(viewsets.ModelViewSet):
    """Coupons with usage report (AD-401)."""

    serializer_class = CouponAdminSerializer
    permission_classes = [StaffModelPermissions]
    pagination_class = AdminPagination
    filterset_fields = ["type", "is_active"]

    def get_queryset(self):
        return Coupon.objects.annotate(
            used_count=Count("redemptions"),
            total_discount=Coalesce(Sum("redemptions__discount"), Value(0), output_field=DecimalField()),
        ).order_by("-created_at")

    @action(detail=True, methods=["get"])
    def redemptions(self, request, pk=None):
        coupon = self.get_object()
        rows = coupon.redemptions.select_related("order", "user").order_by("-created_at")[:500]
        return Response(
            [
                {
                    "order": r.order.number,
                    "customer": r.user.phone,
                    "discount": r.discount,
                    "order_total": r.order.total,
                    "at": r.created_at,
                }
                for r in rows
            ]
        )
