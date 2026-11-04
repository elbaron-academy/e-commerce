from django.contrib import admin

from .models import DeliveryWindow, StoreSettings, Zone


@admin.register(Zone)
class ZoneAdmin(admin.ModelAdmin):
    list_display = ["name_en", "name_ar", "code", "fee", "is_active", "sort_order"]
    list_editable = ["fee", "is_active", "sort_order"]


@admin.register(DeliveryWindow)
class DeliveryWindowAdmin(admin.ModelAdmin):
    list_display = ["__str__", "capacity", "is_active"]


@admin.register(StoreSettings)
class StoreSettingsAdmin(admin.ModelAdmin):
    def has_add_permission(self, request):
        return not StoreSettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False
