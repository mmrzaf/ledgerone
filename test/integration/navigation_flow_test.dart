import 'package:app_flutter_starter/app/app.dart';
import 'package:app_flutter_starter/app/di.dart';
import 'package:app_flutter_starter/core/config/environment.dart';
import 'package:app_flutter_starter/core/contracts/auth_contract.dart';
import 'package:app_flutter_starter/core/contracts/storage_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_remote_config_provider.dart';

void main() {
  group('Navigation Flow Integration Tests', () {
    testWidgets('Fresh install: onboarding -> complete -> login (redirect)', (
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

      await tester.pumpWidget(App(router: routerResult.router));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Flutter Starter'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsAtLeastNWidgets(1));
      expect(find.text('Welcome!'), findsNothing);
    });

    testWidgets('Onboarding skip -> login', (tester) async {
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

      await tester.pumpWidget(App(router: routerResult.router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsAtLeastNWidgets(1));
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('Login flow: invalid -> valid credentials', (tester) async {
      final diSetup = await setupDependencies(
        AppConfig.dev,
        remoteConfigProvider: TestRemoteConfigProvider(),
      );
      final storage = diSetup.locator.get<StorageService>();
      await storage.setBool('onboarding_seen', true);

      final launchState = await diSetup.launchStateResolver.resolve();
      final initialRoute = launchState.determineInitialRoute();
      final routerResult = createRouter(
        initialRoute: initialRoute,
        locator: diSetup.locator,
      );

      await tester.pumpWidget(App(router: routerResult.router));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsAtLeastNWidgets(1));

      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).last, 'short');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Sign In'),
      );
      expect(button.onPressed, isNull);

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.pump();

      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Sign In'),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome!'), findsOneWidget);
    });

    testWidgets('Authenticated user redirects to home from login', (
      tester,
    ) async {
      final diSetup = await setupDependencies(
        AppConfig.dev,
        remoteConfigProvider: TestRemoteConfigProvider(),
      );
      final storage = diSetup.locator.get<StorageService>();
      final auth = diSetup.locator.get<AuthService>();

      await storage.setBool('onboarding_seen', true);
      await auth.login('user@test.com', 'password123');

      final launchState = await diSetup.launchStateResolver.resolve();
      final initialRoute = launchState.determineInitialRoute();

      expect(initialRoute, 'home');

      final routerResult = createRouter(
        initialRoute: initialRoute,
        locator: diSetup.locator,
      );

      await tester.pumpWidget(App(router: routerResult.router));
      await tester.pumpAndSettle();

      expect(find.text('Welcome!'), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('Logout navigates to login', (tester) async {
      final diSetup = await setupDependencies(
        AppConfig.dev,
        remoteConfigProvider: TestRemoteConfigProvider(),
      );
      final storage = diSetup.locator.get<StorageService>();
      final auth = diSetup.locator.get<AuthService>();

      await storage.setBool('onboarding_seen', true);
      await auth.login('user@test.com', 'password123');

      final launchState = await diSetup.launchStateResolver.resolve();
      final initialRoute = launchState.determineInitialRoute();
      final routerResult = createRouter(
        initialRoute: initialRoute,
        locator: diSetup.locator,
      );

      await tester.pumpWidget(App(router: routerResult.router));
      await tester.pumpAndSettle();

      expect(find.text('Welcome!'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsAtLeastNWidgets(1));
      expect(find.text('Welcome!'), findsNothing);
    });

    testWidgets('Guard evaluation order is correct', (tester) async {
      final diSetup = await setupDependencies(
        AppConfig.dev,
        remoteConfigProvider: TestRemoteConfigProvider(),
      );
      final auth = diSetup.locator.get<AuthService>();
      await auth.login('test@test.com', 'password123');

      final launchState = await diSetup.launchStateResolver.resolve();
      final initialRoute = launchState.determineInitialRoute();

      expect(initialRoute, 'onboarding');
    });
  });
}
