abstract interface class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});

  Future<void> setUserId(String? id);

  Future<void> logScreenView(String screenName);
}
