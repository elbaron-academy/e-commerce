import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/common.dart';
import '../domain/catalog_repository.dart';
import '../domain/entities.dart';
import 'widgets/product_card.dart';

const sortOptions = ['recommended', 'best', 'price_asc', 'price_desc', 'discount', 'newest'];

class CategoryState extends Equatable {
  const CategoryState({
    this.category,
    this.sub,
    this.sort = 'recommended',
    this.products = const [],
    this.count = 0,
    this.nextPage,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final CategoryNode? category;
  final String? sub;
  final String sort;
  final List<Product> products;
  final int count;
  final int? nextPage;
  final bool loading;
  final bool loadingMore;
  final Object? error;

  CategoryState copyWith({
    CategoryNode? category,
    String? Function()? sub,
    String? sort,
    List<Product>? products,
    int? count,
    int? Function()? nextPage,
    bool? loading,
    bool? loadingMore,
    Object? Function()? error,
  }) => CategoryState(
    category: category ?? this.category,
    sub: sub != null ? sub() : this.sub,
    sort: sort ?? this.sort,
    products: products ?? this.products,
    count: count ?? this.count,
    nextPage: nextPage != null ? nextPage() : this.nextPage,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [category?.slug, sub, sort, products, count, nextPage, loading, loadingMore, error];
}

/// Products of a category with subcategory filter, sort and infinite scroll (MOB-202, MOB-303).
class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(this._catalog, this.slug, {String? sub}) : super(CategoryState(sub: sub));

  final CatalogRepository _catalog;
  final String slug;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final results = await Future.wait([
        if (state.category == null) _catalog.categories() else Future.value(<CategoryNode>[]),
        _catalog.categoryProducts(slug, sub: state.sub, sort: state.sort),
      ]);
      final tree = results[0] as List<CategoryNode>;
      final page = results[1] as Paged<Product>;
      final category = state.category ?? tree.where((c) => c.slug == slug).firstOrNull;
      emit(
        state.copyWith(
          category: category,
          products: page.results,
          count: page.count,
          nextPage: () => page.next,
          loading: false,
        ),
      );
    } catch (error) {
      emit(state.copyWith(loading: false, error: () => error));
    }
  }

  Future<void> loadMore() async {
    final page = state.nextPage;
    if (page == null || state.loadingMore || state.loading) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final result = await _catalog.categoryProducts(slug, sub: state.sub, sort: state.sort, page: page);
      emit(
        state.copyWith(
          products: [...state.products, ...result.results],
          nextPage: () => result.next,
          loadingMore: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(loadingMore: false));
    }
  }

  void selectSub(String? sub) {
    if (sub == state.sub) return;
    emit(state.copyWith(sub: () => sub, products: const []));
    load();
  }

  void selectSort(String sort) {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort, products: const []));
    load();
  }
}

class CategoryPage extends StatelessWidget {
  const CategoryPage({required this.slug, this.sub, super.key});

  final String slug;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.lang),
      create: (_) => CategoryCubit(sl(), slug, sub: sub)..load(),
      child: const _CategoryView(),
    );
  }
}

class _CategoryView extends StatelessWidget {
  const _CategoryView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CategoryCubit>();
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        final category = state.category;
        return Scaffold(
          appBar: AppBar(
            title: Text(category?.name ?? ''),
            actions: [
              IconButton(
                tooltip: l10n.sortLabel,
                icon: const Icon(Icons.sort),
                onPressed: () => _showSortSheet(context, state.sort, cubit.selectSort),
              ),
            ],
          ),
          body: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) cubit.loadMore();
              return false;
            },
            child: RefreshIndicator(
              onRefresh: cubit.load,
              child: CustomScrollView(
                slivers: [
                  if (category != null && category.children.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 56,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                          children: [
                            _SubChip(
                              label: l10n.commonAll,
                              selected: state.sub == null,
                              onTap: () => cubit.selectSub(null),
                            ),
                            for (final s in category.children)
                              _SubChip(
                                label: s.name,
                                selected: state.sub == s.slug,
                                onTap: () => cubit.selectSub(s.slug),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (!state.loading && state.error == null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Text(
                          '${l10n.categoryCount('${state.count}')} · ${sortLabel(l10n, state.sort)}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ),
                    ),
                  if (state.loading && state.products.isEmpty)
                    const ProductGridSkeleton()
                  else if (state.error != null && state.products.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorView(error: state.error!, onRetry: cubit.load),
                    )
                  else if (state.products.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(emoji: '🧺', title: l10n.categoryEmpty),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid.builder(
                        gridDelegate: productGridDelegate(context),
                        itemCount: state.products.length,
                        itemBuilder: (_, i) => ProductCard(product: state.products[i]),
                      ),
                    ),
                  if (state.loadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SubChip extends StatelessWidget {
  const _SubChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}

/// Sort options in a bottom sheet (MOB-303).
Future<void> _showSortSheet(BuildContext context, String current, ValueChanged<String> onSelected) {
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: RadioGroup<String>(
        groupValue: current,
        onChanged: (value) {
          Navigator.pop(sheetContext);
          if (value != null) onSelected(value);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(l10n.sortApply, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            for (final option in sortOptions)
              RadioListTile<String>(value: option, title: Text(sortLabel(l10n, option))),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
