from django.contrib import admin

from .models import Payment, WebhookEvent


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ["reference", "order", "provider", "method", "amount", "status", "needs_refund", "created_at"]
    list_filter = ["provider", "status", "needs_refund"]
    search_fields = ["reference", "provider_transaction_id", "order__number"]
    raw_id_fields = ["order"]


@admin.register(WebhookEvent)
class WebhookEventAdmin(admin.ModelAdmin):
    list_display = ["provider", "event_id", "processed_at", "created_at"]
    readonly_fields = ["provider", "event_id", "payload", "processed_at"]
