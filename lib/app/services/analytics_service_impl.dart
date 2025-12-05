import 'package:flutter/foundation.dart';
import '../../core/contracts/analytics_contract.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/observability/analytics_allowlist.dart';

/// Analytics service with consent management and allow-listing
class AnalyticsServiceImpl implements AnalyticsService {
  final StorageService _storage;
  final AnalyticsService? _vendor; // Optional vendor implementation

  static const String _consentKey = 'analytics_consent';
  bool? _consentGranted;
  String? _userId;

  AnalyticsServiceImpl({
    required StorageService storage,
    AnalyticsService? vendor,
  }) : _storage = storage,
       _vendor = vendor;

  /// Initialize and load consent status
  Future<void> initialize() async {
    _consentGranted = await _storage.getBool(_consentKey);
    debugPrint('Analytics: Initialized. Consent: $_consentGranted');
  }

  /// Set analytics consent
  Future<void> setConsent(bool granted) async {
    _consentGranted = granted;
    await _storage.setBool(_consentKey, granted);
    debugPrint('Analytics: Consent ${granted ? 'granted' : 'revoked'}');

    if (!granted) {
      // Clear user ID when consent revoked
      await setUserId(null);
    }
  }

  /// Check if consent is granted
  bool get hasConsent => _consentGranted ?? false;

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    // Check consent
    if (!hasConsent) {
      debugPrint('Analytics: Event blocked (no consent): $name');
      return;
    }

    // Validate against allow-list
    if (!AnalyticsAllowlist.isAllowed(name)) {
      debugPrint('Analytics: Event rejected (not allowed): $name');
      assert(false, 'Event "$name" is not in the allow-list');
      return;
    }

    // Validate parameters
    if (!AnalyticsAllowlist.validate(name, parameters)) {
      debugPrint('Analytics: Event rejected (invalid params): $name');
      assert(false, 'Event "$name" has invalid parameters: $parameters');
      return;
    }

    // Sanitize parameters (remove any PII that might have slipped in)
    final sanitized = _sanitizeParameters(parameters);
    debugPrint('Analytics: $name $sanitized');

    // Forward to vendor if available
    await _vendor?.logEvent(name, parameters: sanitized);
  }

  @override
  Future<void> setUserId(String? id) async {
    if (!hasConsent) {
      debugPrint('Analytics: setUserId blocked (no consent)');
      return;
    }

    // Hash user ID for privacy
    _userId = id != null ? _hashUserId(id) : null;

    debugPrint('Analytics: User ID set (hashed): $_userId');
    await _vendor?.setUserId(_userId);
  }

  @override
  Future<void> logScreenView(String screenName) async {
    // Screen views are considered navigation telemetry
    // They're allowed even without explicit consent in some jurisdictions
    // but we respect consent here for maximum privacy
    if (!hasConsent) {
      return;
    }

    debugPrint('Analytics: Screen view: $screenName');
    await _vendor?.logScreenView(screenName);
  }

  /// Sanitize parameters to remove potential PII
  Map<String, dynamic>? _sanitizeParameters(Map<String, dynamic>? params) {
    if (params == null) return null;

    final sanitized = <String, dynamic>{};
    final piiKeys = ['email', 'name', 'phone', 'address', 'password'];

    for (final entry in params.entries) {
      final key = entry.key.toLowerCase();

      // Block known PII fields
      if (piiKeys.any((pii) => key.contains(pii))) {
        debugPrint('Analytics: Blocked PII parameter: ${entry.key}');
        continue;
      }

      sanitized[entry.key] = entry.value;
    }

    return sanitized;
  }

  /// Hash user ID for privacy
  String _hashUserId(String id) {
    // In production, use a proper hashing algorithm
    // For now, just take first few characters as a demo
    return id.length > 8 ? id.substring(0, 8) : id;
  }
}
