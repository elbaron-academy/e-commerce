import 'dart:convert';

import 'package:dio/dio.dart';

import '../storage/key_value_store.dart';

/// Keeps the last catalog responses (home, categories, products, search, delivery)
/// and serves them when there is no connection, like the web app's service worker.
class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor(this._store);

  static const prefix = 'http_cache:';
  static const _maxEntries = 200;
  static final _cacheable = RegExp(r'/(home|categories|products|search|delivery)/');

  final KeyValueStore _store;

  bool _isCacheable(RequestOptions options) => options.method == 'GET' && _cacheable.hasMatch(options.uri.path);
  String _key(RequestOptions options) => '$prefix${options.uri}';

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    if (_isCacheable(options) && response.statusCode == 200 && response.data != null) {
      _store.setString(_key(options), jsonEncode(response.data));
      _trim();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final offline = err.response == null;
    if (offline && _isCacheable(options)) {
      final cached = _store.getString(_key(options));
      if (cached != null) {
        return handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: jsonDecode(cached),
            statusCode: 200,
            extra: {'fromCache': true},
          ),
        );
      }
    }
    handler.next(err);
  }

  void _trim() {
    final keys = _store.keysWithPrefix(prefix).toList();
    if (keys.length > _maxEntries) {
      for (final key in keys.take(keys.length - _maxEntries)) {
        _store.remove(key);
      }
    }
  }
}
