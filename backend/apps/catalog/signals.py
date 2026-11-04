from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from apps.core.cache import bump_catalog_version
from apps.shipping.models import StoreSettings, Zone

from .models import Banner, Brand, Category, HomeSection, Product, ProductImage, Variant

CATALOG_MODELS = (Category, Brand, Product, Variant, ProductImage, Banner, HomeSection, StoreSettings, Zone)


def _bump(**kwargs):
    bump_catalog_version()


for model in CATALOG_MODELS:
    post_save.connect(_bump, sender=model, dispatch_uid=f"catalog-bump-save-{model.__name__}")
    post_delete.connect(_bump, sender=model, dispatch_uid=f"catalog-bump-delete-{model.__name__}")


@receiver(post_save, sender=Category, dispatch_uid="category-reindex")
@receiver(post_save, sender=Brand, dispatch_uid="brand-reindex")
def reindex_products(sender, instance, created, **kwargs):
    """Category/brand names are part of product search text."""
    if created:
        return
    if sender is Category:
        products = Product.objects.filter(category_id__in=instance.descendant_ids())
    else:
        products = Product.objects.filter(brand=instance)
    batch = []
    for product in products.select_related("brand", "category__parent__parent"):
        product.build_search_fields()
        batch.append(product)
    Product.objects.bulk_update(batch, ["search_text", "search_name"], batch_size=500)
