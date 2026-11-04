import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import '../core/storage/key_value_store.dart';
import '../core/storage/token_store.dart';
import '../features/account/data/address_repository_impl.dart';
import '../features/account/domain/address.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth.dart';
import '../features/auth/presentation/session_cubit.dart';
import '../features/cart/data/cart_repository_impl.dart';
import '../features/cart/domain/cart_repository.dart';
import '../features/cart/presentation/cart_cubit.dart';
import '../features/catalog/data/catalog_repository_impl.dart';
import '../features/catalog/domain/catalog_repository.dart';
import '../features/checkout/data/delivery_repository_impl.dart';
import '../features/checkout/domain/delivery.dart';
import '../features/orders/data/orders_repository_impl.dart';
import '../features/orders/domain/order.dart';
import '../features/settings/locale_cubit.dart';
import 'config.dart';

/// Service locator (GetIt). Repositories are singletons; screen cubits are created by the screens.
final sl = GetIt.instance;

Future<void> setupDependencies(AppConfig config) async {
  final store = KeyValueStore(await SharedPreferences.getInstance());
  final tokens = TokenStore(const FlutterSecureStorage());
  await tokens.load();

  sl
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<KeyValueStore>(store)
    ..registerSingleton<TokenStore>(tokens)
    ..registerSingleton<LocaleCubit>(LocaleCubit(store))
    ..registerSingleton<ApiClient>(
      ApiClient(
        baseUrl: config.apiBaseUrl,
        tokens: tokens,
        cache: store,
        languageCode: () => sl<LocaleCubit>().languageCode,
        onSessionExpired: () => sl<SessionCubit>().expired(),
      ),
    )
    ..registerLazySingleton<CatalogRepository>(() => CatalogRepositoryImpl(sl()))
    ..registerLazySingleton<CartRepository>(() => CartRepositoryImpl(sl(), sl()))
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl(), sl()))
    ..registerLazySingleton<AddressRepository>(() => AddressRepositoryImpl(sl()))
    ..registerLazySingleton<DeliveryRepository>(() => DeliveryRepositoryImpl(sl()))
    ..registerLazySingleton<OrdersRepository>(() => OrdersRepositoryImpl(sl()))
    ..registerSingleton<SessionCubit>(SessionCubit(sl()))
    ..registerSingleton<CartCubit>(CartCubit(sl()));
}
