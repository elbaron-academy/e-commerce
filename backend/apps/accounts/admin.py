from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import Address, OTPCode, User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    ordering = ["-date_joined"]
    list_display = ["phone", "name", "email", "is_staff", "is_active", "date_joined"]
    list_filter = ["is_staff", "is_active", "language"]
    search_fields = ["phone", "name", "email"]
    fieldsets = [
        (None, {"fields": ["phone", "password"]}),
        ("Profile", {"fields": ["name", "email", "language", "notes"]}),
        ("Access", {"fields": ["is_active", "is_staff", "is_superuser", "groups", "user_permissions"]}),
        ("Dates", {"fields": ["last_login", "date_joined"]}),
    ]
    add_fieldsets = [(None, {"classes": ["wide"], "fields": ["phone", "password1", "password2", "is_staff"]})]


@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    list_display = ["user", "zone", "area", "street", "is_default"]
    list_filter = ["zone"]
    search_fields = ["user__phone", "area", "street"]
    raw_id_fields = ["user"]


@admin.register(OTPCode)
class OTPCodeAdmin(admin.ModelAdmin):
    list_display = ["phone", "purpose", "attempts", "created_at", "expires_at", "consumed_at"]
    search_fields = ["phone"]
    readonly_fields = [f.name for f in OTPCode._meta.fields]
