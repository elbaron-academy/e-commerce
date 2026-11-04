from django.contrib.auth.models import Group, Permission
from rest_framework import serializers

from apps.core.i18n import tr
from apps.core.text import normalize_phone, to_latin_digits
from apps.shipping.models import Zone

from .models import Address, User, phone_validator


class PhoneField(serializers.CharField):
    """Accepts '+20…', spaces and Arabic-Indic digits; stores 01xxxxxxxxx."""

    def __init__(self, **kwargs):
        kwargs.setdefault("max_length", 20)
        super().__init__(**kwargs)
        self.validators.append(phone_validator)

    def to_internal_value(self, data):
        return normalize_phone(super().to_internal_value(data))

    def run_validators(self, value):
        super().run_validators(value)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "phone", "name", "email", "language"]
        read_only_fields = ["id", "phone"]


class OTPSendSerializer(serializers.Serializer):
    phone = PhoneField()


class OTPVerifySerializer(serializers.Serializer):
    phone = PhoneField()
    code = serializers.CharField(max_length=6)

    def validate_code(self, value):
        return to_latin_digits(value).strip()


class AuthTokensSerializer(serializers.Serializer):
    access = serializers.CharField()
    refresh = serializers.CharField()
    user = UserSerializer()
    is_new = serializers.BooleanField()


class ChangePhoneSerializer(serializers.Serializer):
    phone = PhoneField()
    code = serializers.CharField(max_length=6)


class AddressSerializer(serializers.ModelSerializer):
    zone = serializers.SlugRelatedField(slug_field="code", queryset=Zone.objects.filter(is_active=True))
    zone_name = serializers.SerializerMethodField()

    class Meta:
        model = Address
        fields = [
            "id",
            "label",
            "zone",
            "zone_name",
            "area",
            "street",
            "building",
            "floor",
            "apartment",
            "notes",
            "lat",
            "lng",
            "is_default",
        ]
        read_only_fields = ["id", "zone_name"]

    def get_zone_name(self, obj) -> str:
        return tr(obj.zone, "name")

    def to_representation(self, instance):
        data = super().to_representation(instance)
        for key in ("lat", "lng"):
            data[key] = float(data[key]) if data[key] is not None else None
        return data


# ---- Staff API ----


class CustomerAdminSerializer(serializers.ModelSerializer):
    orders_count = serializers.IntegerField(read_only=True)
    total_spent = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = User
        fields = [
            "id",
            "phone",
            "name",
            "email",
            "language",
            "is_active",
            "notes",
            "date_joined",
            "last_login",
            "orders_count",
            "total_spent",
        ]
        read_only_fields = ["id", "phone", "date_joined", "last_login", "language"]


class RoleSerializer(serializers.ModelSerializer):
    permissions = serializers.SlugRelatedField(
        many=True, slug_field="codename", queryset=Permission.objects.select_related("content_type")
    )

    class Meta:
        model = Group
        fields = ["id", "name", "permissions"]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["permissions"] = sorted(
            f"{p.content_type.app_label}.{p.codename}" for p in instance.permissions.select_related("content_type")
        )
        return data

    def to_internal_value(self, data):
        # Accept "app_label.codename" strings.
        perms = data.get("permissions")
        if perms is not None:
            resolved = []
            for full in perms:
                app_label, _, codename = str(full).partition(".")
                perm = Permission.objects.filter(content_type__app_label=app_label, codename=codename).first()
                if not perm:
                    raise serializers.ValidationError({"permissions": f"Unknown permission: {full}"})
                resolved.append(perm)
            internal = super().to_internal_value({**data, "permissions": []})
            internal["permissions"] = resolved
            return internal
        return super().to_internal_value(data)


class StaffUserSerializer(serializers.ModelSerializer):
    phone = PhoneField()
    password = serializers.CharField(write_only=True, required=False, min_length=8)
    roles = serializers.PrimaryKeyRelatedField(source="groups", many=True, queryset=Group.objects.all(), required=False)

    class Meta:
        model = User
        fields = ["id", "phone", "name", "email", "is_active", "is_superuser", "roles", "password", "last_login"]
        read_only_fields = ["id", "is_superuser", "last_login"]

    def create(self, validated):
        groups = validated.pop("groups", [])
        password = validated.pop("password", None)
        if not password:
            raise serializers.ValidationError({"password": "A password is required for staff accounts."})
        user = User.objects.create_user(password=password, is_staff=True, **validated)
        user.groups.set(groups)
        return user

    def update(self, instance, validated):
        groups = validated.pop("groups", None)
        password = validated.pop("password", None)
        for key, value in validated.items():
            setattr(instance, key, value)
        if password:
            instance.set_password(password)
        instance.save()
        if groups is not None:
            instance.groups.set(groups)
        return instance
