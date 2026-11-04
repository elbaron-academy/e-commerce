from django.contrib import admin
from django.core.exceptions import PermissionDenied
from django.middleware.csrf import get_token
from django.template.response import TemplateResponse
from django.urls import path, reverse
from django.utils import translation

from .models import Conversation, Message

LABELS = {
    "en": {
        "title": "Support inbox",
        "needs_reply": "Needs reply",
        "open": "Open",
        "mine": "Mine",
        "closed": "Closed",
        "all": "All",
        "search": "Search by name or phone",
        "empty_list": "No conversations here.",
        "pick": "Pick a conversation to start replying.",
        "assign_me": "Assign to me",
        "unassign": "Unassign",
        "assigned_to": "Assigned to",
        "nobody": "Nobody",
        "close": "Close conversation",
        "reopen": "Reopen",
        "close_confirm": "Close this conversation? The customer's next message starts a new one.",
        "placeholder": "Write a reply… (Enter to send, Shift+Enter for a new line)",
        "send": "Send",
        "photo": "Photo",
        "remove_photo": "Remove photo",
        "older": "Load older messages",
        "closed_event": "Conversation closed",
        "closed_note": "This conversation is closed. Reopen it to reply.",
        "seen": "Seen",
        "orders": "Recent orders",
        "no_orders": "No orders yet",
        "order": "Order",
        "photo_msg": "📷 Photo",
        "customer": "Customer",
        "you": "You",
        "staff": "Staff",
        "error": "Something went wrong. Try again.",
        "no_reply_perm": "You can read conversations but not reply.",
        "admin_list": "Conversation list",
    },
    "ar": {
        "title": "صندوق الدعم",
        "needs_reply": "مستني رد",
        "open": "مفتوحة",
        "mine": "بتاعتي",
        "closed": "مقفولة",
        "all": "الكل",
        "search": "دوّر بالاسم أو الرقم",
        "empty_list": "مفيش محادثات هنا.",
        "pick": "اختار محادثة عشان ترد.",
        "assign_me": "خليها عليّا",
        "unassign": "شيل التعيين",
        "assigned_to": "مع",
        "nobody": "محدش",
        "close": "اقفل المحادثة",
        "reopen": "افتحها تاني",
        "close_confirm": "تقفل المحادثة؟ رسالة العميل الجاية هتفتح محادثة جديدة.",
        "placeholder": "اكتب ردك… (Enter للإرسال، Shift+Enter لسطر جديد)",
        "send": "ابعت",
        "photo": "صورة",
        "remove_photo": "شيل الصورة",
        "older": "رسائل أقدم",
        "closed_event": "المحادثة اتقفلت",
        "closed_note": "المحادثة دي مقفولة. افتحها تاني عشان ترد.",
        "seen": "اتشافت",
        "orders": "آخر الطلبات",
        "no_orders": "مفيش طلبات لسه",
        "order": "طلب",
        "photo_msg": "📷 صورة",
        "customer": "العميل",
        "you": "إنت",
        "staff": "الدعم",
        "error": "حصلت مشكلة. جرّب تاني.",
        "no_reply_perm": "تقدر تقرا المحادثات بس مش ترد.",
        "admin_list": "قائمة المحادثات",
    },
}


class MessageInline(admin.TabularInline):
    model = Message
    extra = 0
    can_delete = False
    fields = ["created_at", "from_staff", "sender", "kind", "event", "body", "image", "order"]
    readonly_fields = fields

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ["id", "customer", "status", "assigned_to", "last_message_at", "created_at"]
    list_filter = ["status", "assigned_to"]
    search_fields = ["customer__phone", "customer__name"]
    raw_id_fields = ["customer", "assigned_to"]
    readonly_fields = [
        "customer",
        "last_message",
        "last_message_at",
        "customer_last_read",
        "staff_last_read",
        "customer_reminded_upto",
        "closed_at",
    ]
    fields = ["customer", "status", "assigned_to", *readonly_fields[1:]]
    inlines = [MessageInline]
    change_list_template = "admin/support/conversation/change_list.html"

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def get_urls(self):
        inbox = path("inbox/", self.admin_site.admin_view(self.inbox_view), name="support_conversation_inbox")
        return [inbox, *super().get_urls()]

    def inbox_view(self, request):
        if not self.has_view_permission(request):
            raise PermissionDenied
        lang = "en" if (translation.get_language() or "ar").startswith("en") else "ar"
        context = {
            **self.admin_site.each_context(request),
            "title": LABELS[lang]["title"],
            "opts": self.model._meta,
            "inbox_config": {
                "api": reverse("admin-support-conversation-list"),
                "csrf": get_token(request),
                "lang": lang,
                "labels": LABELS[lang],
                "me": request.user.pk,
                "can_reply": request.user.has_perm("support.add_message"),
                "can_change": request.user.has_perm("support.change_conversation"),
                "order_url": reverse("admin:orders_order_change", args=[0]).replace("/0/", "/{id}/"),
                "list_url": reverse("admin:support_conversation_changelist"),
            },
        }
        return TemplateResponse(request, "support/admin/inbox.html", context)
