import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/contracts/navigation_contract.dart';
import '../../core/contracts/guard_contract.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/contracts/auth_contract.dart';
import '../../features/onboarding/ui/onboarding_screen.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/home/ui/home_screen.dart';

class RouteMetadata {
  final String id;
  final String path;

  const RouteMetadata(this.id, this.path);
}

class NavigationServiceImpl implements NavigationService {
  final GoRouter _router;
  final Map<String, String> _routeIdToPath;

  NavigationServiceImpl(this._router, this._routeIdToPath);

  @override
  void goToRoute(String routeId, {Map<String, dynamic>? params}) {
    final path = _routeIdToPath[routeId];
    if (path == null) {
      throw ArgumentError('Unknown route ID: $routeId');
    }
    _router.go(path, extra: params);
  }

  @override
  void replaceRoute(String routeId, {Map<String, dynamic>? params}) {
    final path = _routeIdToPath[routeId];
    if (path == null) {
      throw ArgumentError('Unknown route ID: $routeId');
    }
    _router.pushReplacement(path, extra: params);
  }

  @override
  void goBack() {
    _router.pop();
  }

  @override
  bool canGoBack() {
    return _router.canPop();
  }

  @override
  String? get currentRouteId {
    final location = _router.routerDelegate.currentConfiguration.uri.path;
    for (final entry in _routeIdToPath.entries) {
      if (entry.value == location) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  void clearAndGoTo(String routeId, {Map<String, dynamic>? params}) {
    final path = _routeIdToPath[routeId];
    if (path == null) {
      throw ArgumentError('Unknown route ID: $routeId');
    }

    while (_router.canPop()) {
      _router.pop();
    }
    _router.go(path, extra: params);
  }
}

class RouterFactory {
  static RouterFactoryResult create({
    required String initialRoute,
    required List<NavigationGuard> guards,
    required StorageService storage,
    required AuthService auth,
  }) {
    final routeIdToPath = {
      'onboarding': '/onboarding',
      'login': '/login',
      'home': '/home',
    };

    final sortedGuards = List<NavigationGuard>.from(guards)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final router = GoRouter(
      initialLocation: routeIdToPath[initialRoute] ?? '/onboarding',
      redirect: (context, state) async {
        final targetPath = state.uri.path;

        String? targetRouteId;
        for (final entry in routeIdToPath.entries) {
          if (entry.value == targetPath) {
            targetRouteId = entry.key;
            break;
          }
        }

        if (targetRouteId == null) return null;

        final currentPath = state.matchedLocation;
        String? currentRouteId;
        for (final entry in routeIdToPath.entries) {
          if (entry.value == currentPath) {
            currentRouteId = entry.key;
            break;
          }
        }

        for (final guard in sortedGuards) {
          final result = await guard.evaluate(targetRouteId, currentRouteId);

          if (result is GuardRedirect) {
            final redirectPath = routeIdToPath[result.targetRouteId];
            if (redirectPath != null && redirectPath != targetPath) {
              return redirectPath;
            }
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) {
            final navService = NavigationServiceImpl(router, routeIdToPath);
            return OnboardingScreen(
              storage: storage,
              navigation: navService,
            );
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final navService = NavigationServiceImpl(router, routeIdToPath);
            return LoginScreen(
              authService: auth,
              navigation: navService,
            );
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            final navService = NavigationServiceImpl(router, routeIdToPath);
            return HomeScreen(
              authService: auth,
              navigation: navService,
            );
          },
        ),
      ],
    );

    final navigationService = NavigationServiceImpl(router, routeIdToPath);

    return RouterFactoryResult(
      router: router,
      navigationService: navigationService,
    );
  }
}

class RouterFactoryResult {
  final GoRouter router;
  final NavigationService navigationService;

  RouterFactoryResult({
    required this.router,
    required this.navigationService,
  });
}
