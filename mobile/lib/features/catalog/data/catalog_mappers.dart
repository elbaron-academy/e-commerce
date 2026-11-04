import '../../../core/utils/formatters.dart';
import '../domain/entities.dart';

typedef Json = Map<String, dynamic>;

double _d(Object? value) => (value as num?)?.toDouble() ?? 0;
double? _dn(Object? value) => (value as num?)?.toDouble();

CategoryRef categoryRefFromJson(Json json) => CategoryRef(slug: json['slug'] as String, name: json['name'] as String);

CategoryNode categoryFromJson(Json json) => CategoryNode(
  id: json['id'] as int,
  slug: json['slug'] as String,
  name: json['name'] as String,
  emoji: (json['emoji'] as String?) ?? '',
  color: parseHexColor(json['color'] as String?),
  image: json['image'] as String?,
  productCount: (json['product_count'] as int?) ?? 0,
  children: [for (final c in (json['children'] as List? ?? const [])) categoryFromJson(c as Json)],
);

Variant variantFromJson(Json json) => Variant(
  sku: json['sku'] as String,
  label: json['label'] as String,
  price: _d(json['price']),
  salePrice: _dn(json['sale_price']),
  inStock: json['in_stock'] as bool,
  stock: _d(json['stock']),
  maxQty: _d(json['max_qty']),
);

Product productFromJson(Json json) => Product(
  id: json['id'] as int,
  slug: json['slug'] as String,
  name: json['name'] as String,
  brand: (json['brand'] as String?) ?? '',
  image: json['image'] as String?,
  emoji: (json['emoji'] as String?) ?? '🛒',
  color: parseHexColor(json['color'] as String?),
  category: categoryRefFromJson(json['category'] as Json),
  subcategory: json['subcategory'] == null ? null : categoryRefFromJson(json['subcategory'] as Json),
  unitLabel: (json['unit_label'] as String?) ?? '',
  soldByWeight: json['sold_by_weight'] as bool? ?? false,
  qtyStep: _d(json['qty_step']),
  minQty: _d(json['min_qty']),
  maxQty: _d(json['max_qty']),
  price: _d(json['price']),
  salePrice: _dn(json['sale_price']),
  discountPercent: (json['discount_percent'] as num?)?.toInt() ?? 0,
  saleEndsAt: json['sale_ends_at'] == null ? null : DateTime.parse('${json['sale_ends_at']}T12:00:00'),
  inStock: json['in_stock'] as bool? ?? false,
  defaultSku: json['default_sku'] as String,
  variants: [for (final v in json['variants'] as List) variantFromJson(v as Json)],
  tags: [for (final t in (json['tags'] as List? ?? const [])) t as String],
  description: (json['description'] as String?) ?? '',
  images: [for (final i in (json['images'] as List? ?? const [])) i as String],
);

Paged<T> pagedFromJson<T>(Json json, T Function(Json) item) => Paged(
  count: json['count'] as int,
  next: json['next'] as int?,
  results: [for (final r in json['results'] as List) item(r as Json)],
);

HomeData homeFromJson(Json json) => HomeData(
  banners: [
    for (final b in json['banners'] as List)
      HomeBanner(
        id: b['id'] as int,
        title: b['title'] as String,
        subtitle: (b['subtitle'] as String?) ?? '',
        cta: (b['cta'] as String?) ?? '',
        link: b['link'] as String,
        emoji: (b['emoji'] as String?) ?? '',
        image: b['image'] as String?,
        tone: (b['tone'] as String?) ?? 'green',
      ),
  ],
  sections: [
    for (final s in json['sections'] as List)
      HomeSection(
        key: s['key'] as String,
        title: s['title'] as String,
        link: s['link'] as String?,
        products: [for (final p in s['products'] as List) productFromJson(p as Json)],
      ),
  ],
);

SearchSuggestion suggestionFromJson(Json json) => SearchSuggestion(
  type: json['type'] as String,
  slug: json['slug'] as String,
  name: json['name'] as String,
  emoji: (json['emoji'] as String?) ?? '',
  subtitle: (json['subtitle'] as String?) ?? '',
);
