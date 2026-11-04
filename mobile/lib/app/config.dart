/// Build flavors (MOB-001). Pick one with the entrypoint:
///   flutter run -t lib/main_dev.dart        (local `make api` backend)
///   flutter run -t lib/main_staging.dart
///   flutter run -t lib/main_prod.dart
/// `--dart-define=API_BASE_URL=...` overrides the API address for any flavor.
enum Flavor { dev, staging, prod }

class AppConfig {
  const AppConfig({required this.flavor, required this.apiBaseUrl, required this.storefrontUrl});

  factory AppConfig.forFlavor(Flavor flavor) {
    const override = String.fromEnvironment('API_BASE_URL');
    final apiBaseUrl = switch (flavor) {
      // 10.0.2.2 is your computer as seen from the Android emulator (use localhost on iOS).
      Flavor.dev => 'http://10.0.2.2:8000/api/v1',
      // No separate staging server yet: staging talks to production.
      Flavor.staging => 'https://api.rocket.hossam-ameen.online/api/v1',
      Flavor.prod => 'https://api.rocket.hossam-ameen.online/api/v1',
    };
    return AppConfig(
      flavor: flavor,
      apiBaseUrl: override.isNotEmpty ? override : apiBaseUrl,
      storefrontUrl: 'https://rocket.hossam-ameen.online',
    );
  }

  final Flavor flavor;
  final String apiBaseUrl;
  final String storefrontUrl;

  bool get isProd => flavor == Flavor.prod;
}
