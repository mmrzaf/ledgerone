import 'package:go_router/go_router.dart';
import 'package:ledgerone/app/di.dart';
import 'package:ledgerone/core/contracts/analytics_contract.dart';
import 'package:ledgerone/core/contracts/i18n_contract.dart';
import 'package:ledgerone/core/contracts/logging_contract.dart';
import 'package:ledgerone/features/ledger/data/repositories_interfaces.dart';
import 'package:ledgerone/features/ledger/domain/services.dart';
import 'package:ledgerone/features/ledger/ui/accounts_screen.dart';
import 'package:ledgerone/features/ledger/ui/assets_screen.dart';
import 'package:ledgerone/features/ledger/ui/crypto_screen.dart';
import 'package:ledgerone/features/ledger/ui/dashboard_screen.dart';
import 'package:ledgerone/features/ledger/ui/money_screen.dart';
import 'package:ledgerone/features/ledger/ui/transaction_editor_screen.dart';
import 'package:ledgerone/features/settings/ui/logs_screen.dart';
import 'package:ledgerone/features/settings/ui/settings_screen.dart';

import '../../core/contracts/guard_contract.dart';
import '../../core/contracts/navigation_contract.dart';
import '../../core/contracts/storage_contract.dart';
import '../../features/onboarding/ui/onboarding_screen.dart';

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

    String fullPath = path;
    if (params != null && params.isNotEmpty) {
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      fullPath = '$path?$query';
    }

    _router.go(fullPath);
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
    if (_router.canPop()) {
      _router.pop();
    } else {
      final fallbackPath = _routeIdToPath['dashboard'] ?? '/dashboard';
      _router.go(fallbackPath);
    }
  }

  @override
  bool canGoBack() {
    return _router.canPop();
  }

  @override
  String? get currentRouteId {
    final location = _router.routerDelegate.currentConfiguration.uri.toString();
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

    _router.go(path, extra: params);
  }
}

class RouterFactory {
  static RouterFactoryResult create({
    required String initialRoute,
    required List<NavigationGuard> guards,
    required ServiceLocator locator,
    required LocalizationService localization,
  }) {
    final routeIdToPath = {
      'onboarding': '/onboarding',
      'dashboard': '/dashboard',
      'crypto': '/crypto',
      'money': '/money',
      'transaction_editor': '/transaction',
      'assets': '/assets',
      'accounts': '/accounts',
      'settings': '/settings',
      'logs': '/logs',
    };
    final sortedGuards = List<NavigationGuard>.from(guards)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    late final NavigationServiceImpl navigationService;

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
            return OnboardingScreen(
              storage: locator.get<StorageService>(),
              navigation: navigationService,
            );
          },
        ),

        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            return DashboardScreen(
              navigation: navigationService,
              portfolioService: locator.get<PortfolioValuationService>(),
              priceUpdateService: locator.get<PriceUpdateService>(),
              balanceService: locator.get<BalanceService>(),
              analytics: locator.get<AnalyticsService>(),
              valuationService: locator.get<BalanceValuationService>(),
            );
          },
        ),

        GoRoute(
          path: '/crypto',
          builder: (context, state) {
            return CryptoScreen(
              navigation: navigationService,
              balanceService: locator.get<BalanceService>(),
              analytics: locator.get<AnalyticsService>(),
              valuationService: locator.get<BalanceValuationService>(),
            );
          },
        ),
        GoRoute(
          path: '/money',
          name: 'money',
          builder: (context, state) => MoneyScreen(
            navigation: navigationService,
            summaryService: locator.get<MoneySummaryService>(),
            analytics: locator.get<AnalyticsService>(),
            valuationService: locator.get<BalanceValuationService>(),
          ),
        ),
        GoRoute(
          path: '/transaction',
          name: 'transaction_editor',
          builder: (context, state) {
            final transactionId = state.uri.queryParameters['id'];
            return TransactionEditorScreen(
              navigation: navigationService,
              transactionService: locator.get<TransactionService>(),
              assetRepo: locator.get<AssetRepository>(),
              accountRepo: locator.get<AccountRepository>(),
              categoryRepo: locator.get<CategoryRepository>(),
              analytics: locator.get<AnalyticsService>(),
              transactionId: transactionId,
            );
          },
        ),
        GoRoute(
          path: '/assets',
          builder: (context, state) {
            return AssetsScreen(
              navigation: navigationService,
              assetRepo: locator.get<AssetRepository>(),
              analytics: locator.get<AnalyticsService>(),
            );
          },
        ),
        GoRoute(
          path: '/accounts',
          builder: (context, state) {
            return AccountsScreen(
              navigation: navigationService,
              accountRepo: locator.get<AccountRepository>(),
              analytics: locator.get<AnalyticsService>(),
            );
          },
        ),

        GoRoute(
          path: '/settings',
          builder: (context, state) {
            return SettingsScreen(
              navigation: navigationService,
              analytics: locator.get<AnalyticsService>(),
            );
          },
        ),
        GoRoute(
          path: '/logs',
          builder: (context, state) {
            return LogsScreen(
              navigation: navigationService,
              loggingService: locator.get<LoggingService>(),
            );
          },
        ),
      ],
    );

    navigationService = NavigationServiceImpl(router, routeIdToPath);

    return RouterFactoryResult(
      router: router,
      navigationService: navigationService,
    );
  }
}

class RouterFactoryResult {
  final GoRouter router;
  final NavigationService navigationService;

  RouterFactoryResult({required this.router, required this.navigationService});
}
