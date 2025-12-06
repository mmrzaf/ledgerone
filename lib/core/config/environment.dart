enum Environment {
  dev,
  stage,
  prod,
  test;

  bool get isDev => this == Environment.dev;

  bool get isProd => this == Environment.prod;
}

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String appName;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
  });

  static const dev = AppConfig(
    appName: 'Ledger One (DEV)',
    environment: Environment.dev,
    apiBaseUrl: '',
  );

  static const prod = AppConfig(
    environment: Environment.prod,
    apiBaseUrl: 'https://api.example.com',
    appName: 'Ledger One',
  );
}
