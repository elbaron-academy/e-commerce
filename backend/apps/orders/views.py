from drf_spectacular.utils import extend_schema
from rest_framework import mixins, status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Order
from .pricing import build_quote
from .serializers import OrderCreateResponseSerializer, OrderCreateSerializer, OrderSerializer, QuoteRequestSerializer
from .services import place_order


class QuoteView(APIView):
    """Prices a cart: stock, sale prices, coupon, delivery fee and order rules."""

    @extend_schema(request=QuoteRequestSerializer, responses={200: {"type": "object"}})
    def post(self, request):
        data = QuoteRequestSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        body = data.validated_data
        quote = build_quote(
            [dict(item) for item in body["items"]],
            coupon_code=body.get("coupon") or None,
            zone_code=body.get("zone") or None,
            method=body["method"],
            user=request.user,
        )
        return Response(quote.to_dict({"request": request}))


class OrderViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, mixins.CreateModelMixin, viewsets.GenericViewSet):
    """The customer's orders. POST places a new order (checkout)."""

    permission_classes = [IsAuthenticated]
    serializer_class = OrderSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Order.objects.none()
        return Order.objects.filter(user=self.request.user).prefetch_related("items", "history")

    @extend_schema(request=OrderCreateSerializer, responses={201: OrderCreateResponseSerializer})
    def create(self, request, *args, **kwargs):
        data = OrderCreateSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        body = data.validated_data
        order, payment_url = place_order(
            user=request.user,
            items=[dict(item) for item in body["items"]],
            method=body["method"],
            payment_method=body["payment_method"],
            address_id=body.get("address_id"),
            slot_id=body["slot_id"],
            coupon_code=body.get("coupon") or None,
            notes=body.get("notes", ""),
            serializer_context={"request": request},
        )
        order = self.get_queryset().get(pk=order.pk)
        return Response(
            {"order": OrderSerializer(order).data, "payment_url": payment_url}, status=status.HTTP_201_CREATED
        )
