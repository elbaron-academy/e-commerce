import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../features/auth/presentation/session_cubit.dart';
import 'app.dart';
import 'config.dart';
import 'di.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([initializeDateFormatting('ar'), initializeDateFormatting('en')]);
  // Latin digits in Arabic, like the website ("4 نوفمبر").
  DateFormat.useNativeDigitsByDefaultFor('ar', false);

  await setupDependencies(config);

  // For automated UI tests on web: `--dart-define=ENABLE_SEMANTICS=true` exposes the widget tree to the browser.
  if (const bool.fromEnvironment('ENABLE_SEMANTICS')) SemanticsBinding.instance.ensureSemantics();

  // TODO(MOB-105): send these to Firebase Crashlytics once the Firebase project exists.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  unawaited(sl<SessionCubit>().refresh());
  runApp(const RocketApp());
}
