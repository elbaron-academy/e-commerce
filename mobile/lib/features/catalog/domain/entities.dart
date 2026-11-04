import 'dart:ui';

class CategoryRef {
  const CategoryRef({required this.slug, required this.name});

  final String slug;
  final String name;
}

class CategoryNode {
  const CategoryNode({
    required this.id,
    required this.slug,
    required this.name,
    required this.emoji,
    required this.color,
    required this.image,
    required this.productCount,
    required this.children,
  });

  final int id;
  final String slug;
  final String name;
  final String emoji;
  final Color color;
  final String? image;
  final int productCount;
  final List<CategoryNode> children;
}

/// A sellable size of a product, with its own SKU, price and stock.
class Variant {
  const Variant({
    required this.sku,
    required this.label,
    required this.price,
    required this.salePrice,
    required this.inStock,
    required this.stock,
    required this.maxQty,
  });

  final String sku;
  final String label;
  final double price;
  final double? salePrice;
  final bool inStock;
  final double stock;
  final double maxQty;

  double get unitPrice => salePrice ?? price;
  int get discountPercent => salePrice == null || price == 0 ? 0 : ((1 - salePrice! / price) * 100).round();
}

class Product {
  const Product({
    required this.id,
    required this.slug,
    required this.name,
    required this.brand,
    required this.image,
    required this.emoji,
    required this.color,
    required this.category,
    required this.subcategory,
    required this.unitLabel,
    required this.soldByWeight,
    required this.qtyStep,
    required this.minQty,
    required this.maxQty,
    required this.price,
    required this.salePrice,
    required this.discountPercent,
    required this.saleEndsAt,
    required this.inStock,
    required this.defaultSku,
    required this.variants,
    required this.tags,
    this.description = '',
    this.images = const [],
  });

  final int id;
  final String slug;
  final String name;
  final String brand;
  final String? image;
  final String emoji;
  final Color color;
  final CategoryRef category;
  final CategoryRef? subcategory;
  final String unitLabel;

  /// Quantity is a weight in kg (fruit, vegetables, meat…).
  final bool soldByWeight;
  final double qtyStep;
  final double minQty;
  final double maxQty;
  final double price;
  final double? salePrice;
  final int discountPercent;
  final DateTime? saleEndsAt;
  final bool inStock;
  final String defaultSku;
  final List<Variant> variants;
  final List<String> tags;
  final String description;
  final List<String> images;

  Variant variant([String? sku]) =>
      variants.firstWhere((v) => v.sku == (sku ?? defaultSku), orElse: () => variants.first);
}

class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.link,
    required this.emoji,
    required this.image,
    required this.tone,
  });

  final int id;
  final String title;
  final String subtitle;
  final String cta;
  final String link;
  final String emoji;
  final String? image;
  final String tone;
}

class HomeSection {
  const HomeSection({required this.key, required this.title, required this.link, required this.products});

  final String key;
  final String title;
  final String? link;
  final List<Product> products;
}

class HomeData {
  const HomeData({required this.banners, required this.sections});

  final List<HomeBanner> banners;
  final List<HomeSection> sections;
}

class Paged<T> {
  const Paged({required this.count, required this.next, required this.results});

  final int count;
  final int? next;
  final List<T> results;

  bool get hasMore => next != null;
}

class SearchSuggestion {
  const SearchSuggestion({
    required this.type,
    required this.slug,
    required this.name,
    required this.emoji,
    required this.subtitle,
  });

  final String type;
  final String slug;
  final String name;
  final String emoji;
  final String subtitle;

  bool get isCategory => type == 'category';
}
