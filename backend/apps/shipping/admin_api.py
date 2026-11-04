from rest_framework import serializers, viewsets
from rest_framework.generics import RetrieveUpdateAPIView

from apps.core.permissions import StaffModelPermissions

from .models import DeliveryWindow, StoreSettings, Zone


class ZoneAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = Zone
        fields = ["id", "code", "name_ar", "name_en", "fee", "is_active", "sort_order"]


class DeliveryWindowAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryWindow
        fields = ["id", "start_time", "end_time", "capacity", "is_active"]

    def validate(self, attrs):
        start = attrs.get("start_time", getattr(self.instance, "start_time", None))
        end = attrs.get("end_time", getattr(self.instance, "end_time", None))
        if start and end and end <= start:
            raise serializers.ValidationError({"end_time": "The window must end after it starts."})
        return attrs


class StoreSettingsAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = StoreSettings
        exclude = ["id"]


class ZoneAdminViewSet(viewsets.ModelViewSet):
    serializer_class = ZoneAdminSerializer
    permission_classes = [StaffModelPermissions]
    queryset = Zone.objects.all()
    pagination_class = None


class DeliveryWindowAdminViewSet(viewsets.ModelViewSet):
    serializer_class = DeliveryWindowAdminSerializer
    permission_classes = [StaffModelPermissions]
    queryset = DeliveryWindow.objects.all()
    pagination_class = None


class StoreSettingsAdminView(RetrieveUpdateAPIView):
    """Store rules: free delivery threshold, minimum order, COD limit, slots, pickup (AD-402)."""

    serializer_class = StoreSettingsAdminSerializer
    permission_classes = [StaffModelPermissions]
    queryset = StoreSettings.objects.all()
    http_method_names = ["get", "patch"]

    def get_object(self):
        obj = StoreSettings.load()
        self.check_object_permissions(self.request, obj)
        return obj
