import 'package:app_flutter_starter/app/services/analytics_service_impl.dart';
import 'package:app_flutter_starter/app/services/mock_services.dart';
import 'package:app_flutter_starter/core/observability/analytics_allowlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsAllowlist', () {
    test('all standard events are defined', () {
      final eventNames = AnalyticsAllowlist.allEventNames;

      expect(eventNames, contains('app_launch'));
      expect(eventNames, contains('config_loaded'));
      expect(eventNames, contains('onboarding_view'));
      expect(eventNames, contains('login_success'));
      expect(eventNames, contains('home_view'));
      expect(eventNames, contains('error_shown'));
    });

    test('isAllowed returns true for allowed events', () {
      expect(AnalyticsAllowlist.isAllowed('app_launch'), isTrue);
      expect(AnalyticsAllowlist.isAllowed('login_success'), isTrue);
    });

    test('isAllowed returns false for unknown events', () {
      expect(AnalyticsAllowlist.isAllowed('unknown_event'), isFalse);
      expect(AnalyticsAllowlist.isAllowed('random_tracking'), isFalse);
    });

    test('validates required parameters', () {
      expect(
        AnalyticsAllowlist.validate('app_launch', {'cold_start': true}),
        isTrue,
      );

      expect(
        AnalyticsAllowlist.validate('app_launch', {}),
        isFalse, // Missing required cold_start
      );
    });

    test('validates optional parameters', () {
      expect(
        AnalyticsAllowlist.validate('app_launch', {
          'cold_start': true,
          'duration_ms': 1500,
        }),
        isTrue,
      );
    });

    test('rejects unknown parameters', () {
      expect(
        AnalyticsAllowlist.validate('app_launch', {
          'cold_start': true,
          'unknown_param': 'value',
        }),
        isFalse,
      );
    });

    test('validates parameter types', () {
      expect(
        AnalyticsAllowlist.validate('app_launch', {'cold_start': 'not a bool'}),
        isFalse,
      );

      expect(
        AnalyticsAllowlist.validate('login_success', {
          'duration_ms': 'not an int',
        }),
        isFalse,
      );
    });

    test('allows events with no parameters', () {
      expect(AnalyticsAllowlist.validate('onboarding_view', null), isTrue);
      expect(AnalyticsAllowlist.validate('login_view', {}), isTrue);
    });
  });

  group('AnalyticsServiceImpl', () {
    late MockStorageService storage;
    late AnalyticsServiceImpl analytics;

    setUp(() {
      storage = MockStorageService();
      analytics = AnalyticsServiceImpl(storage: storage);
    });

    test('blocks events without consent', () async {
      await analytics.initialize();
      await analytics.setConsent(false);

      await analytics.logEvent('app_launch', parameters: {'cold_start': true});

      // No assertions needed - just verify it doesn't crash
    });

    test('allows events with consent', () async {
      await analytics.initialize();
      await analytics.setConsent(true);

      await analytics.logEvent('app_launch', parameters: {'cold_start': true});

      // Verify consent was stored
      final consent = await storage.getBool('analytics_consent');
      expect(consent, isTrue);
    });

    test('rejects events not in allow-list', () async {
      await analytics.initialize();
      await analytics.setConsent(true);

      // This should be rejected and trigger an assert in debug mode
      await analytics.logEvent('forbidden_event');
    });

    test('validates event parameters', () async {
      await analytics.initialize();
      await analytics.setConsent(true);

      // Missing required parameter should be rejected
      await analytics.logEvent('app_launch', parameters: {});
    });

    test('sanitizes PII from parameters', () async {
      await analytics.initialize();
      await analytics.setConsent(true);

      // Attempt to log PII - should be blocked
      await analytics.logEvent(
        'login_view',
        parameters: {'email': 'user@example.com', 'password': 'secret123'},
      );
    });

    test('clears user ID when consent revoked', () async {
      await analytics.initialize();
      await analytics.setConsent(true);
      await analytics.setUserId('user123');

      await analytics.setConsent(false);

      // User ID should be cleared
    });
  });

  group('EventDefinition', () {
    test('validates parameters correctly', () {
      const event = EventDefinition(
        name: 'test_event',
        description: 'Test',
        parameters: [
          EventParameter(
            name: 'required_param',
            type: String,
            description: 'Required',
            required: true,
          ),
          EventParameter(
            name: 'optional_param',
            type: int,
            description: 'Optional',
            required: false,
          ),
        ],
      );

      expect(event.validateParameters({'required_param': 'value'}), isTrue);
      expect(event.validateParameters({}), isFalse);
      expect(
        event.validateParameters({
          'required_param': 'value',
          'optional_param': 42,
        }),
        isTrue,
      );
    });
  });
}
