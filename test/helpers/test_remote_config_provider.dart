import 'package:ledgerone/core/contracts/config_provider.dart';

class TestRemoteConfigProvider implements RemoteConfigProvider {
  final Map<String, dynamic> config;

  TestRemoteConfigProvider({Map<String, dynamic>? config})
    : config =
          config ??
          {
            'home.promo_banner.enabled': true,
            'ui.theme_variant': 'winter_holiday',
            'retry.max_attempts': 5,
          };

  @override
  Future<Map<String, dynamic>> fetchConfig() async {
    return config;
  }
}
