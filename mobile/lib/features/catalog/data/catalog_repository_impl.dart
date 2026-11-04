import '../../../core/network/api_client.dart';
import '../domain/catalog_repository.dart';
import '../domain/entities.dart';
import 'catalog_mappers.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<HomeData> home() async => homeFromJson(await _api.get<Json>('/home/'));

  @override
  Future<List<CategoryNode>> categories() async {
    final data = await _api.get<List<dynamic>>('/categories/');
    return [for (final c in data) categoryFromJson(c as Json)];
  }

  @override
  Future<Paged<Product>> categoryProducts(String slug, {String? sub, String sort = 'recommended', int page = 1}) async {
    final data = await _api.get<Json>('/categories/$slug/products/', query: {'sub': ?sub, 'sort': sort, 'page': page});
    return pagedFromJson(data, productFromJson);
  }

  @override
  Future<Paged<Product>> products({
    String? category,
    String? tag,
    String? exclude,
    String sort = 'recommended',
    int pageSize = 24,
  }) async {
    final data = await _api.get<Json>(
      '/products/',
      query: {'category': ?category, 'tag': ?tag, 'exclude': ?exclude, 'sort': sort, 'page_size': pageSize},
    );
    return pagedFromJson(data, productFromJson);
  }

  @override
  Future<Product> product(String slug) async => productFromJson(await _api.get<Json>('/products/$slug/'));

  @override
  Future<Paged<Product>> search({String? query, String? tag, String sort = 'recommended', int page = 1}) async {
    final data = await _api.get<Json>(
      '/search/',
      query: {
        if (query != null && query.isNotEmpty) 'q': query,
        'tag': ?tag,
        'sort': sort,
        'page': page,
        'page_size': 48,
      },
    );
    return pagedFromJson(data, productFromJson);
  }

  @override
  Future<List<SearchSuggestion>> autocomplete(String query) async {
    final data = await _api.get<List<dynamic>>('/search/autocomplete/', query: {'q': query});
    return [for (final s in data) suggestionFromJson(s as Json)];
  }
}
