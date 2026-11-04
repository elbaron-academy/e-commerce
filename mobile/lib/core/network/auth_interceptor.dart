import 'package:dio/dio.dart';

import '../storage/token_store.dart';

/// Adds the JWT and refreshes it once when the API answers 401 (MOB-103).
/// Queued, so parallel requests wait for a single refresh.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.tokens, required this.dio, required this.refreshDio, this.onSessionExpired});

  final TokenStore tokens;
  final Dio dio;
  final Dio refreshDio;
  final void Function()? onSessionExpired;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final access = tokens.access;
    if (access != null && options.extra['skipAuth'] != true) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final unauthorized = err.response?.statusCode == 401;
    final sentAuth = options.headers['Authorization'] as String?;
    if (!unauthorized || sentAuth == null || options.extra['retried'] == true) {
      return handler.next(err);
    }

    // Another request may already have refreshed the token while this one waited.
    final alreadyRefreshed = tokens.access != null && sentAuth != 'Bearer ${tokens.access}';
    if (!alreadyRefreshed && !await _refresh()) {
      await _expire();
      return handler.next(err);
    }
    await _retry(options, handler);
  }

  /// Exchanges the refresh token for a new pair. Returns false if that isn't possible.
  Future<bool> _refresh() async {
    final refresh = tokens.refresh;
    if (refresh == null) return false;
    try {
      final response = await refreshDio.post<Map<String, dynamic>>('/auth/token/refresh/', data: {'refresh': refresh});
      final data = response.data!;
      await tokens.save(access: data['access'] as String, refresh: (data['refresh'] as String?) ?? refresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _retry(RequestOptions options, ErrorInterceptorHandler handler) async {
    options.extra['retried'] = true;
    options.headers['Authorization'] = 'Bearer ${tokens.access}';
    if (options.data case final FormData form) options.data = form.clone();
    try {
      handler.resolve(await dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<void> _expire() async {
    await tokens.clear();
    onSessionExpired?.call();
  }
}
