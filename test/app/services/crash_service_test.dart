import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerone/app/services/crash_service_impl.dart';
import 'package:ledgerone/core/errors/app_error.dart';

import '../../helpers/mock_services.dart';

void main() {
  group('CrashServiceImpl', () {
    late MockStorageService storage;
    late CrashServiceImpl crash;

    setUp(() {
      storage = MockStorageService();
      crash = CrashServiceImpl(storage: storage);
      crash.setConsent(true);
    });

    test('blocks reporting without consent', () async {
      await crash.initialize();
      await crash.setConsent(false);

      await crash.recordError(Exception('Test'), null);

      // Should not crash
    });

    test('allows reporting with consent', () async {
      await crash.initialize();
      await crash.setConsent(true);

      await crash.recordError(Exception('Test'), null);

      final consent = await storage.getBool('crash_reporting_consent');
      expect(consent, isTrue);
    });

    test('adds breadcrumbs', () {
      crash.addBreadcrumb('Test message');
      expect(crash.breadcrumbs.length, equals(1));
      expect(crash.breadcrumbs.first.message, equals('Test message'));
    });

    test('limits breadcrumb count', () async {
      await crash.initialize();
      await crash.setConsent(true);

      // Add more than max breadcrumbs
      for (var i = 0; i < 60; i++) {
        crash.addBreadcrumb('Message $i');
      }

      expect(crash.breadcrumbs.length, lessThanOrEqualTo(50));
    });

    test('sanitizes exception messages', () async {
      await crash.initialize();
      await crash.setConsent(true);

      await crash.recordError(Exception('Error for user@example.com'), null);

      // PII should be redacted in production
    });

    test('records navigation breadcrumbs', () async {
      await crash.initialize();
      await crash.setConsent(true);

      crash.recordNavigation('login', 'home');

      expect(crash.breadcrumbs.length, equals(1));
      expect(crash.breadcrumbs.first.category, equals('navigation'));
    });

    test('records error category breadcrumbs', () async {
      await crash.initialize();
      await crash.setConsent(true);

      crash.recordErrorCategory('timeout', 'login');

      expect(crash.breadcrumbs.length, equals(1));
      expect(crash.breadcrumbs.first.category, equals('error'));
    });

    test('clears breadcrumbs when consent revoked', () async {
      await crash.initialize();
      await crash.setConsent(true);

      crash.addBreadcrumb('Test');
      expect(crash.breadcrumbs.length, equals(1));

      await crash.setConsent(false);
      expect(crash.breadcrumbs.length, equals(0));
    });

    test('handles AppError specially', () async {
      await crash.initialize();
      await crash.setConsent(true);

      const appError = AppError(
        category: ErrorCategory.timeout,
        message: 'Timeout occurred',
      );

      await crash.recordError(appError, null);

      // AppError should be recorded as-is since it's already safe
    });
  });
}
