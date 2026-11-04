import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n.dart';
import '../features/auth/presentation/session_cubit.dart';
import '../features/cart/presentation/cart_cubit.dart';
import '../features/settings/locale_cubit.dart';
import 'di.dart';
import 'router.dart';
import 'theme.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class RocketApp extends StatefulWidget {
  const RocketApp({super.key});

  @override
  State<RocketApp> createState() => _RocketAppState();
}

class _RocketAppState extends State<RocketApp> {
  late final GoRouter _router = createRouter(sl<SessionCubit>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<LocaleCubit>()),
        BlocProvider.value(value: sl<SessionCubit>()),
        BlocProvider.value(value: sl<CartCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) => MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.brandName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          scaffoldMessengerKey: scaffoldMessengerKey,
          routerConfig: _router,
          builder: (context, child) => BlocListener<SessionCubit, SessionState>(
            listenWhen: (previous, current) => current.expired && !previous.expired,
            listener: (context, _) => scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text(context.l10n.errorSessionExpired)),
            ),
            child: child!,
          ),
        ),
      ),
    );
  }
}

/// Shows a short message at the bottom of the screen.
void showMessage(String message) {
  scaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
}
