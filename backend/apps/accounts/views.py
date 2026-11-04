from django.contrib.auth import authenticate
from django.db import transaction
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import mixins, serializers, status, viewsets
from rest_framework.generics import RetrieveUpdateAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from apps.core.exceptions import ApiError
from apps.core.i18n import t

from . import otp
from .models import Address, User
from .serializers import (
    AddressSerializer,
    AuthTokensSerializer,
    ChangePhoneSerializer,
    OTPSendSerializer,
    OTPVerifySerializer,
    UserSerializer,
)


def issue_tokens(user: User) -> dict:
    refresh = RefreshToken.for_user(user)
    return {"access": str(refresh.access_token), "refresh": str(refresh)}


class OTPSendView(APIView):
    """Sends a login code by SMS. 5 codes per phone per hour, 60 s between codes."""

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "otp"

    @extend_schema(
        request=OTPSendSerializer,
        responses=inline_serializer(
            "OTPSent",
            {
                "sent": serializers.BooleanField(),
                "expires_in": serializers.IntegerField(),
                "resend_in": serializers.IntegerField(),
            },
        ),
    )
    def post(self, request):
        data = OTPSendSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        otp.send_otp(data.validated_data["phone"], ip=request.META.get("REMOTE_ADDR"))
        from django.conf import settings

        return Response(
            {"sent": True, "expires_in": settings.OTP_TTL_SECONDS, "resend_in": settings.OTP_RESEND_SECONDS}
        )


class OTPVerifyView(APIView):
    """Checks the code and returns JWT tokens. Creates the customer on first login."""

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "otp"

    @extend_schema(request=OTPVerifySerializer, responses=AuthTokensSerializer)
    def post(self, request):
        data = OTPVerifySerializer(data=request.data)
        data.is_valid(raise_exception=True)
        phone = data.validated_data["phone"]
        otp.verify_otp(phone, data.validated_data["code"])
        user, _ = User.objects.get_or_create(phone=phone)
        if user.is_staff:
            # Staff sign in with a password; a phone code must never open a staff account.
            raise ApiError(
                t("حسابات الموظفين بتدخل بكلمة السر.", "Staff accounts sign in with a password."),
                status_code=403,
                code="staff_account",
            )
        if not user.is_active:
            raise ApiError(t("الحساب ده موقوف.", "This account is disabled."), status_code=403, code="account_disabled")
        return Response({**issue_tokens(user), "user": UserSerializer(user).data, "is_new": not user.name})


class StaffLoginView(APIView):
    """Staff sign-in for the admin dashboard: phone or email + password."""

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "login"

    @extend_schema(
        request=inline_serializer(
            "StaffLogin",
            {"login": serializers.CharField(help_text="Phone or email"), "password": serializers.CharField()},
        ),
        responses=AuthTokensSerializer,
    )
    def post(self, request):
        login = request.data.get("login") or request.data.get("email") or request.data.get("phone") or ""
        user = authenticate(request, username=str(login), password=str(request.data.get("password", "")))
        if not user or not user.is_staff:
            raise ApiError(
                t("بيانات الدخول غلط.", "Invalid login or password."), status_code=401, code="invalid_credentials"
            )
        return Response({**issue_tokens(user), "user": UserSerializer(user).data, "is_new": False})


class MeView(RetrieveUpdateAPIView):
    """The signed-in customer's profile (BE-104)."""

    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ["get", "patch"]

    def get_object(self):
        return self.request.user


class ChangePhoneView(APIView):
    """Changes the phone number after verifying an OTP sent to the new number."""

    permission_classes = [IsAuthenticated]

    @extend_schema(request=ChangePhoneSerializer, responses=UserSerializer)
    def post(self, request):
        data = ChangePhoneSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        phone = data.validated_data["phone"]
        if User.objects.filter(phone=phone).exclude(pk=request.user.pk).exists():
            raise ApiError(t("الرقم ده مستخدم في حساب تاني.", "This number belongs to another account."), field="phone")
        otp.verify_otp(phone, data.validated_data["code"])
        request.user.phone = phone
        request.user.save(update_fields=["phone"])
        return Response(UserSerializer(request.user).data)


class AddressViewSet(
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.UpdateModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet,
):
    serializer_class = AddressSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None
    http_method_names = ["get", "post", "patch", "delete"]

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Address.objects.none()
        return Address.objects.filter(user=self.request.user).select_related("zone")

    @transaction.atomic
    def perform_create(self, serializer):
        has_addresses = self.get_queryset().exists()
        make_default = serializer.validated_data.get("is_default") or not has_addresses
        if make_default:
            self.get_queryset().update(is_default=False)
        serializer.save(user=self.request.user, is_default=make_default)

    @transaction.atomic
    def perform_update(self, serializer):
        if serializer.validated_data.get("is_default"):
            self.get_queryset().exclude(pk=serializer.instance.pk).update(is_default=False)
        serializer.save()

    @transaction.atomic
    def perform_destroy(self, instance):
        was_default = instance.is_default
        instance.delete()
        if was_default:
            first = self.get_queryset().first()
            if first:
                first.is_default = True
                first.save(update_fields=["is_default"])

    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        response.status_code = status.HTTP_201_CREATED
        return response
