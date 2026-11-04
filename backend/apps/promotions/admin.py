from django.contrib import admin

from .models import Coupon, CouponRedemption


@admin.register(Coupon)
class CouponAdmin(admin.ModelAdmin):
    list_display = ["code", "type", "value", "min_subtotal", "usage_limit", "starts_at", "ends_at", "is_active"]
    list_filter = ["type", "is_active"]
    search_fields = ["code"]


@admin.register(CouponRedemption)
class CouponRedemptionAdmin(admin.ModelAdmin):
    list_display = ["coupon", "user", "order", "discount", "created_at"]
    raw_id_fields = ["user", "order"]
