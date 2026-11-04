from django.contrib import admin

from .models import NotificationLog


@admin.register(NotificationLog)
class NotificationLogAdmin(admin.ModelAdmin):
    list_display = ["created_at", "channel", "event", "recipient", "status"]
    list_filter = ["channel", "status", "event"]
    search_fields = ["recipient", "body"]
    readonly_fields = [f.name for f in NotificationLog._meta.fields]
