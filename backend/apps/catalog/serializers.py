"""Storefront payloads. Shapes match storefront/shared/types/api.ts."""

from django.utils import timezone
from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from apps.core.i18n import tr

from .models import Category, Product, Variant


def _url(request, file) -> str | None:
    if not file:
        return None
    url = file.url
    return request.build_absolute_uri(url) if request and url.startswith("/") else url


def product_variants(product: Product) -> list[Variant]:
    return getattr(product, "active_variants", None) or list(product.variants.filter(is_active=True))


def default_variant(product: Product) -> Variant | None:
    variants = product_variants(product)
    return next((v for v in variants if v.in_stock), variants[0] if variants else None)


class CategoryRefSerializer(serializers.Serializer):
    slug = serializers.CharField()
    name = serializers.CharField()


class VariantSerializer(serializers.Serializer):
    sku = serializers.CharField()
    label = serializers.CharField()
    price = serializers.FloatField()
    sale_price = serializers.FloatField(allow_null=True)
    in_stock = serializers.BooleanField()
    stock = serializers.FloatField()
    max_qty = serializers.FloatField()

    def to_representation(self, variant: Variant):
        product = self.context.get("product") or variant.product
        return {
            "sku": variant.sku,
            "label": tr(variant, "label"),
            "price": variant.price,
            "sale_price": variant.active_sale_price(self.context.get("now")),
            "in_stock": variant.in_stock,
            "stock": variant.stock,
            "max_qty": variant.max_qty(product),
        }


class ProductSummarySerializer(serializers.Serializer):
    """Product card data. Product-level price/label mirror the default variant."""

    id = serializers.IntegerField()
    slug = serializers.CharField()
    name = serializers.CharField()
    brand = serializers.CharField()
    image = serializers.CharField(allow_null=True)
    emoji = serializers.CharField()
    color = serializers.CharField()
    category = CategoryRefSerializer()
    subcategory = CategoryRefSerializer(allow_null=True)
    unit_label = serializers.CharField()
    sold_by_weight = serializers.BooleanField()
    qty_step = serializers.FloatField()
    min_qty = serializers.FloatField()
    max_qty = serializers.FloatField()
    price = serializers.FloatField()
    sale_price = serializers.FloatField(allow_null=True)
    discount_percent = serializers.IntegerField()
    sale_ends_at = serializers.DateField(allow_null=True)
    in_stock = serializers.BooleanField()
    default_sku = serializers.CharField()
    variants = VariantSerializer(many=True)
    rating = serializers.FloatField()
    tags = serializers.ListField(child=serializers.CharField())

    def to_representation(self, product: Product):
        now = self.context.setdefault("now", timezone.now())
        request = self.context.get("request")
        variants = product_variants(product)
        variant = default_variant(product)
        variant_context = {**self.context, "product": product}
        variant_data = [VariantSerializer(v, context=variant_context).data for v in variants]
        sale = variant.active_sale_price(now) if variant else None
        sale_variants = [v for v in variants if v.active_sale_price(now) is not None]
        ends = [v.sale_ends_at for v in sale_variants if v.sale_ends_at]
        root = product.category.root
        sub = product.category if product.category_id != root.pk else None
        images = getattr(product, "ordered_images", None)
        if images is None:
            images = list(product.images.all())
        tags = [
            tag
            for tag, on in (("best", product.is_bestseller), ("new", product.is_new), ("offer", bool(sale_variants)))
            if on
        ]
        return {
            "id": product.pk,
            "slug": product.slug,
            "name": tr(product, "name"),
            "brand": tr(product.brand, "name") if product.brand_id else "",
            "image": _url(request, images[0].image) if images else None,
            "emoji": product.emoji or root.emoji,
            "color": root.color,
            "category": {"slug": root.slug, "name": tr(root, "name")},
            "subcategory": {"slug": sub.slug, "name": tr(sub, "name")} if sub else None,
            "unit_label": tr(variant, "label") if variant else "",
            "sold_by_weight": product.sold_by_weight,
            "qty_step": product.qty_step,
            "min_qty": product.min_qty,
            "max_qty": variant.max_qty(product) if variant else 0,
            "price": variant.price if variant else 0,
            "sale_price": sale,
            "discount_percent": round((1 - sale / variant.price) * 100) if sale is not None and variant.price else 0,
            "sale_ends_at": timezone.localtime(min(ends)).date().isoformat() if ends else None,
            "in_stock": any(v.in_stock for v in variants),
            "default_sku": variant.sku if variant else "",
            "variants": variant_data,
            "rating": 0,
            "tags": tags,
        }


class ProductDetailSerializer(ProductSummarySerializer):
    description = serializers.CharField()
    images = serializers.ListField(child=serializers.CharField())

    def to_representation(self, product: Product):
        data = super().to_representation(product)
        request = self.context.get("request")
        images = getattr(product, "ordered_images", None) or list(product.images.all())
        data["description"] = tr(product, "description")
        data["images"] = [_url(request, img.image) for img in images]
        return data


class CategoryNodeSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    slug = serializers.CharField()
    name = serializers.CharField()
    emoji = serializers.CharField()
    color = serializers.CharField()
    image = serializers.CharField(allow_null=True)
    product_count = serializers.IntegerField()
    children = serializers.ListField(child=serializers.DictField())


class SearchSuggestionSerializer(serializers.Serializer):
    type = serializers.ChoiceField(choices=["product", "category"])
    slug = serializers.CharField()
    name = serializers.CharField()
    emoji = serializers.CharField()
    subtitle = serializers.CharField()


class HomeBannerSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    title = serializers.CharField()
    subtitle = serializers.CharField()
    cta = serializers.CharField()
    link = serializers.CharField()
    emoji = serializers.CharField()
    image = serializers.CharField(allow_null=True)
    tone = serializers.CharField()


class HomeSectionSerializer(serializers.Serializer):
    key = serializers.CharField()
    title = serializers.CharField()
    link = serializers.CharField(allow_null=True)
    products = ProductSummarySerializer(many=True)


class HomeSerializer(serializers.Serializer):
    banners = HomeBannerSerializer(many=True)
    sections = HomeSectionSerializer(many=True)


@extend_schema_field(CategoryNodeSerializer(many=True))
class CategoryTreeField(serializers.Field):
    pass


def category_tree(request) -> list[dict]:
    """Active categories as a tree, with product counts that include subcategories."""
    from django.db.models import Count, Q

    nodes = list(
        Category.objects.filter(is_active=True).annotate(direct=Count("products", filter=Q(products__is_active=True)))
    )
    by_parent: dict[int | None, list[Category]] = {}
    for node in nodes:
        by_parent.setdefault(node.parent_id, []).append(node)

    def build(node: Category) -> dict:
        children = [build(child) for child in by_parent.get(node.pk, [])]
        return {
            "id": node.pk,
            "slug": node.slug,
            "name": tr(node, "name"),
            "emoji": node.emoji,
            "color": node.color,
            "image": _url(request, node.image),
            "product_count": node.direct + sum(c["product_count"] for c in children),
            "children": children,
        }

    return [build(root) for root in by_parent.get(None, [])]
