import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_market/core/network/api_client.dart';
import 'package:rocket_market/core/network/api_exception.dart';
import 'package:rocket_market/core/storage/key_value_store.dart';
import 'package:rocket_market/core/storage/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fake API server for Dio.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStore tokens;
  late KeyValueStore store;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    store = KeyValueStore(await SharedPreferences.getInstance());
    tokens = TokenStore(const FlutterSecureStorage());
    await tokens.save(access: 'old', refresh: 'refresh-1');
  });

  ApiClient client(FakeAdapter adapter, {void Function()? onExpired}) {
    final api = ApiClient(
      baseUrl: 'https://api.test/api/v1',
      tokens: tokens,
      cache: store,
      languageCode: () => 'ar',
      onSessionExpired: onExpired,
    );
    api.dio.httpClientAdapter = adapter;
    return api;
  }

  test('adds language and token to every request', () async {
    final adapter = FakeAdapter((_) => json(200, {'ok': true}));
    await client(adapter).get<Map<String, dynamic>>('/home/');
    final request = adapter.requests.single;
    expect(request.uri.toString(), 'https://api.test/api/v1/home/?lang=ar');
    expect(request.headers['Accept-Language'], 'ar');
    expect(request.headers['Authorization'], 'Bearer old');
  });

  test('refreshes an expired token once and retries the request', () async {
    var refreshes = 0;
    final adapter = FakeAdapter((options) {
      if (options.path.endsWith('/auth/token/refresh/')) {
        refreshes++;
        return json(200, {'access': 'new', 'refresh': 'refresh-2'});
      }
      return options.headers['Authorization'] == 'Bearer new'
          ? json(200, {'id': 1})
          : json(401, {'detail': 'expired', 'code': 'token_not_valid'});
    });
    final api = client(adapter);
    // The refresh call uses its own Dio; give it the same fake server.
    final refreshDio =
        (api.dio.interceptors.firstWhere((i) => i.runtimeType.toString() == 'AuthInterceptor') as dynamic).refreshDio
            as Dio;
    refreshDio.httpClientAdapter = adapter;

    final me = await api.get<Map<String, dynamic>>('/me/');
    expect(me['id'], 1);
    expect(refreshes, 1);
    expect(tokens.access, 'new');
    expect(tokens.refresh, 'refresh-2');
  });

  test('signs out when the refresh token is rejected', () async {
    var expired = false;
    final adapter = FakeAdapter((options) => json(401, {'detail': 'no', 'code': 'token_not_valid'}));
    final api = client(adapter, onExpired: () => expired = true);
    final refreshDio =
        (api.dio.interceptors.firstWhere((i) => i.runtimeType.toString() == 'AuthInterceptor') as dynamic).refreshDio
            as Dio;
    refreshDio.httpClientAdapter = adapter;

    await expectLater(
      api.get<dynamic>('/me/'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
    expect(expired, isTrue);
    expect(tokens.access, isNull);
  });

  test('maps DRF errors and network failures', () async {
    final adapter = FakeAdapter(
      (_) => json(409, {'detail': 'المنتج ده خلص', 'code': 'cart_changed', 'field': 'items'}),
    );
    late ApiException error;
    try {
      await client(adapter).post<dynamic>('/orders/');
      fail('expected an error');
    } on ApiException catch (e) {
      error = e;
    }
    expect(error.message, 'المنتج ده خلص');
    expect(error.code, 'cart_changed');
    expect(error.field, 'items');
    expect(error.statusCode, 409);

    final offline = ApiException.fromDio(
      DioException.connectionError(requestOptions: RequestOptions(), reason: 'offline'),
    );
    expect(offline.isNetwork, isTrue);
  });

  test('serves cached catalog responses when offline', () async {
    var online = true;
    final adapter = FakeAdapter((options) {
      if (!online) throw DioException.connectionError(requestOptions: options, reason: 'offline');
      return json(200, [
        {'slug': 'bakery'},
      ]);
    });
    final api = client(adapter);
    expect(await api.get<List<dynamic>>('/categories/'), hasLength(1));
    online = false;
    expect(await api.get<List<dynamic>>('/categories/'), [
      {'slug': 'bakery'},
    ]);
    await expectLater(
      api.get<dynamic>('/orders/'),
      throwsA(isA<ApiException>().having((e) => e.isNetwork, 'network', isTrue)),
    );
  });
}
