import '../../core/contracts/config_provider.dart';

class SimulatedRemoteConfig implements RemoteConfigProvider {
  @override
  Future<Map<String, dynamic>> fetchConfig() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return {
      'home.promo_banner.enabled': true,
      'ui.theme_variant': 'winter_holiday',
      'retry.max_attempts': 5,
    };
  }
}
