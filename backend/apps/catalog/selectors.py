"""Querysets for the storefront: active products with their variants, plus sorting."""

from django.db.models import (
    Case,
    Exists,
    F,
    FloatField,
    IntegerField,
    OuterRef,
    Prefetch,
    Q,
    QuerySet,
    Subquery,
    Value,
    When,
)
from django.db.models.functions import Cast
from django.utils import timezone

from .models import Category, Product, ProductImage, Variant, sale_active_q

SORTS = ("recommended", "best", "price_asc", "price_desc", "discount", "newest")


def storefront_products() -> QuerySet[Product]:
    active_variants = Variant.objects.filter(is_active=True).order_by("sort_order", "id")
    return (
        Product.objects.filter(is_active=True, category__is_active=True)
        .filter(Exists(Variant.objects.filter(product=OuterRef("pk"), is_active=True)))
        .select_related("brand", "category__parent__parent")
        .prefetch_related(
            Prefetch("variants", queryset=active_variants, to_attr="active_variants"),
            Prefetch("images", queryset=ProductImage.objects.order_by("sort_order", "id"), to_attr="ordered_images"),
        )
    )


def in_category(qs: QuerySet[Product], category: Category) -> QuerySet[Product]:
    return qs.filter(category_id__in=category.descendant_ids())


def with_tag(qs: QuerySet[Product], tag: str) -> QuerySet[Product]:
    if tag == "offer":
        return qs.filter(Exists(Variant.objects.filter(sale_active_q(), product=OuterRef("pk"), is_active=True)))
    if tag == "best":
        return qs.filter(is_bestseller=True)
    if tag == "new":
        return qs.filter(is_new=True)
    return qs.none()


def sort_products(qs: QuerySet[Product], sort: str) -> QuerySet[Product]:
    now = timezone.now()
    variants = Variant.objects.filter(product=OuterRef("pk"), is_active=True)
    in_stock = Exists(variants.filter(stock__gt=0))
    if sort in ("price_asc", "price_desc"):
        default_price = (
            variants.annotate(
                eff=Case(When(sale_active_q(now), then=F("sale_price")), default=F("price")),
                has=Case(When(stock__gt=0, then=Value(1)), default=Value(0), output_field=IntegerField()),
            )
            .order_by("-has", "sort_order", "id")
            .values("eff")[:1]
        )
        qs = qs.annotate(sort_price=Subquery(default_price))
        return qs.order_by("sort_price" if sort == "price_asc" else "-sort_price", "id")
    if sort == "discount":
        best_discount = (
            variants.filter(sale_active_q(now))
            .annotate(ratio=1 - Cast("sale_price", FloatField()) / Cast("price", FloatField()))
            .order_by("-ratio")
            .values("ratio")[:1]
        )
        return qs.annotate(sort_discount=Subquery(best_discount)).order_by(
            F("sort_discount").desc(nulls_last=True), "id"
        )
    if sort == "newest":
        return qs.order_by("-created_at", "-id")
    if sort == "best":
        return qs.order_by("-is_bestseller", "-sold_count", "id")
    # recommended: available first, then popular
    return qs.annotate(sort_stock=in_stock).order_by("-sort_stock", "-is_bestseller", "-sold_count", "id")


def on_sale_q() -> Q:
    return Q(Exists(Variant.objects.filter(sale_active_q(), product=OuterRef("pk"), is_active=True)))
