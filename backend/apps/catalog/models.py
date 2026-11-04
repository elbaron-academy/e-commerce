from decimal import Decimal

from django.core.exceptions import ValidationError
from django.core.validators import MinValueValidator
from django.db import models
from django.db.models import Q
from django.utils import timezone

from apps.core.models import TimeStampedModel
from apps.core.text import search_words


class Vendor(TimeStampedModel):
    """A shop inside Rocket Mall. Unused until the marketplace decision is made,
    but every product can already belong to one (plan risk: "Store/Vendor field")."""

    name_ar = models.CharField(max_length=120)
    name_en = models.CharField(max_length=120)
    slug = models.SlugField(unique=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name_en


class Category(TimeStampedModel):
    MAX_DEPTH = 3

    parent = models.ForeignKey("self", null=True, blank=True, on_delete=models.PROTECT, related_name="children")
    name_ar = models.CharField(max_length=120)
    name_en = models.CharField(max_length=120)
    slug = models.SlugField(unique=True, allow_unicode=False)
    emoji = models.CharField(max_length=8, blank=True, help_text="Shown until an image is uploaded")
    color = models.CharField(max_length=7, default="#EEF2EF", help_text="Tile background, e.g. #E3F3DC")
    image = models.ImageField(upload_to="categories/", blank=True)
    sort_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["sort_order", "id"]
        verbose_name_plural = "categories"

    def __str__(self):
        return self.name_en

    @property
    def depth(self) -> int:
        depth, node = 1, self.parent
        while node:
            depth, node = depth + 1, node.parent
        return depth

    def clean(self):
        if self.parent_id and self.depth > self.MAX_DEPTH:
            raise ValidationError({"parent": f"Categories can be at most {self.MAX_DEPTH} levels deep."})
        node = self.parent
        while node:
            if node.pk == self.pk:
                raise ValidationError({"parent": "A category can't be inside itself."})
            node = node.parent

    @property
    def root(self) -> "Category":
        node = self
        while node.parent_id:
            node = node.parent
        return node

    def descendant_ids(self) -> list[int]:
        ids, frontier = [self.pk], [self.pk]
        while frontier:
            frontier = list(Category.objects.filter(parent_id__in=frontier).values_list("id", flat=True))
            ids += frontier
        return ids


class Brand(TimeStampedModel):
    name_ar = models.CharField(max_length=120)
    name_en = models.CharField(max_length=120)
    slug = models.SlugField(unique=True)

    def __str__(self):
        return self.name_en


class Product(TimeStampedModel):
    vendor = models.ForeignKey(Vendor, null=True, blank=True, on_delete=models.SET_NULL, related_name="products")
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="products")
    brand = models.ForeignKey(Brand, null=True, blank=True, on_delete=models.SET_NULL, related_name="products")
    name_ar = models.CharField(max_length=200)
    name_en = models.CharField(max_length=200)
    slug = models.SlugField(max_length=200, unique=True)
    description_ar = models.TextField(blank=True)
    description_en = models.TextField(blank=True)
    emoji = models.CharField(max_length=8, blank=True, help_text="Placeholder until photos are uploaded")
    sold_by_weight = models.BooleanField(default=False, help_text="Quantity is in kg (fruit, vegetables, meat…)")
    qty_step = models.DecimalField(
        max_digits=6, decimal_places=3, default=Decimal("1"), validators=[MinValueValidator(Decimal("0.001"))]
    )
    min_qty = models.DecimalField(
        max_digits=6, decimal_places=3, default=Decimal("1"), validators=[MinValueValidator(Decimal("0.001"))]
    )
    max_per_order = models.DecimalField(max_digits=8, decimal_places=3, default=Decimal("20"))
    is_active = models.BooleanField(default=True, db_index=True)
    is_bestseller = models.BooleanField(default=False)
    is_new = models.BooleanField(default=False)
    sold_count = models.PositiveIntegerField(default=0, help_text="Updated when orders are delivered")
    # Normalized words for search (Arabic + English), kept in sync on save.
    search_text = models.TextField(blank=True, editable=False)
    search_name = models.TextField(blank=True, editable=False)

    class Meta:
        ordering = ["id"]

    def __str__(self):
        return self.name_en

    def build_search_fields(self):
        brand = [self.brand.name_ar, self.brand.name_en] if self.brand_id else []
        categories, node = [], self.category if self.category_id else None
        while node:
            categories += [node.name_ar, node.name_en]
            node = node.parent
        name_words = search_words(self.name_ar, self.name_en)
        self.search_name = " ".join(name_words)
        self.search_text = " ".join(
            search_words(self.name_ar, self.name_en, *brand, *categories, self.slug.replace("-", " "))
        )

    def save(self, *args, **kwargs):
        self.build_search_fields()
        if kwargs.get("update_fields") is not None:
            kwargs["update_fields"] = {*kwargs["update_fields"], "search_text", "search_name"}
        super().save(*args, **kwargs)


def sale_active_q(now=None, prefix: str = "") -> Q:
    now = now or timezone.now()
    p = prefix
    return (
        Q(**{f"{p}sale_price__isnull": False})
        & (Q(**{f"{p}sale_starts_at__isnull": True}) | Q(**{f"{p}sale_starts_at__lte": now}))
        & (Q(**{f"{p}sale_ends_at__isnull": True}) | Q(**{f"{p}sale_ends_at__gte": now}))
    )


class Variant(TimeStampedModel):
    """A sellable size of a product with its own SKU, price and stock (BE-203)."""

    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name="variants")
    sku = models.CharField(max_length=40, unique=True)
    label_ar = models.CharField(max_length=60)
    label_en = models.CharField(max_length=60)
    price = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal("0"))])
    sale_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    sale_starts_at = models.DateTimeField(null=True, blank=True)
    sale_ends_at = models.DateTimeField(null=True, blank=True)
    stock = models.DecimalField(
        max_digits=10, decimal_places=3, default=Decimal("0"), help_text="Units, or kg for weight items"
    )
    low_stock_threshold = models.DecimalField(max_digits=10, decimal_places=3, default=Decimal("5"))
    is_active = models.BooleanField(default=True)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["sort_order", "id"]
        constraints = [
            models.CheckConstraint(condition=Q(stock__gte=0), name="variant_stock_not_negative"),
            models.CheckConstraint(
                condition=Q(sale_price__isnull=True) | Q(sale_price__lt=models.F("price")),
                name="variant_sale_below_price",
            ),
        ]

    def __str__(self):
        return f"{self.sku} · {self.label_en}"

    def active_sale_price(self, at=None) -> Decimal | None:
        """Sale price if the sale is running now (BE-206: evaluated at order time)."""
        if self.sale_price is None:
            return None
        now = at or timezone.now()
        if self.sale_starts_at and self.sale_starts_at > now:
            return None
        if self.sale_ends_at and self.sale_ends_at < now:
            return None
        return self.sale_price

    def unit_price(self, at=None) -> Decimal:
        sale = self.active_sale_price(at)
        return sale if sale is not None else self.price

    @property
    def in_stock(self) -> bool:
        return self.stock > 0

    def max_qty(self, product: Product | None = None) -> Decimal:
        product = product or self.product
        return max(Decimal("0"), min(self.stock, product.max_per_order))


class ProductImage(TimeStampedModel):
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name="images")
    image = models.ImageField(upload_to="products/%Y/%m/")
    alt = models.CharField(max_length=200, blank=True)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["sort_order", "id"]


class Banner(TimeStampedModel):
    class Tone(models.TextChoices):
        GREEN = "green"
        ORANGE = "orange"
        BLUE = "blue"

    title_ar = models.CharField(max_length=120)
    title_en = models.CharField(max_length=120)
    subtitle_ar = models.CharField(max_length=200, blank=True)
    subtitle_en = models.CharField(max_length=200, blank=True)
    cta_ar = models.CharField(max_length=40, blank=True)
    cta_en = models.CharField(max_length=40, blank=True)
    link = models.CharField(max_length=200, help_text="Storefront path, e.g. /category/bakery")
    emoji = models.CharField(max_length=16, blank=True)
    image = models.ImageField(upload_to="banners/", blank=True)
    tone = models.CharField(max_length=10, choices=Tone.choices, default=Tone.GREEN)
    starts_at = models.DateTimeField(null=True, blank=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    sort_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["sort_order", "id"]

    def __str__(self):
        return self.title_en


class HomeSection(TimeStampedModel):
    """A product row on the home page."""

    class Kind(models.TextChoices):
        OFFERS = "offers", "Products on sale"
        BEST = "best", "Best sellers"
        NEW = "new", "New arrivals"
        CATEGORY = "category", "From a category"

    key = models.SlugField(unique=True)
    kind = models.CharField(max_length=10, choices=Kind.choices)
    title_ar = models.CharField(max_length=120)
    title_en = models.CharField(max_length=120)
    category = models.ForeignKey(Category, null=True, blank=True, on_delete=models.CASCADE)
    limit = models.PositiveSmallIntegerField(default=12)
    sort_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["sort_order", "id"]

    def __str__(self):
        return self.title_en

    def clean(self):
        if self.kind == self.Kind.CATEGORY and not self.category_id:
            raise ValidationError({"category": "Pick a category for this section."})
