"""Role-based access for the staff API (BE-105): Django groups + model permissions."""

from rest_framework.permissions import BasePermission, DjangoModelPermissions


class IsStaff(BasePermission):
    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.is_staff and user.is_active)


class StaffModelPermissions(DjangoModelPermissions):
    """Staff only; reads need `view_*`, writes need `add_*`/`change_*`/`delete_*`."""

    perms_map = {
        "GET": ["%(app_label)s.view_%(model_name)s"],
        "OPTIONS": [],
        "HEAD": ["%(app_label)s.view_%(model_name)s"],
        "POST": ["%(app_label)s.add_%(model_name)s"],
        "PUT": ["%(app_label)s.change_%(model_name)s"],
        "PATCH": ["%(app_label)s.change_%(model_name)s"],
        "DELETE": ["%(app_label)s.delete_%(model_name)s"],
    }

    def has_permission(self, request, view):
        return IsStaff().has_permission(request, view) and super().has_permission(request, view)


def require_perms(*perms: str):
    """Permission class for custom actions: `permission_classes=[require_perms('orders.change_order')]`."""

    class _HasPerms(BasePermission):
        def has_permission(self, request, view):
            return IsStaff().has_permission(request, view) and request.user.has_perms(perms)

    _HasPerms.__name__ = f"HasPerms({', '.join(perms)})"
    return _HasPerms
