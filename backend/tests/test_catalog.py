from datetime import timedelta
from decimal import Decimal

import pytest
from django.utils import timezone

from apps.catalog.models import Category, Product, Variant
from apps.core.text import normalize_phone, normalize_text, strip_article

pytestmark = pytest.mark.django_db


def test_normalize_text_handles_arabic_letter_forms():
    assert normalize_text("أَحْمَد إِسلام آمنة") == "احمد اسلام امنه"
    assert normalize_text("مستشفى") == "مستشفي"
    assert strip_article("الموز") == "موز"
    assert strip_article("الا") == "الا"
    assert normalize_phone("+20 100 123 4567") == "01001234567"
    assert normalize_phone("٠١٠٠١٢٣٤٥٦٧") == "01001234567"


def test_home_has_banners_and_sections(api):
    res = api.get("/api/v1/home/?lang=en")
    assert res.status_code == 200
    data = res.json()
    assert len(data["banners"]) == 3
    assert [s["key"] for s in data["sections"]] == ["offers", "best", "fresh", "dairy", "new"]
    offers = data["sections"][0]["products"]
    assert offers and all("offer" in p["tags"] for p in offers)
    assert data["banners"][0]["title"] == "Fresh produce, every day"


def test_language_switch_via_query(api):
    ar = api.get("/api/v1/products/banana/").json()
    en = api.get("/api/v1/products/banana/?lang=en").json()
    assert ar["name"] == "موز"
    assert en["name"] == "Banana"
    assert en["unit_label"] == "per kg"


def test_category_tree_counts_include_subcategories(api):
    tree = api.get("/api/v1/categories/").json()
    assert len(tree) == 8
    produce = next(c for c in tree if c["slug"] == "fruits-vegetables")
    assert produce["product_count"] == 13
    assert sum(c["product_count"] for c in produce["children"]) == 13


def test_category_products_sorting_and_sub_filter(api):
    res = api.get("/api/v1/categories/dairy-eggs/products/?sort=price_asc").json()
    prices = [p["sale_price"] or p["price"] for p in res["results"]]
    assert prices == sorted(prices)
    milk = api.get("/api/v1/categories/dairy-eggs/products/?sub=milk").json()
    assert milk["count"] == 2
    assert {p["subcategory"]["slug"] for p in milk["results"]} == {"milk"}
    assert api.get("/api/v1/categories/dairy-eggs/products/?sub=fruits").status_code == 404


@pytest.mark.parametrize("sort", ["recommended", "best", "price_desc", "discount", "newest"])
def test_every_sort_works(api, sort):
    res = api.get(f"/api/v1/products/?sort={sort}&page_size=48")
    assert res.status_code == 200
    assert res.json()["count"] == 66


def test_pagination_shape(api):
    res = api.get("/api/v1/products/?page_size=10&page=2").json()
    assert res["count"] == 66
    assert res["next"] == 3 and res["previous"] == 1
    assert len(res["results"]) == 10


def test_out_of_stock_products_sort_last(api):
    results = api.get("/api/v1/categories/fruits-vegetables/products/").json()["results"]
    assert results[-1]["slug"] == "avocado"
    assert results[-1]["in_stock"] is False


def test_product_detail_shape(api):
    data = api.get("/api/v1/products/white-eggs/").json()
    assert data["default_sku"] == "RK-0021-1"
    assert len(data["variants"]) == 2
    big = data["variants"][1]
    assert big["sale_price"] == 155 and big["price"] == 165
    assert data["sale_ends_at"]
    assert data["description"]
    assert "offer" in data["tags"] and "best" in data["tags"]


def test_weight_product_fields(api):
    data = api.get("/api/v1/products/banana/").json()
    assert data["sold_by_weight"] is True
    assert data["qty_step"] == 0.25 and data["min_qty"] == 0.5 and data["max_qty"] == 5


def test_inactive_products_are_hidden(api):
    Product.objects.filter(slug="banana").update(is_active=False)
    assert api.get("/api/v1/products/banana/").status_code == 404
    assert "banana" not in [p["slug"] for p in api.get("/api/v1/products/?page_size=48").json()["results"]]


def test_future_sale_is_not_applied(api):
    Variant.objects.filter(sku="RK-0007-1").update(sale_starts_at=timezone.now() + timedelta(days=1))
    data = api.get("/api/v1/products/tomato/").json()
    assert data["sale_price"] is None and data["discount_percent"] == 0


def test_catalog_cache_refreshes_after_changes(api):
    assert api.get("/api/v1/categories/").json()[0]["name"] == "فواكه وخضروات"
    category = Category.objects.get(slug="fruits-vegetables")
    category.name_ar = "خضار وفاكهة"
    category.save()
    assert api.get("/api/v1/categories/").json()[0]["name"] == "خضار وفاكهة"


@pytest.mark.parametrize(
    ("query", "expected"),
    [
        ("الموز", "banana"),
        ("موز", "banana"),
        ("طماطة", "tomato"),  # typo
        ("banan", "banana"),
        ("chiken", "whole-chicken"),
        ("جبنه", "white-cheese"),
        ("Milk", "full-cream-milk"),
    ],
)
def test_search_handles_arabic_and_typos(api, query, expected):
    slugs = [p["slug"] for p in api.get("/api/v1/search/", {"q": query}).json()["results"]]
    assert expected in slugs[:3]


def test_search_by_brand_and_empty_query(api):
    assert api.get("/api/v1/search/", {"q": "الذهبي"}).json()["count"] == 11
    assert api.get("/api/v1/search/").json()["count"] == 0
    assert api.get("/api/v1/search/", {"q": "zzzzqqq"}).json()["count"] == 0


def test_search_by_tag_and_sort(api):
    res = api.get("/api/v1/search/", {"tag": "offer", "sort": "discount"}).json()
    assert res["count"] == 11
    sorted_res = api.get("/api/v1/search/", {"q": "لبن", "sort": "price_asc"}).json()["results"]
    prices = [p["sale_price"] or p["price"] for p in sorted_res]
    assert prices == sorted(prices)


def test_autocomplete(api):
    assert api.get("/api/v1/search/autocomplete/", {"q": "ل"}).json() == []
    suggestions = api.get("/api/v1/search/autocomplete/", {"q": "لب"}).json()
    assert suggestions and all(s["type"] == "product" for s in suggestions)
    categories = api.get("/api/v1/search/autocomplete/", {"q": "مشروب"}).json()
    assert categories[0] == {"type": "category", "slug": "beverages", "name": "مشروبات", "emoji": "🧃", "subtitle": ""}


def test_variant_max_qty_respects_stock():
    variant = Variant.objects.get(sku="RK-0034-1")  # jumbo shrimp, 3 kg in stock
    assert variant.max_qty() == Decimal("3")
