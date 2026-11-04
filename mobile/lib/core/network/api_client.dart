import 'package:dio/dio.dart';

import '../storage/key_value_store.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';
import 'offline_cache_interceptor.dart';

/// HTTP client for the Rocket API. Every request carries the app language
/// (`?lang=` + Accept-Language) so texts come back translated.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStore tokens,
    required KeyValueStore cache,
    required String Function() languageCode,
    void Function()? onSessionExpired,
    Dio? dio,
  }) : dio = dio ?? Dio(_options(baseUrl)) {
    final refreshDio = Dio(_options(baseUrl));
    this.dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final lang = languageCode();
          options.queryParameters = {'lang': lang, ...options.queryParameters};
          options.headers['Accept-Language'] = lang;
          handler.next(options);
        },
      ),
      AuthInterceptor(tokens: tokens, dio: this.dio, refreshDio: refreshDio, onSessionExpired: onSessionExpired),
      OfflineCacheInterceptor(cache),
    ]);
  }

  final Dio dio;

  static BaseOptions _options(String baseUrl) => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/json'},
  );

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) => _send(() => dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? data}) => _send(() => dio.post<T>(path, data: data));

  Future<T> patch<T>(String path, {Object? data}) => _send(() => dio.patch<T>(path, data: data));

  Future<void> delete(String path) => _send(() => dio.delete<dynamic>(path));

  Future<T> _send<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
