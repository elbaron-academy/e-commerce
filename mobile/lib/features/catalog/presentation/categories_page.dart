import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/load_state.dart';
import '../domain/catalog_repository.dart';
import '../domain/entities.dart';

class CategoriesCubit extends LoadCubit<List<CategoryNode>> {
  CategoriesCubit(CatalogRepository catalog) : super(catalog.categories);
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.lang),
      create: (_) => CategoriesCubit(sl())..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.navCategories)),
        body: LoadView<CategoriesCubit, List<CategoryNode>>(
          builder: (context, categories) => RefreshIndicator(
            onRefresh: () => context.read<CategoriesCubit>().load(silent: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _CategoryCard(category: categories[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final CategoryNode category;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/category/${category.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: category.color, borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: Text(category.emoji, style: const TextStyle(fontSize: 34)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(
                      context.l10n.categoryCount('${category.productCount}'),
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final sub in category.children)
                          InkWell(
                            borderRadius: BorderRadius.circular(99),
                            onTap: () => context.push(
                              Uri(path: '/category/${category.slug}', queryParameters: {'sub': sub.slug}).toString(),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.canvas,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(sub.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
