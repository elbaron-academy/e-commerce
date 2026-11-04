from django.contrib.auth.models import Group, Permission
from django.db.models import Count, DecimalField, Q, Sum, Value
from django.db.models.functions import Coalesce
from drf_spectacular.utils import extend_schema
from rest_framework import filters, mixins, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.pagination import AdminPagination
from apps.core.permissions import IsStaff, StaffModelPermissions

from .models import User
from .serializers import CustomerAdminSerializer, RoleSerializer, StaffUserSerializer

APP_LABELS = ["accounts", "catalog", "orders", "payments", "promotions", "shipping", "notifications"]


class CustomerAdminViewSet(
    mixins.ListModelMixin, mixins.RetrieveModelMixin, mixins.UpdateModelMixin, viewsets.GenericViewSet
):
    """Customers: profile, order stats, disable account, internal notes (BE-607)."""

    serializer_class = CustomerAdminSerializer
    permission_classes = [StaffModelPermissions]
    pagination_class = AdminPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["phone", "name", "email"]
    ordering_fields = ["date_joined", "orders_count", "total_spent"]
    http_method_names = ["get", "patch"]

    def get_queryset(self):
        paid = ~Q(orders__status="cancelled")
        return (
            User.objects.filter(is_staff=False)
            .annotate(
                orders_count=Count("orders", filter=paid),
                total_spent=Coalesce(Sum("orders__total", filter=paid), Value(0), output_field=DecimalField()),
            )
            .order_by("-date_joined")
        )


class StaffUserAdminViewSet(viewsets.ModelViewSet):
    """Staff accounts and their roles (AD-102)."""

    serializer_class = StaffUserSerializer
    permission_classes = [StaffModelPermissions]
    pagination_class = AdminPagination
    queryset = User.objects.filter(is_staff=True).prefetch_related("groups")
    filter_backends = [filters.SearchFilter]
    search_fields = ["phone", "name"]

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save(update_fields=["is_active"])


class RoleAdminViewSet(viewsets.ModelViewSet):
    """Roles = Django groups with permissions like "orders.change_order"."""

    serializer_class = RoleSerializer
    permission_classes = [StaffModelPermissions]
    pagination_class = None
    queryset = Group.objects.prefetch_related("permissions__content_type").order_by("name")


class PermissionListView(APIView):
    permission_classes = [IsStaff]

    @extend_schema(responses={200: {"type": "array", "items": {"type": "object"}}})
    def get(self, request):
        perms = Permission.objects.filter(content_type__app_label__in=APP_LABELS).select_related("content_type")
        return Response(
            [
                {"code": f"{p.content_type.app_label}.{p.codename}", "name": p.name}
                for p in perms.order_by("content_type__app_label", "codename")
            ]
        )
