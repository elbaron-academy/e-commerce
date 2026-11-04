import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Product photo, or the emoji on the category color until photos are uploaded.
class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.emoji,
    required this.color,
    this.image,
    this.emojiSize = 56,
    this.radius = 14,
    this.semanticLabel,
    super.key,
  });

  final String emoji;
  final Color color;
  final String? image;
  final double emojiSize;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Text(
        emoji,
        style: TextStyle(fontSize: emojiSize, height: 1.1),
        semanticsLabel: semanticLabel,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: color,
        child: image == null
            ? placeholder
            : CachedNetworkImage(
                imageUrl: image!,
                fit: BoxFit.contain,
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
