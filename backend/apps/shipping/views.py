from drf_spectacular.utils import extend_schema
from rest_framework import serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.cache import cached_catalog
from apps.core.i18n import tr

from .models import StoreSettings, Zone
from .services import delivery_slots


class ZoneOutSerializer(serializers.Serializer):
    id = serializers.CharField()
    name = serializers.CharField()
    fee = serializers.FloatField()


class PickupSerializer(serializers.Serializer):
    name = serializers.CharField()
    address = serializers.CharField()
    hours = serializers.CharField()


class DeliveryInfoSerializer(serializers.Serializer):
    zones = ZoneOutSerializer(many=True)
    free_delivery_threshold = serializers.FloatField()
    min_order = serializers.FloatField()
    pickup = PickupSerializer()
    pickup_enabled = serializers.BooleanField()


class DeliveryInfoView(APIView):
    """Delivery zones with fees, free-delivery threshold, minimum order and the pickup point."""

    @extend_schema(responses=DeliveryInfoSerializer)
    def get(self, request):
        return Response(cached_catalog("delivery-info", self.build, timeout=600))

    @staticmethod
    def build():
        rules = StoreSettings.load()
        return {
            "zones": [{"id": z.code, "name": tr(z, "name"), "fee": z.fee} for z in Zone.objects.filter(is_active=True)],
            "free_delivery_threshold": rules.free_delivery_threshold,
            "min_order": rules.min_order,
            "pickup": {
                "name": tr(rules, "pickup_name"),
                "address": tr(rules, "pickup_address"),
                "hours": tr(rules, "pickup_hours"),
            },
            "pickup_enabled": rules.pickup_enabled,
        }


class DeliverySlotsView(APIView):
    """Delivery windows for the next days. Full or too-soon windows are marked unavailable."""

    @extend_schema(responses={200: {"type": "array", "items": {"type": "object"}}})
    def get(self, request):
        return Response(delivery_slots())
