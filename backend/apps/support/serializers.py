"""Chat payloads. Shapes match storefront/shared/types/api.ts (ChatMessage, ChatState)."""

from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from .models import Conversation, Message


def absolute(request, url: str) -> str:
    return request.build_absolute_uri(url) if request and url.startswith("/") else url


class ChatImageSerializer(serializers.Serializer):
    url = serializers.CharField()
    width = serializers.IntegerField(allow_null=True)
    height = serializers.IntegerField(allow_null=True)


class OrderRefSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    number = serializers.CharField()


class MessageSerializer(serializers.ModelSerializer):
    sender = serializers.SerializerMethodField(help_text="customer or staff")
    sender_name = serializers.SerializerMethodField()
    image = serializers.SerializerMethodField()
    order = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = [
            "id",
            "conversation",
            "kind",
            "event",
            "sender",
            "sender_name",
            "body",
            "image",
            "order",
            "created_at",
        ]

    def get_sender(self, message) -> str:
        return "staff" if message.from_staff else "customer"

    def get_sender_name(self, message) -> str:
        return (message.sender.name if message.sender else "") or ""

    @extend_schema_field(ChatImageSerializer(allow_null=True))
    def get_image(self, message) -> dict | None:
        if not message.image:
            return None
        return {
            "url": absolute(self.context.get("request"), message.image.url),
            "width": message.image_width,
            "height": message.image_height,
        }

    @extend_schema_field(OrderRefSerializer(allow_null=True))
    def get_order(self, message) -> dict | None:
        if not message.order_id or not message.order:
            return None
        return {"id": message.order_id, "number": message.order.number or ""}


class ConversationRefSerializer(serializers.ModelSerializer):
    class Meta:
        model = Conversation
        fields = ["id", "status", "staff_last_read", "customer_last_read"]


class SendMessageSerializer(serializers.Serializer):
    body = serializers.CharField(max_length=2000, required=False, allow_blank=True, default="", trim_whitespace=True)
    image = serializers.FileField(required=False, allow_null=True)
    order = serializers.IntegerField(required=False, allow_null=True)


class ReadSerializer(serializers.Serializer):
    message_id = serializers.IntegerField(required=False, allow_null=True, min_value=1)
