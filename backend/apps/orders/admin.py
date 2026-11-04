from django.contrib import admin

from .models import Order, OrderItem, OrderStatusHistory


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    can_delete = False
    readonly_fields = ["sku", "name_en", "variant_label_en", "qty", "unit_price", "line_total"]
    fields = readonly_fields


class OrderStatusHistoryInline(admin.TabularInline):
    model = OrderStatusHistory
    extra = 0
    can_delete = False
    readonly_fields = ["status", "note", "actor", "created_at"]


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = [
        "number",
        "user",
        "status",
        "method",
        "payment_method",
        "payment_status",
        "total",
        "slot_date",
        "created_at",
    ]
    list_filter = ["status", "method", "payment_method", "payment_status", "slot_date"]
    search_fields = ["number", "user__phone", "user__name"]
    raw_id_fields = ["user", "coupon"]
    inlines = [OrderItemInline, OrderStatusHistoryInline]
    readonly_fields = [
        "number",
        "subtotal",
        "coupon_discount",
        "delivery_fee",
        "total",
        "address",
        "placed_at",
        "reserved_until",
        "cancelled_at",
        "delivered_at",
    ]
    date_hierarchy = "created_at"

    def has_delete_permission(self, request, obj=None):
        return False
