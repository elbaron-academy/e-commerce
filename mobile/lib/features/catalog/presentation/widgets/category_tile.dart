import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({required this.category, super.key});

  final CategoryNode category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/category/${category.slug}'),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(color: category.color, borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: Text(category.emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.25),
          ),
        ],
      ),
    );
  }
}
