from decimal import Decimal

from rest_framework import serializers

from apps.core.i18n import current_lang

from .models import Order
from .services import item_display, order_timeline


class CartItemSerializer(serializers.Serializer):
    sku = serializers.CharField(max_length=40)
    qty = serializers.DecimalField(
        max_digits=10, decimal_places=3, min_value=Decimal("0.001"), max_value=Decimal("1000")
    )
    expected_price = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, allow_null=True)


class QuoteRequestSerializer(serializers.Serializer):
    items = CartItemSerializer(many=True, max_length=100)
    coupon = serializers.CharField(max_length=30, required=False, allow_null=True, allow_blank=True)
    zone = serializers.CharField(max_length=50, required=False, allow_null=True, allow_blank=True)
    method = serializers.ChoiceField(choices=Order.Method.choices, default=Order.Method.DELIVERY)


class OrderCreateSerializer(serializers.Serializer):
    items = CartItemSerializer(many=True, min_length=1, max_length=100)
    coupon = serializers.CharField(max_length=30, required=False, allow_null=True, allow_blank=True)
    method = serializers.ChoiceField(choices=Order.Method.choices)
    address_id = serializers.IntegerField(required=False, allow_null=True)
    slot_id = serializers.CharField(max_length=40)
    payment_method = serializers.ChoiceField(choices=Order.PaymentMethod.choices)
    notes = serializers.CharField(max_length=300, required=False, allow_blank=True, default="")


class OrderSerializer(serializers.Serializer):
    """Customer view of an order (matches the storefront's Order type)."""

    id = serializers.IntegerField()
    number = serializers.CharField()
    status = serializers.CharField()
    created_at = serializers.DateTimeField()
    method = serializers.CharField()
    payment_method = serializers.CharField()
    payment_status = serializers.CharField()
    items = serializers.ListField(child=serializers.DictField())
    subtotal = serializers.FloatField()
    coupon_discount = serializers.FloatField()
    delivery_fee = serializers.FloatField()
    total = serializers.FloatField()
    coupon = serializers.CharField(allow_null=True)
    notes = serializers.CharField()
    address = serializers.DictField(allow_null=True)
    slot = serializers.DictField(allow_null=True)
    timeline = serializers.ListField(child=serializers.DictField())

    def to_representation(self, order: Order):
        address = None
        if order.address:
            snap = order.address
            address = {
                **{k: v for k, v in snap.items() if not k.startswith("zone_name")},
                "zone_name": snap.get(f"zone_name_{current_lang()}") or snap.get("zone_name_ar", ""),
                "is_default": False,
            }
        return {
            "id": order.pk,
            "number": order.number,
            "status": order.status,
            "created_at": serializers.DateTimeField().to_representation(order.created_at),
            "method": order.method,
            "payment_method": order.payment_method,
            "payment_status": order.payment_status,
            "items": [item_display(item) for item in order.items.all()],
            "subtotal": order.subtotal,
            "coupon_discount": order.coupon_discount,
            "delivery_fee": order.delivery_fee,
            "total": order.total,
            "coupon": order.coupon_code or None,
            "notes": order.notes,
            "address": address,
            "slot": {
                "date": order.slot_date.isoformat() if order.slot_date else None,
                "start": f"{order.slot_start:%H:%M}" if order.slot_start else "",
                "end": f"{order.slot_end:%H:%M}" if order.slot_end else "",
                "express": order.is_express,
            },
            "timeline": [
                {**step, "at": serializers.DateTimeField().to_representation(step["at"]) if step["at"] else None}
                for step in order_timeline(order)
            ],
        }


class OrderCreateResponseSerializer(serializers.Serializer):
    order = OrderSerializer()
    payment_url = serializers.CharField(allow_null=True)
