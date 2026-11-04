"""Staff API for the catalog (AD-201/202/203)."""

from django.db import transaction
from django.db.models import F, Q
from django_filters import rest_framework as df
from rest_framework import filters, mixins, serializers, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

from apps.core.pagination import AdminPagination
from apps.core.permissions import StaffModelPermissions, require_perms

from .models import Banner, Brand, Category, HomeSection, Product, ProductImage, Variant, Vendor


class CategoryAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = [
            "id",
            "parent",
            "name_ar",
            "name_en",
            "slug",
            "emoji",
            "color",
            "image",
            "sort_order",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]

    def validate(self, attrs):
        parent = attrs.get("parent", getattr(self.instance, "parent", None))
        depth, node = 1, parent
        while node:
            if self.instance and node.pk == self.instance.pk:
                raise serializers.ValidationError({"parent": "A category can't be inside itself."})
            depth, node = depth + 1, node.parent
        if depth > Category.MAX_DEPTH:
            raise serializers.ValidationError(
                {"parent": f"Categories can be at most {Category.MAX_DEPTH} levels deep."}
            )
        return attrs


class BrandAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = Brand
        fields = ["id", "name_ar", "name_en", "slug"]


class VendorAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vendor
        fields = ["id", "name_ar", "name_en", "slug", "is_active"]


class VariantAdminSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)
    is_low_stock = serializers.SerializerMethodField()

    class Meta:
        model = Variant
        fields = [
            "id",
            "sku",
            "label_ar",
            "label_en",
            "price",
            "sale_price",
            "sale_starts_at",
            "sale_ends_at",
            "stock",
            "low_stock_threshold",
            "is_active",
            "sort_order",
            "is_low_stock",
        ]
        extra_kwargs = {"sku": {"validators": []}}

    def get_is_low_stock(self, obj) -> bool:
        return obj.stock <= obj.low_stock_threshold

    def validate(self, attrs):
        price = attrs.get("price", getattr(self.instance, "price", None))
        sale = attrs.get("sale_price", getattr(self.instance, "sale_price", None))
        if sale is not None and price is not None and sale >= price:
            raise serializers.ValidationError({"sale_price": "Sale price must be lower than the price."})
        starts = attrs.get("sale_starts_at", getattr(self.instance, "sale_starts_at", None))
        ends = attrs.get("sale_ends_at", getattr(self.instance, "sale_ends_at", None))
        if starts and ends and ends <= starts:
            raise serializers.ValidationError({"sale_ends_at": "The sale must end after it starts."})
        if attrs.get("stock") is not None and attrs["stock"] < 0:
            raise serializers.ValidationError({"stock": "Stock can't be negative."})
        return attrs


class ProductImageAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ["id", "image", "alt", "sort_order"]


class ProductAdminSerializer(serializers.ModelSerializer):
    variants = VariantAdminSerializer(many=True)
    images = ProductImageAdminSerializer(many=True, read_only=True)

    class Meta:
        model = Product
        exclude = ["search_text", "search_name"]
        read_only_fields = ["sold_count", "created_at", "updated_at"]

    def validate_variants(self, variants):
        if not variants:
            raise serializers.ValidationError("Add at least one variant.")
        skus = [v["sku"] for v in variants]
        if len(skus) != len(set(skus)):
            raise serializers.ValidationError("SKUs must be unique.")
        taken = Variant.objects.filter(sku__in=skus)
        if self.instance:
            taken = taken.exclude(product=self.instance)
        if taken.exists():
            raise serializers.ValidationError(f"SKU already used: {', '.join(taken.values_list('sku', flat=True))}")
        return variants

    def validate(self, attrs):
        step = attrs.get("qty_step", getattr(self.instance, "qty_step", None))
        min_qty = attrs.get("min_qty", getattr(self.instance, "min_qty", None))
        if step and min_qty and min_qty < step:
            raise serializers.ValidationError({"min_qty": "Minimum quantity can't be lower than the step."})
        return attrs

    @transaction.atomic
    def create(self, validated):
        variants = validated.pop("variants")
        product = Product.objects.create(**validated)
        for i, data in enumerate(variants):
            data.pop("id", None)
            data.setdefault("sort_order", i)
            Variant.objects.create(product=product, **data)
        return product

    @transaction.atomic
    def update(self, instance, validated):
        variants = validated.pop("variants", None)
        for key, value in validated.items():
            setattr(instance, key, value)
        instance.save()
        if variants is not None:
            existing = {v.sku: v for v in instance.variants.all()}
            seen = set()
            for i, data in enumerate(variants):
                data.pop("id", None)
                data.setdefault("sort_order", i)
                variant = existing.get(data["sku"])
                if variant:
                    for key, value in data.items():
                        setattr(variant, key, value)
                    variant.save()
                else:
                    Variant.objects.create(product=instance, **data)
                seen.add(data["sku"])
            # Variants referenced by old orders are never deleted, only hidden.
            instance.variants.exclude(sku__in=seen).update(is_active=False)
        return instance


class ProductFilter(df.FilterSet):
    category = df.NumberFilter(method="filter_category")
    low_stock = df.BooleanFilter(method="filter_low_stock")

    class Meta:
        model = Product
        fields = ["is_active", "brand", "vendor", "sold_by_weight", "is_bestseller", "is_new"]

    def filter_category(self, qs, name, value):
        category = Category.objects.filter(pk=value).first()
        return qs.filter(category_id__in=category.descendant_ids()) if category else qs.none()

    def filter_low_stock(self, qs, name, value):
        low = Q(variants__is_active=True, variants__stock__lte=F("variants__low_stock_threshold"))
        return qs.filter(low).distinct() if value else qs.exclude(low)


class CategoryAdminViewSet(viewsets.ModelViewSet):
    serializer_class = CategoryAdminSerializer
    permission_classes = [StaffModelPermissions]
    pagination_class = None
    queryset = Category.objects.all()
    filterset_fields = ["parent", "is_active"]

    def perform_destroy(self, instance):
        # Categories with products are hidden instead of deleted.
        if instance.products.exists() or instance.children.exists():
            instance.is_active = False
            instance.save(update_fields=["is_active"])
        else:
            instance.delete()


class BrandAdminViewSet(viewsets.ModelViewSet):
    serializer_class = BrandAdminSerializer
    permission_classes = [StaffModelPermissions]
    queryset = Brand.objects.order_by("name_en")
    pagination_class = AdminPagination
    filter_backends = [filters.SearchFilter]
    search_fields = ["name_ar", "name_en"]


class VendorAdminViewSet(viewsets.ModelViewSet):
    serializer_class = VendorAdminSerializer
    permission_classes = [StaffModelPermissions]
    queryset = Vendor.objects.order_by("name_en")
    pagination_class = None


class ProductAdminViewSet(viewsets.ModelViewSet):
    serializer_class = ProductAdminSerializer
    permission_classes = [StaffModelPermissions]
    pagination_class = AdminPagination
    filterset_class = ProductFilter
    filter_backends = [df.DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["name_ar", "name_en", "slug", "variants__sku"]
    ordering_fields = ["created_at", "sold_count", "name_en"]

    def get_queryset(self):
        return Product.objects.select_related("category", "brand").prefetch_related("variants", "images").distinct()

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save(update_fields=["is_active"])

    @action(
        detail=True,
        methods=["post"],
        parser_classes=[MultiPartParser, FormParser],
        serializer_class=ProductImageAdminSerializer,
    )
    def images(self, request, pk=None):
        """Upload a product photo (multipart: image, alt, sort_order)."""
        product = self.get_object()
        serializer = ProductImageAdminSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        serializer.save(product=product)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class ProductImageAdminViewSet(mixins.UpdateModelMixin, mixins.DestroyModelMixin, viewsets.GenericViewSet):
    serializer_class = ProductImageAdminSerializer
    permission_classes = [require_perms("catalog.change_product")]
    queryset = ProductImage.objects.all()
    http_method_names = ["patch", "delete"]


class VariantAdminViewSet(
    mixins.ListModelMixin, mixins.RetrieveModelMixin, mixins.UpdateModelMixin, viewsets.GenericViewSet
):
    """Inventory screen: list variants (filter low_stock=true) and edit stock (AD-203)."""

    serializer_class = VariantAdminSerializer
    permission_classes = [StaffModelPermissions]
    pagination_class = AdminPagination
    filter_backends = [df.DjangoFilterBackend, filters.SearchFilter]
    search_fields = ["sku", "product__name_ar", "product__name_en"]
    filterset_fields = ["product", "is_active"]
    http_method_names = ["get", "patch"]

    def get_queryset(self):
        qs = Variant.objects.select_related("product").order_by("product_id", "sort_order")
        if self.request.query_params.get("low_stock") in ("1", "true"):
            qs = qs.filter(is_active=True, stock__lte=F("low_stock_threshold"))
        return qs


class BannerAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = Banner
        fields = "__all__"


class HomeSectionAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = HomeSection
        fields = "__all__"

    def validate(self, attrs):
        kind = attrs.get("kind", getattr(self.instance, "kind", None))
        category = attrs.get("category", getattr(self.instance, "category", None))
        if kind == HomeSection.Kind.CATEGORY and not category:
            raise serializers.ValidationError({"category": "Pick a category for this section."})
        return attrs


class BannerAdminViewSet(viewsets.ModelViewSet):
    serializer_class = BannerAdminSerializer
    permission_classes = [StaffModelPermissions]
    queryset = Banner.objects.all()
    pagination_class = None


class HomeSectionAdminViewSet(viewsets.ModelViewSet):
    serializer_class = HomeSectionAdminSerializer
    permission_classes = [StaffModelPermissions]
    queryset = HomeSection.objects.all()
    pagination_class = None
