import 'package:flutter/material.dart';
import 'core/config/environment.dart';
import 'app/app.dart';
import 'app/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig.dev;

  // Phase 1: Setup dependencies
  final diSetup = await setupDependencies(config);

  // Phase 2: Resolve launch state
  final launchState = await diSetup.launchStateResolver.resolve();
  final initialRoute = launchState.determineInitialRoute();

  debugPrint('Launch state: $launchState');
  debugPrint('Initial route: $initialRoute');

  // Phase 3: Create router with determined initial route
  final routerResult = createRouter(
    initialRoute: initialRoute,
    locator: diSetup.locator,
  );

  // Phase 4: Run app
  runApp(App(router: routerResult.router));
}
