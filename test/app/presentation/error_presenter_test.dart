import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerone/app/di.dart';
import 'package:ledgerone/app/presentation/error_presenter.dart';
import 'package:ledgerone/app/services/localization_service_impl.dart';
import 'package:ledgerone/core/contracts/analytics_contract.dart';
import 'package:ledgerone/core/errors/app_error.dart';
import 'package:ledgerone/core/i18n/string_keys.dart';
import 'package:ledgerone/core/observability/analytics_allowlist.dart';

import '../../helpers/mock_services.dart';

void main() {
  group('ErrorPresenter.showError', () {
    late MockAnalyticsService analytics;
    late LocalizationServiceImpl localization;
    late ServiceLocator locator;

    setUp(() async {
      locator = ServiceLocator();
      locator.clear();

      analytics = MockAnalyticsService();
      locator.register<AnalyticsService>(analytics);

      final storage = MockStorageService();
      localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();
    });

    tearDown(() {
      locator.clear();
    });

    testWidgets(
      'logs analytics and shows banner SnackBar for banner presentation',
      (tester) async {
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedContext = context;
                return const Scaffold(body: SizedBox.shrink());
              },
            ),
          ),
        );

        const error = AppError(
          category: ErrorCategory.networkOffline,
          message: '',
        );

        ErrorPresenter.showError(capturedContext, error, screen: 'home');

        await tester.pump(); // show SnackBar

        // SnackBar visible with correct message
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text(localization.get(L10nKeys.errorNetworkOffline)),
          findsOneWidget,
        );

        // Analytics event logged
        expect(analytics.events.length, 1);
        final event = analytics.events.single;
        expect(event['name'], AnalyticsAllowlist.errorShown.name);
        expect(event['parameters']['error_category'], 'networkOffline');
        expect(event['parameters']['presentation'], 'banner');
        expect(event['parameters']['screen'], 'home');
      },
    );

    testWidgets(
      'does nothing for inline presentation (no SnackBar, no analytics)',
      (tester) async {
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedContext = context;
                return const Scaffold(body: SizedBox.shrink());
              },
            ),
          ),
        );

        const error = AppError(category: ErrorCategory.parseError, message: '');

        ErrorPresenter.showError(capturedContext, error, screen: 'home');

        await tester.pump();

        expect(find.byType(SnackBar), findsNothing);
        expect(analytics.events, isEmpty);
      },
    );
  });
}
