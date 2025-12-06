import 'package:go_router/go_router.dart';
import 'package:ledgerone/app/di.dart';
import 'package:ledgerone/core/contracts/i18n_contract.dart';
import 'package:ledgerone/features/ledger/data/database.dart';
import 'package:ledgerone/features/ledger/services/price_update_service.dart';
import 'package:ledgerone/features/ledger/ui/crypto_screen.dart';
import 'package:ledgerone/features/ledger/ui/dashboard_screen.dart';
import 'package:ledgerone/features/ledger/ui/money_screen.dart';
import 'package:ledgerone/features/ledger/ui/settings_screen.dart';
import 'package:ledgerone/features/ledger/ui/transaction_editor_screen.dart';

import '../../core/contracts/cache_contract.dart';
import '../../core/contracts/config_contract.dart';
import '../../core/contracts/guard_contract.dart';
import '../../core/contracts/lifecycle_contract.dart';
import '../../core/contracts/navigation_contract.dart';
import '../../core/contracts/network_contract.dart';
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
    required StorageService storage,
    required ConfigService config,
    required NetworkService network,
    required CacheService cache,
    required AppLifecycleService lifecycle,
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
              storage: storage,
              navigation: navigationService,
            );
          },
        ),

        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            final balanceService = ServiceLocator().get<BalanceService>();
            final priceUpdateService = ServiceLocator()
                .get<PriceUpdateService>();

            return DashboardScreen(
              navigation: navigationService,
              balanceService: balanceService,
              priceUpdateService: priceUpdateService,
            );
          },
        ),

        GoRoute(
          path: '/crypto',
          builder: (context, state) {
            final balanceService = ServiceLocator().get<BalanceService>();
            final assetRepo = ServiceLocator().get<AssetRepository>();

            return CryptoScreen(
              navigation: navigationService,
              balanceService: balanceService,
              assetRepo: assetRepo,
            );
          },
        ),

        GoRoute(
          path: '/money',
          builder: (context, state) {
            final balanceService = ServiceLocator().get<BalanceService>();

            return MoneyScreen(
              navigation: navigationService,
              balanceService: balanceService,
            );
          },
        ),
        GoRoute(
          path: '/transaction',
          builder: (context, state) {
            final db = ServiceLocator().get<LedgerDatabase>();
            final assetRepo = ServiceLocator().get<AssetRepository>();
            final accountRepo = ServiceLocator().get<AccountRepository>();
            final categoryRepo = ServiceLocator().get<CategoryRepository>();
            final txRepo = ServiceLocator().get<TransactionRepository>();

            return TransactionEditorScreen(
              navigation: navigationService,
              database: db,
              assetRepo: assetRepo,
              accountRepo: accountRepo,
              categoryRepo: categoryRepo,
              transactionRepo: txRepo,
            );
          },
        ),

        GoRoute(
          path: '/settings',
          builder: (context, state) {
            return SettingsScreen(navigation: navigationService);
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
