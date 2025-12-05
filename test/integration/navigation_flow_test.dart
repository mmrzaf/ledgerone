import 'package:app_flutter_starter/app/app.dart';
import 'package:app_flutter_starter/app/di.dart';
import 'package:app_flutter_starter/core/config/environment.dart';
import 'package:app_flutter_starter/core/contracts/i18n_contract.dart';
import 'package:app_flutter_starter/core/contracts/theme_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_remote_config_provider.dart';

void main() {
  group('Navigation Flow Integration Tests', () {
    testWidgets('Fresh install: onboarding -> complete -> home', (
      tester,
    ) async {
      final diSetup = await setupDependencies(
        AppConfig.dev,
        remoteConfigProvider: TestRemoteConfigProvider(),
      );
      final launchState = await diSetup.launchStateResolver.resolve();
      final initialRoute = launchState.determineInitialRoute();
      final routerResult = createRouter(
        initialRoute: initialRoute,
        locator: diSetup.locator,
      );
      final localization = diSetup.locator.get<LocalizationService>();
      final themeService = diSetup.locator.get<ThemeService>();

      await tester.pumpWidget(
        App(
          router: routerResult.router,
          localization: localization,
          themeService: themeService,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome to Flutter Starter'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back!'), findsAtLeastNWidgets(1));
    });

    testWidgets('Onboarding skip -> home', (tester) async {
      final diSetup = await setupDependencies(
        AppConfig.dev,
        remoteConfigProvider: TestRemoteConfigProvider(),
      );
      final launchState = await diSetup.launchStateResolver.resolve();
      final initialRoute = launchState.determineInitialRoute();
      final routerResult = createRouter(
        initialRoute: initialRoute,
        locator: diSetup.locator,
      );
      final localization = diSetup.locator.get<LocalizationService>();
      final themeService = diSetup.locator.get<ThemeService>();

      await tester.pumpWidget(
        App(
          router: routerResult.router,
          localization: localization,
          themeService: themeService,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back!'), findsAtLeastNWidgets(1));
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });
}
