import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/account/presentation/account_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/session_cubit.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/catalog/presentation/categories_page.dart';
import '../features/catalog/presentation/category_page.dart';
import '../features/catalog/presentation/home_page.dart';
import '../features/catalog/presentation/product_page.dart';
import '../features/catalog/presentation/search_page.dart';
import '../features/checkout/presentation/checkout_page.dart';
import '../features/checkout/presentation/mock_payment_page.dart';
import '../features/orders/presentation/order_detail_page.dart';
import '../features/orders/presentation/orders_page.dart';
import 'main_shell.dart';

/// Routes use the same paths as the website, so links can open in the app later (MOB-304).
GoRouter createRouter(SessionCubit session) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/',
    refreshListenable: _StreamListenable(session.stream),
    redirect: (context, state) {
      final loggedIn = session.state.isLoggedIn;
      final location = state.matchedLocation;
      final needsAuth =
          location.startsWith('/checkout') ||
          location.startsWith('/payment') ||
          RegExp(r'^/orders/\d+').hasMatch(location);
      if (needsAuth && !loggedIn) {
        return Uri(path: '/login', queryParameters: {'redirect': state.uri.toString()}).toString();
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/categories', builder: (_, _) => const CategoriesPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/cart', builder: (_, _) => const CartPage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (_, _) => const OrdersPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) => OrderDetailPage(
                      orderId: int.parse(state.pathParameters['id']!),
                      banner: state.uri.queryParameters['paid'] != null
                          ? OrderBanner.paid
                          : state.uri.queryParameters['placed'] != null
                          ? OrderBanner.placed
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/account', builder: (_, _) => const AccountPage())],
          ),
        ],
      ),
      GoRoute(
        path: '/category/:slug',
        builder: (_, state) => CategoryPage(slug: state.pathParameters['slug']!, sub: state.uri.queryParameters['sub']),
      ),
      GoRoute(
        path: '/product/:slug',
        builder: (_, state) => ProductPage(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/search',
        builder: (_, state) => SearchPage(query: state.uri.queryParameters['q'], tag: state.uri.queryParameters['tag']),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutPage()),
      GoRoute(
        path: '/payment/mock',
        builder: (_, state) => MockPaymentPage(orderId: int.parse(state.uri.queryParameters['order'] ?? '0')),
      ),
    ],
  );
}

/// Opens a link from the API (banners, "see all"), switching tabs for top-level sections.
void openLink(BuildContext context, String link) {
  const tabs = {'/', '/categories', '/cart', '/orders', '/account'};
  if (tabs.contains(link)) {
    context.go(link);
  } else {
    context.push(link);
  }
}

class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
