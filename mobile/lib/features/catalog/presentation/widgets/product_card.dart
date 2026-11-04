import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/price_tag.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/entities.dart';
import 'add_to_cart_button.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void open() => context.push('/product/${product.slug}');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: open,
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(
                      emoji: product.emoji,
                      color: product.color,
                      image: product.image,
                      semanticLabel: product.name,
                    ),
                    if (product.discountPercent > 0)
                      PositionedDirectional(
                        top: 6,
                        start: 6,
                        child: _Badge(text: l10n.productOff('${product.discountPercent}')),
                      ),
                    if (!product.inStock)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: _Badge(text: l10n.productOutOfStock, color: AppColors.ink),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: open,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
              ),
            ),
            Text(product.unitLabel, maxLines: 1, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const Spacer(),
            PriceTag(price: product.price, salePrice: product.salePrice),
            const SizedBox(height: 8),
            AddToCartButton(product: product),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.color = AppColors.accent500});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Horizontal product row with a title (home, related products).
class ProductRow extends StatelessWidget {
  const ProductRow({required this.title, required this.products, this.onSeeAll, super.key});

  final String title;
  final List<Product> products;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title, onSeeAll: onSeeAll),
        SizedBox(
          height: 318,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(width: 168, child: ProductCard(product: products[i])),
          ),
        ),
      ],
    );
  }
}

/// Grid delegate shared by product grids: 2 columns on phones, more on tablets.
SliverGridDelegate productGridDelegate(BuildContext context) => const SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 220,
  mainAxisExtent: 318,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
);

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({this.count = 6, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid.builder(
        gridDelegate: productGridDelegate(context),
        itemCount: count,
        itemBuilder: (_, _) => const Card(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(aspectRatio: 1, child: Skeleton()),
                SizedBox(height: 10),
                Skeleton(height: 14),
                SizedBox(height: 6),
                Skeleton(height: 12, width: 60),
                Spacer(),
                Skeleton(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
