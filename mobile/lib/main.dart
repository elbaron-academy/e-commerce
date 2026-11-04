import 'app/bootstrap.dart';
import 'app/config.dart';

/// Production build (same as main_prod.dart), used by plain `flutter run` / `flutter build`.
void main() => bootstrap(AppConfig.forFlavor(Flavor.prod));
