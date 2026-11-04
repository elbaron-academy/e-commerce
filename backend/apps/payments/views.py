from django.conf import settings
from django.db import IntegrityError, transaction
from django.http import Http404
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import serializers
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.exceptions import ApiError
from apps.orders.models import Order
from apps.orders.serializers import OrderSerializer

from .gateways import get_gateway
from .gateways.base import InvalidSignature
from .models import Payment, WebhookEvent
from .services import apply_payment_result


class PaymentWebhookView(APIView):
    """Gateway callback. Signature checked; each event handled once (BE-504)."""

    permission_classes = [AllowAny]
    authentication_classes = []

    @extend_schema(request=None, responses={200: {"type": "object"}})
    def post(self, request, provider: str):
        try:
            gateway = get_gateway(provider)
        except RuntimeError as exc:
            raise Http404 from exc
        try:
            result = gateway.parse_webhook(request)
        except InvalidSignature as exc:
            raise ApiError("Invalid signature", status_code=400, code="invalid_signature") from exc
        if not result.event_id or not result.reference:
            raise ApiError("Missing event_id or reference", code="invalid_payload")

        try:
            with transaction.atomic():
                event = WebhookEvent.objects.create(
                    provider=provider, event_id=result.event_id, payload=result.payload or {}
                )
        except IntegrityError:
            event = WebhookEvent.objects.get(provider=provider, event_id=result.event_id)
            if event.processed_at:
                return Response({"received": True, "duplicate": True})

        payment = Payment.objects.filter(provider=provider, reference=result.reference).first()
        if not payment:
            raise ApiError("Unknown payment reference", status_code=404, code="unknown_reference")
        apply_payment_result(
            payment, success=result.success, transaction_id=result.transaction_id, payload=result.payload
        )
        event.processed_at = timezone.now()
        event.save(update_fields=["processed_at"])
        return Response({"received": True})


class MockPaymentConfirmView(APIView):
    """Test gateway only: the storefront's /payment/mock page reports the result here."""

    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=inline_serializer(
            "MockPaymentConfirm",
            {"order_id": serializers.IntegerField(), "result": serializers.ChoiceField(choices=["success", "failed"])},
        ),
        responses=OrderSerializer,
    )
    def post(self, request):
        if settings.PAYMENT_PROVIDER != "dummy":
            raise Http404
        order = get_object_or_404(Order, pk=request.data.get("order_id"), user=request.user)
        payment = order.payments.filter(provider="dummy").first()
        if not payment:
            raise ApiError("This order has no pending payment.", code="no_payment")
        apply_payment_result(
            payment, success=request.data.get("result") == "success", transaction_id=f"MOCK-{payment.pk}"
        )
        order = Order.objects.prefetch_related("items", "history").get(pk=order.pk)
        return Response(OrderSerializer(order).data)
