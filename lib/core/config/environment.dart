enum Environment {
  dev,
  stage,
  prod;

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
    environment: Environment.dev,
    apiBaseUrl: 'https://dev-api.example.com',
    appName: 'Flutter Starter (Dev)',
  );

  static const prod = AppConfig(
    environment: Environment.prod,
    apiBaseUrl: 'https://api.example.com',
    appName: 'Flutter Starter',
  );
}
