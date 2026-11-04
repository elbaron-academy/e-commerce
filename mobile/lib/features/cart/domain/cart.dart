import '../../catalog/domain/entities.dart';

/// A cart line keeps a snapshot of the product so the cart works offline.
class CartLine {
  const CartLine({
    required this.sku,
    required this.slug,
    required this.qty,
    required this.name,
    required this.variantLabel,
    required this.emoji,
    required this.color,
    required this.image,
    required this.price,
    required this.originalPrice,
    required this.soldByWeight,
    required this.step,
    required this.min,
    required this.max,
  });

  factory CartLine.fromProduct(Product product, Variant variant) => CartLine(
    sku: variant.sku,
    slug: product.slug,
    qty: product.minQty < variant.maxQty ? product.minQty : variant.maxQty,
    name: product.name,
    variantLabel: variant.label,
    emoji: product.emoji,
    color: product.color.toARGB32(),
    image: product.image,
    price: variant.unitPrice,
    originalPrice: variant.price,
    soldByWeight: product.soldByWeight,
    step: product.qtyStep,
    min: product.minQty,
    max: variant.maxQty,
  );

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
    sku: json['sku'] as String,
    slug: json['slug'] as String,
    qty: (json['qty'] as num).toDouble(),
    name: json['name'] as String,
    variantLabel: json['variant_label'] as String,
    emoji: json['emoji'] as String,
    color: json['color'] as int,
    image: json['image'] as String?,
    price: (json['price'] as num).toDouble(),
    originalPrice: (json['original_price'] as num).toDouble(),
    soldByWeight: json['sold_by_weight'] as bool,
    step: (json['step'] as num).toDouble(),
    min: (json['min'] as num).toDouble(),
    max: (json['max'] as num).toDouble(),
  );

  final String sku;
  final String slug;
  final double qty;
  final String name;
  final String variantLabel;
  final String emoji;
  final int color;
  final String? image;
  final double price;
  final double originalPrice;
  final bool soldByWeight;
  final double step;
  final double min;
  final double max;

  bool get atMin => qty <= min + 1e-9;
  bool get atMax => qty + step > max + 1e-9;

  CartLine copyWith({
    double? qty,
    String? name,
    String? variantLabel,
    double? price,
    double? originalPrice,
    double? max,
  }) => CartLine(
    sku: sku,
    slug: slug,
    qty: qty ?? this.qty,
    name: name ?? this.name,
    variantLabel: variantLabel ?? this.variantLabel,
    emoji: emoji,
    color: color,
    image: image,
    price: price ?? this.price,
    originalPrice: originalPrice ?? this.originalPrice,
    soldByWeight: soldByWeight,
    step: step,
    min: min,
    max: max ?? this.max,
  );

  Map<String, dynamic> toJson() => {
    'sku': sku,
    'slug': slug,
    'qty': qty,
    'name': name,
    'variant_label': variantLabel,
    'emoji': emoji,
    'color': color,
    'image': image,
    'price': price,
    'original_price': originalPrice,
    'sold_by_weight': soldByWeight,
    'step': step,
    'min': min,
    'max': max,
  };
}

class QuoteLine {
  const QuoteLine({
    required this.sku,
    required this.qty,
    required this.available,
    required this.maxQty,
    required this.unitPrice,
    required this.originalUnitPrice,
    required this.lineTotal,
    required this.priceChanged,
    required this.variantLabel,
    required this.product,
  });

  final String sku;
  final double qty;
  final bool available;
  final double maxQty;
  final double unitPrice;
  final double originalUnitPrice;
  final double lineTotal;
  final bool priceChanged;
  final String variantLabel;
  final Product product;
}

class CouponResult {
  const CouponResult({required this.code, required this.valid, required this.message});

  final String code;
  final bool valid;
  final String message;
}

class QuoteWarning {
  const QuoteWarning({required this.code, required this.message});

  final String code;
  final String message;
}

/// Server pricing of a cart: stock, sale prices, coupon, delivery fee and rules.
class Quote {
  const Quote({
    required this.lines,
    required this.subtotal,
    required this.savings,
    required this.couponDiscount,
    required this.deliveryFee,
    required this.total,
    required this.minOrder,
    required this.freeDeliveryThreshold,
    required this.codAvailable,
    required this.codLimit,
    required this.coupon,
    required this.warnings,
    required this.canCheckout,
  });

  final List<QuoteLine> lines;
  final double subtotal;
  final double savings;
  final double couponDiscount;
  final double deliveryFee;
  final double total;
  final double minOrder;
  final double freeDeliveryThreshold;
  final bool codAvailable;
  final double codLimit;
  final CouponResult? coupon;
  final List<QuoteWarning> warnings;
  final bool canCheckout;

  QuoteLine? line(String sku) {
    for (final l in lines) {
      if (l.sku == sku) return l;
    }
    return null;
  }
}

class CartItemInput {
  const CartItemInput({required this.sku, required this.qty, this.expectedPrice});

  final String sku;
  final double qty;
  final double? expectedPrice;

  Map<String, dynamic> toJson() => {'sku': sku, 'qty': qty, 'expected_price': ?expectedPrice};
}
