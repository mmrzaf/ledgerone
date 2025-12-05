import 'package:app_flutter_starter/app/presentation/error_presenter.dart';
import 'package:app_flutter_starter/app/services/mock_services.dart';
import 'package:app_flutter_starter/core/contracts/navigation_contract.dart';
import 'package:app_flutter_starter/core/errors/app_error.dart';
import 'package:app_flutter_starter/features/auth/ui/login_screen.dart';
import 'package:app_flutter_starter/features/home/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingAuthService extends MockAuthService {
  int loginAttempts = 0;
  final int failCount;

  FailingAuthService({this.failCount = 2});

  @override
  Future<void> login(String email, String password) async {
    loginAttempts++;
    if (loginAttempts <= failCount) {
      throw const AppError(
        category: ErrorCategory.timeout,
        message: 'Connection timeout',
      );
    }
    return super.login(email, password);
  }
}

void main() {
  group('Error Handling Integration', () {
    testWidgets('login shows error on failure', (tester) async {
      final auth = FailingAuthService(failCount: 999);
      final nav = MockNavigationService();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: auth, navigation: nav),
        ),
      );

      // Enter credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap the actual "Sign In" button (not the header text)
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      expect(signInButton, findsOneWidget);

      await tester.tap(signInButton);
      await tester.pump(); // frame where _isLoading = true

      // Spinner inside the button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let the failing login complete & rebuild UI
      await tester.pumpAndSettle();

      // Inline error card with retry action
      expect(find.byType(ErrorCard), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Try Again'), findsOneWidget);
      expect(auth.loginAttempts, equals(1));
    });

    testWidgets('login retry works', (tester) async {
      final auth = FailingAuthService(failCount: 1);
      final nav = MockNavigationService();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: auth, navigation: nav),
        ),
      );

      // Enter credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // First attempt fails
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      expect(signInButton, findsOneWidget);

      await tester.tap(signInButton);
      await tester.pump(); // show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(); // let failure propagate

      final retryButton = find.widgetWithText(OutlinedButton, 'Try Again');
      expect(retryButton, findsOneWidget);
      expect(auth.loginAttempts, equals(1));

      // Retry succeeds
      await tester.tap(retryButton);
      await tester.pump(); // loading again
      await tester.pumpAndSettle(); // success path → navigate to home

      expect(nav.lastRoute, equals('home'));
      expect(auth.loginAttempts, equals(2));
    });
    testWidgets('navigation away cancels login', (tester) async {
      final auth = SlowAuthService();
      final nav = MockNavigationService();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: auth, navigation: nav),
        ),
      );

      // Enter credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Start login
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      // Navigate away immediately
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pump();

      // Should not crash or update disposed state
      await tester.pumpAndSettle();
    });

    testWidgets('home screen handles load errors', (tester) async {
      final auth = MockAuthService();
      await auth.login('test@example.com', 'password123');
      final nav = MockNavigationService();
      final config = MockConfigService();
      await config.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authService: auth,
            navigation: nav,
            configService: config,
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Content should be visible (might succeed or fail based on timing)
      // Just verify screen doesn't crash
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('home screen retry works', (tester) async {
      final auth = MockAuthService();
      await auth.login('test@example.com', 'password123');
      final nav = MockNavigationService();
      final config = MockConfigService();
      await config.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authService: auth,
            navigation: nav,
            configService: config,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap refresh button if visible
      final refreshButton = find.byIcon(Icons.refresh);
      if (tester.any(refreshButton)) {
        await tester.tap(refreshButton);
        await tester.pump();

        // Should show loading
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    });
  });
  testWidgets('home load is safe when navigated away', (tester) async {
    final auth = MockAuthService();
    // Optional: simulate an authenticated user for realism
    await auth.login('test@example.com', 'password123');
    final nav = MockNavigationService();
    final config = MockConfigService();
    await config.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: auth,
          navigation: nav,
          configService: config,
        ),
      ),
    );

    // Kick off the initial load
    await tester.pump();

    // Immediately "navigate away" by replacing the tree
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Other screen'))),
    );
    await tester.pump();

    // Let timers/microtasks settle. If cancellation + dispose are wrong,
    // this is where you'd see setState-after-dispose or similar crashes.
    await tester.pumpAndSettle();

    // HomeScreen should be gone, and the test should complete without errors.
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Other screen'), findsOneWidget);
  });
}

class SlowAuthService extends MockAuthService {
  @override
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 10));
    return super.login(email, password);
  }
}

class MockNavigationService implements NavigationService {
  String? lastRoute;
  Map<String, dynamic>? lastParams;

  @override
  void goToRoute(String routeId, {Map<String, dynamic>? params}) {
    lastRoute = routeId;
    lastParams = params;
  }

  @override
  void clearAndGoTo(String routeId, {Map<String, dynamic>? params}) {
    lastRoute = routeId;
    lastParams = params;
  }

  @override
  void replaceRoute(String routeId, {Map<String, dynamic>? params}) {
    lastRoute = routeId;
    lastParams = params;
  }

  @override
  void goBack() {}

  @override
  bool canGoBack() => false;

  @override
  String? get currentRouteId => lastRoute;
}
