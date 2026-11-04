import 'entities.dart';

abstract interface class CatalogRepository {
  Future<HomeData> home();
  Future<List<CategoryNode>> categories();
  Future<Paged<Product>> categoryProducts(String slug, {String? sub, String sort = 'recommended', int page = 1});
  Future<Paged<Product>> products({
    String? category,
    String? tag,
    String? exclude,
    String sort = 'recommended',
    int pageSize = 24,
  });
  Future<Product> product(String slug);
  Future<Paged<Product>> search({String? query, String? tag, String sort = 'recommended', int page = 1});
  Future<List<SearchSuggestion>> autocomplete(String query);
}
