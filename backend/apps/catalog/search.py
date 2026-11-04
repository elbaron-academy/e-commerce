"""
Product search (BE-302/303) on the main database: Arabic normalization, the
definite article, prefix matching and typo tolerance. Fine for a supermarket
catalog of a few thousand items. Swap in Meilisearch behind the same functions
when the catalog grows.
"""

from apps.core.cache import cached_catalog
from apps.core.i18n import tr
from apps.core.text import levenshtein, query_tokens, search_words

from .models import Category, Product, Variant


def _index() -> list[tuple[int, list[str], list[str], bool, int, bool]]:
    in_stock = set(Variant.objects.filter(is_active=True, stock__gt=0).values_list("product_id", flat=True))
    rows = Product.objects.filter(is_active=True, category__is_active=True).values_list(
        "id", "search_name", "search_text", "sold_count", "is_bestseller"
    )
    return [(pk, name.split(), text.split(), pk in in_stock, sold, best) for pk, name, text, sold, best in rows]


def _exact(words: list[str], token: str) -> bool:
    return any(w.startswith(token) or (len(token) >= 3 and token in w) for w in words)


def _fuzzy(words: list[str], token: str) -> bool:
    if len(token) < 3:
        return False
    limit = 2 if len(token) >= 6 else 1
    return any(abs(len(w) - len(token)) <= 2 and levenshtein(w, token) <= limit for w in words)


def search_product_ids(query: str) -> list[int]:
    tokens = query_tokens(query)
    if not tokens:
        return []
    index = cached_catalog("search-index", _index, timeout=600)
    for fuzzy in (False, True):

        def hit(words, token, fuzzy=fuzzy):
            return _exact(words, token) or (fuzzy and _fuzzy(words, token))

        ranked = []
        for pk, name, text, stock, sold, best in index:
            if all(hit(text, token) for token in tokens):
                name_hits = sum(1 for token in tokens if hit(name, token))
                ranked.append((-name_hits, -int(stock), -int(best), -sold, pk))
        if ranked:
            return [row[-1] for row in sorted(ranked)]
    return []


def autocomplete(query: str, products_qs, serializer_context) -> list[dict]:
    from .serializers import default_variant

    tokens = query_tokens(query)
    categories = [
        c
        for c in Category.objects.filter(is_active=True, parent__isnull=True)
        if all(_exact(search_words(c.name_ar, c.name_en), t) for t in tokens)
    ][:2]
    ids = search_product_ids(query)[:6]
    products = {p.pk: p for p in products_qs.filter(pk__in=ids)}
    suggestions = [
        {"type": "category", "slug": c.slug, "name": tr(c, "name"), "emoji": c.emoji, "subtitle": ""}
        for c in categories
    ]
    for pk in ids:
        product = products.get(pk)
        if not product:
            continue
        variant = default_variant(product)
        root = product.category.root
        suggestions.append(
            {
                "type": "product",
                "slug": product.slug,
                "name": tr(product, "name"),
                "emoji": product.emoji or root.emoji,
                "subtitle": f"{tr(variant, 'label') if variant else ''} · {tr(root, 'name')}",
            }
        )
    return suggestions
