import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/load_state.dart';
import '../../../core/widgets/price_tag.dart';
import '../../../core/widgets/product_image.dart';
import '../domain/catalog_repository.dart';
import '../domain/entities.dart';
import 'widgets/add_to_cart_button.dart';
import 'widgets/product_card.dart';

typedef ProductBundle = ({Product product, List<Product> related});

class ProductCubit extends LoadCubit<ProductBundle> {
  ProductCubit(CatalogRepository catalog, String slug)
    : super(() async {
        final product = await catalog.product(slug);
        final related = await catalog
            .products(category: product.category.slug, exclude: slug, pageSize: 10)
            .then((p) => p.results)
            .catchError((_) => <Product>[]);
        return (product: product, related: related);
      });
}

class ProductPage extends StatelessWidget {
  const ProductPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('${context.lang}-$slug'),
      create: (_) => ProductCubit(sl(), slug)..load(),
      child: Scaffold(
        appBar: AppBar(
          actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search'))],
        ),
        body: LoadView<ProductCubit, ProductBundle>(
          builder: (context, data) => _ProductView(product: data.product, related: data.related),
        ),
      ),
    );
  }
}

class _ProductView extends StatefulWidget {
  const _ProductView({required this.product, required this.related});

  final Product product;
  final List<Product> related;

  @override
  State<_ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<_ProductView> {
  late String _sku = widget.product.defaultSku;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final product = widget.product;
    final variant = product.variant(_sku);
    final discount = variant.discountPercent;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: AspectRatio(
            aspectRatio: 1.2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Gallery(product: product),
                if (discount > 0)
                  PositionedDirectional(
                    top: 14,
                    start: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accent500, borderRadius: BorderRadius.circular(99)),
                      child: Text(
                        l10n.productOff('$discount'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (product.brand.isNotEmpty)
                Text(
                  product.brand,
                  style: const TextStyle(color: AppColors.brand700, fontWeight: FontWeight.w700),
                ),
              Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3)),
              Text(variant.label, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              PriceTag(price: variant.price, salePrice: variant.salePrice, large: true),
              if (variant.salePrice != null && product.saleEndsAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: AppColors.accent700),
                      const SizedBox(width: 4),
                      Text(
                        l10n.productOfferEnds(fmt.date(product.saleEndsAt!, 'EEEE d MMMM')),
                        style: const TextStyle(color: AppColors.accent700, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              if (product.variants.length > 1) ...[
                const SizedBox(height: 16),
                Text(l10n.productChooseSize, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final v in product.variants)
                      ChoiceTile(
                        selected: v.sku == _sku,
                        enabled: v.inStock,
                        onTap: () => setState(() => _sku = v.sku),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(v.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              fmt.money(v.unitPrice),
                              style: TextStyle(
                                fontSize: 12,
                                color: v.salePrice != null ? AppColors.accent600 : AppColors.muted,
                                fontWeight: v.salePrice != null ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (variant.inStock && variant.stock <= 5)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.productLowStock(fmt.qty(variant.stock, byWeight: product.soldByWeight)),
                    style: const TextStyle(color: AppColors.accent700, fontWeight: FontWeight.w700),
                  ),
                ),
              AddToCartButton(product: product, sku: _sku, large: true),
              if (product.soldByWeight)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.productWeightNote,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SectionCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.local_shipping_outlined, color: AppColors.brand700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l10n.productDeliveryPromise, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: l10n.productDescription,
                  child: Text(product.description, style: const TextStyle(color: AppColors.muted, height: 1.6)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        ProductRow(
          title: l10n.productRelated,
          products: widget.related,
          onSeeAll: () => context.push('/category/${product.category.slug}'),
        ),
      ],
    );
  }
}

/// Swipeable photos (MOB-301); the emoji tile when there are none.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.product});

  final Product product;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    if (p.images.length <= 1) {
      return ProductImage(
        emoji: p.emoji,
        color: p.color,
        image: p.image,
        emojiSize: 120,
        radius: 24,
        semanticLabel: p.name,
      );
    }
    return Stack(
      children: [
        PageView.builder(
          itemCount: p.images.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => InteractiveViewer(
            child: ProductImage(emoji: p.emoji, color: p.color, image: p.images[i], radius: 24),
          ),
        ),
        PositionedDirectional(
          bottom: 10,
          start: 0,
          end: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < p.images.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? AppColors.brand600 : Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
