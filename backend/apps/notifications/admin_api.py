from rest_framework import filters, mixins, serializers, viewsets

from apps.core.pagination import AdminPagination
from apps.core.permissions import StaffModelPermissions

from .models import NotificationLog


class NotificationLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationLog
        fields = ["id", "user", "channel", "event", "recipient", "subject", "body", "status", "error", "created_at"]


class NotificationLogAdminViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    """Sent messages log (AD-501)."""

    serializer_class = NotificationLogSerializer
    permission_classes = [StaffModelPermissions]
    pagination_class = AdminPagination
    queryset = NotificationLog.objects.all()
    filterset_fields = ["channel", "status", "event"]
    filter_backends = [filters.SearchFilter, *viewsets.GenericViewSet.filter_backends]
    search_fields = ["recipient"]
