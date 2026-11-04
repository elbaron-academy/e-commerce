from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework.generics import ListAPIView, RetrieveAPIView
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.cache import cached_catalog
from apps.core.i18n import tr

from . import search, selectors
from .models import Banner, Category, HomeSection, Product
from .serializers import (
    CategoryNodeSerializer,
    HomeSerializer,
    ProductDetailSerializer,
    ProductSummarySerializer,
    SearchSuggestionSerializer,
    _url,
    category_tree,
)

SORT_PARAM = OpenApiParameter("sort", enum=selectors.SORTS, required=False)


def _sort(request) -> str:
    sort = request.query_params.get("sort", "recommended")
    return sort if sort in selectors.SORTS else "recommended"


class HomeView(APIView):
    """Home page: banners and product rows (cached, refreshed on any catalog change)."""

    @extend_schema(responses=HomeSerializer)
    def get(self, request):
        return Response(cached_catalog("home", lambda: self.build(request), timeout=300))

    def build(self, request):
        now = timezone.now()
        banners = Banner.objects.filter(is_active=True).filter(
            Q(starts_at__isnull=True) | Q(starts_at__lte=now), Q(ends_at__isnull=True) | Q(ends_at__gte=now)
        )
        sections = []
        for section in HomeSection.objects.filter(is_active=True).select_related("category"):
            products = selectors.storefront_products()
            link = None
            if section.kind == HomeSection.Kind.OFFERS:
                products, link = selectors.with_tag(products, "offer"), "/search?tag=offer"
            elif section.kind == HomeSection.Kind.BEST:
                products, link = selectors.with_tag(products, "best"), "/search?tag=best"
            elif section.kind == HomeSection.Kind.NEW:
                products, link = selectors.with_tag(products, "new"), "/search?tag=new"
            elif section.category_id:
                products, link = selectors.in_category(products, section.category), f"/category/{section.category.slug}"
            items = list(selectors.sort_products(products, "recommended")[: section.limit])
            if items:
                sections.append(
                    {
                        "key": section.key,
                        "title": tr(section, "title"),
                        "link": link,
                        "products": ProductSummarySerializer(
                            items, many=True, context={"request": request, "now": now}
                        ).data,
                    }
                )
        return {
            "banners": [
                {
                    "id": b.pk,
                    "title": tr(b, "title"),
                    "subtitle": tr(b, "subtitle"),
                    "cta": tr(b, "cta"),
                    "link": b.link,
                    "emoji": b.emoji,
                    "image": _url(request, b.image),
                    "tone": b.tone,
                }
                for b in banners
            ],
            "sections": sections,
        }


class CategoryTreeView(APIView):
    @extend_schema(responses=CategoryNodeSerializer(many=True))
    def get(self, request):
        return Response(cached_catalog("category-tree", lambda: category_tree(request), timeout=600))


class CategoryProductsView(ListAPIView):
    """Products in a category and its subcategories, 24 per page (BE-208)."""

    serializer_class = ProductSummarySerializer

    @extend_schema(parameters=[OpenApiParameter("sub", str, description="Subcategory slug"), SORT_PARAM])
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Product.objects.none()
        category = get_object_or_404(Category, slug=self.kwargs["slug"], is_active=True)
        sub_slug = self.request.query_params.get("sub")
        if sub_slug:
            category = get_object_or_404(Category, slug=sub_slug, is_active=True, parent=category)
        return selectors.sort_products(
            selectors.in_category(selectors.storefront_products(), category), _sort(self.request)
        )


class ProductListView(ListAPIView):
    serializer_class = ProductSummarySerializer

    @extend_schema(
        parameters=[
            OpenApiParameter("category", str),
            OpenApiParameter("tag", enum=["offer", "best", "new"]),
            OpenApiParameter("exclude", str, description="Product slug to leave out"),
            SORT_PARAM,
        ]
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    def get_queryset(self):
        params = self.request.query_params
        qs = selectors.storefront_products()
        if params.get("category"):
            category = Category.objects.filter(slug=params["category"], is_active=True).first()
            qs = selectors.in_category(qs, category) if category else qs.none()
        if params.get("tag"):
            qs = selectors.with_tag(qs, params["tag"])
        if params.get("exclude"):
            qs = qs.exclude(slug=params["exclude"])
        return selectors.sort_products(qs, _sort(self.request))


class ProductDetailView(RetrieveAPIView):
    serializer_class = ProductDetailSerializer
    lookup_field = "slug"

    def get_queryset(self):
        return selectors.storefront_products()


class SearchView(ListAPIView):
    """Search by text (`q`) or by tag (`tag=offer|best|new`)."""

    serializer_class = ProductSummarySerializer
    queryset = Product.objects.none()  # results come from the search index

    @extend_schema(
        parameters=[OpenApiParameter("q", str), OpenApiParameter("tag", enum=["offer", "best", "new"]), SORT_PARAM]
    )
    def get(self, request, *args, **kwargs):
        query = request.query_params.get("q", "").strip()
        sort = _sort(request)
        products = selectors.storefront_products()
        if query:
            ids = search.search_product_ids(query)
            if sort != "recommended":
                ids = list(selectors.sort_products(products.filter(pk__in=ids), sort).values_list("pk", flat=True))
            page_ids = self.paginate_queryset(ids)
            by_id = {p.pk: p for p in products.filter(pk__in=page_ids)}
            items = [by_id[pk] for pk in page_ids if pk in by_id]
        elif request.query_params.get("tag"):
            items = self.paginate_queryset(
                selectors.sort_products(selectors.with_tag(products, request.query_params["tag"]), sort)
            )
        else:
            items = self.paginate_queryset([])
        return self.get_paginated_response(self.get_serializer(items, many=True).data)


class AutocompleteView(APIView):
    """Suggestions after 2 characters (BE-304)."""

    @extend_schema(
        parameters=[OpenApiParameter("q", str, required=True)], responses=SearchSuggestionSerializer(many=True)
    )
    def get(self, request):
        query = request.query_params.get("q", "").strip()
        if len(query) < 2:
            return Response([])
        return Response(search.autocomplete(query, selectors.storefront_products(), {"request": request}))
