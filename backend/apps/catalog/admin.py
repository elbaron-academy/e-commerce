from django.contrib import admin

from .models import Banner, Brand, Category, HomeSection, Product, ProductImage, Variant, Vendor


class VariantInline(admin.TabularInline):
    model = Variant
    extra = 0
    fields = [
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
    ]


class ProductImageInline(admin.TabularInline):
    model = ProductImage
    extra = 0


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = [
        "name_en",
        "name_ar",
        "category",
        "brand",
        "sold_by_weight",
        "is_active",
        "is_bestseller",
        "sold_count",
    ]
    list_filter = ["is_active", "category", "brand", "sold_by_weight", "is_bestseller", "is_new"]
    search_fields = ["name_ar", "name_en", "slug", "variants__sku"]
    prepopulated_fields = {"slug": ["name_en"]}
    inlines = [VariantInline, ProductImageInline]
    list_select_related = ["category", "brand"]


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ["name_en", "name_ar", "parent", "sort_order", "is_active"]
    list_filter = ["is_active", "parent"]
    search_fields = ["name_ar", "name_en", "slug"]
    prepopulated_fields = {"slug": ["name_en"]}


@admin.register(Variant)
class VariantAdmin(admin.ModelAdmin):
    list_display = ["sku", "product", "label_en", "price", "sale_price", "stock", "is_active"]
    list_filter = ["is_active"]
    search_fields = ["sku", "product__name_en", "product__name_ar"]
    raw_id_fields = ["product"]


admin.site.register(Brand)
admin.site.register(Vendor)


@admin.register(Banner)
class BannerAdmin(admin.ModelAdmin):
    list_display = ["title_en", "tone", "link", "sort_order", "is_active"]


@admin.register(HomeSection)
class HomeSectionAdmin(admin.ModelAdmin):
    list_display = ["key", "kind", "title_en", "category", "sort_order", "is_active"]
