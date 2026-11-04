import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/storage/key_value_store.dart';
import '../../../core/widgets/common.dart';
import '../domain/catalog_repository.dart';
import '../domain/entities.dart';
import 'widgets/product_card.dart';

class SearchState extends Equatable {
  const SearchState({
    this.text = '',
    this.query,
    this.tag,
    this.suggestions = const [],
    this.recent = const [],
    this.results,
    this.loading = false,
    this.error,
  });

  final String text;
  final String? query;
  final String? tag;
  final List<SearchSuggestion> suggestions;
  final List<String> recent;
  final Paged<Product>? results;
  final bool loading;
  final Object? error;

  bool get showingResults => (query != null && query!.isNotEmpty) || tag != null;

  SearchState copyWith({
    String? text,
    String? Function()? query,
    String? Function()? tag,
    List<SearchSuggestion>? suggestions,
    List<String>? recent,
    Paged<Product>? Function()? results,
    bool? loading,
    Object? Function()? error,
  }) => SearchState(
    text: text ?? this.text,
    query: query != null ? query() : this.query,
    tag: tag != null ? tag() : this.tag,
    suggestions: suggestions ?? this.suggestions,
    recent: recent ?? this.recent,
    results: results != null ? results() : this.results,
    loading: loading ?? this.loading,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [text, query, tag, suggestions, recent, results, loading, error];
}

/// Search with live suggestions after 2 letters (debounced) and search history (MOB-302).
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._catalog, this._store, {String? query, String? tag})
    : super(SearchState(text: query ?? '', recent: _store.getStringList(_recentKey))) {
    if (tag != null) {
      showTag(tag);
    } else if (query != null && query.isNotEmpty) {
      submit(query);
    }
  }

  static const _recentKey = 'rk_recent_searches';

  final CatalogRepository _catalog;
  final KeyValueStore _store;
  Timer? _debounce;
  int _seq = 0;

  void typed(String text) {
    emit(state.copyWith(text: text));
    _debounce?.cancel();
    final term = text.trim();
    if (term.length < 2) {
      emit(state.copyWith(suggestions: const []));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final id = ++_seq;
      try {
        final suggestions = await _catalog.autocomplete(term);
        if (id == _seq && !isClosed) emit(state.copyWith(suggestions: suggestions));
      } catch (_) {
        // Offline: no suggestions.
      }
    });
  }

  Future<void> submit(String text) async {
    final term = text.trim();
    if (term.isEmpty) return;
    _debounce?.cancel();
    _remember(term);
    emit(
      state.copyWith(
        text: term,
        query: () => term,
        tag: () => null,
        suggestions: const [],
        loading: true,
        error: () => null,
      ),
    );
    await _run(() => _catalog.search(query: term));
  }

  Future<void> showTag(String tag) async {
    emit(state.copyWith(tag: () => tag, query: () => null, loading: true, error: () => null));
    await _run(() => _catalog.search(tag: tag));
  }

  void clearResults() => emit(state.copyWith(query: () => null, tag: () => null, results: () => null));

  void clearRecent() {
    _store.setStringList(_recentKey, const []);
    emit(state.copyWith(recent: const []));
  }

  Future<void> _run(Future<Paged<Product>> Function() search) async {
    try {
      final results = await search();
      if (!isClosed) emit(state.copyWith(results: () => results, loading: false));
    } catch (error) {
      if (!isClosed) emit(state.copyWith(loading: false, error: () => error));
    }
  }

  void _remember(String term) {
    final recent = [term, ...state.recent.where((t) => t != term)].take(8).toList();
    _store.setStringList(_recentKey, recent);
    emit(state.copyWith(recent: recent));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({this.query, this.tag, super.key});

  final String? query;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.lang),
      create: (_) => SearchCubit(sl(), sl(), query: query, tag: tag),
      child: _SearchView(autofocus: query == null && tag == null),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView({required this.autofocus});

  final bool autofocus;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final _controller = TextEditingController(text: context.read<SearchCubit>().state.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String term) {
    _controller.text = term;
    FocusScope.of(context).unfocus();
    context.read<SearchCubit>().submit(term);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SearchCubit>();
    final popular = context.lang == 'ar'
        ? const ['لبن', 'عيش', 'بيض', 'طماطم', 'فراخ', 'مياه', 'أرز', 'جبنة']
        : const ['Milk', 'Bread', 'Eggs', 'Tomato', 'Chicken', 'Water', 'Rice', 'Cheese'];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.search,
          onChanged: cubit.typed,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: l10n.headerSearchPlaceholder,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.canvas,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            isDense: true,
            suffixIcon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        cubit
                          ..typed('')
                          ..clearResults();
                      },
                    ),
            ),
          ),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state.suggestions.isNotEmpty) {
            return ListView(
              children: [
                for (final s in state.suggestions)
                  ListTile(
                    leading: Text(s.emoji, style: const TextStyle(fontSize: 26)),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(s.isCategory ? l10n.searchInCategory : s.subtitle),
                    onTap: () => context.push(s.isCategory ? '/category/${s.slug}' : '/product/${s.slug}'),
                  ),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: Text(l10n.searchSeeResults(state.text.trim())),
                  onTap: () => _search(state.text),
                ),
              ],
            );
          }
          if (state.showingResults) {
            return _Results(state: state, onRetry: () => _search(state.query ?? ''), popular: popular, onTerm: _search);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.recent.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.searchRecent, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    TextButton(onPressed: cubit.clearRecent, child: Text(l10n.searchClear)),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final term in state.recent)
                      ActionChip(
                        avatar: const Icon(Icons.history, size: 16),
                        label: Text(term),
                        onPressed: () => _search(term),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              Text(l10n.searchPopular, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final term in popular) ActionChip(label: Text(term), onPressed: () => _search(term))],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state, required this.onRetry, required this.popular, required this.onTerm});

  final SearchState state;
  final VoidCallback onRetry;
  final List<String> popular;
  final ValueChanged<String> onTerm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results = state.results;
    if (state.loading && results == null) {
      return const CustomScrollView(slivers: [ProductGridSkeleton()]);
    }
    if (state.error != null && results == null) return ErrorView(error: state.error!, onRetry: onRetry);
    final count = results?.count ?? 0;
    final heading = state.tag != null
        ? tagTitle(l10n, state.tag!)
        : count == 0
        ? l10n.searchNoResults(state.query ?? '')
        : l10n.searchResults('$count', state.query ?? '');
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(heading, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
        if (count == 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('🔎', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(l10n.searchTryAnother, style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final term in popular) ActionChip(label: Text(term), onPressed: () => onTerm(term)),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.builder(
              gridDelegate: productGridDelegate(context),
              itemCount: results!.results.length,
              itemBuilder: (_, i) => ProductCard(product: results.results[i]),
            ),
          ),
      ],
    );
  }
}
