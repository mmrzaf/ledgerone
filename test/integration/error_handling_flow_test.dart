import 'package:app_flutter_starter/app/di.dart';
import 'package:app_flutter_starter/app/presentation/error_presenter.dart';
import 'package:app_flutter_starter/app/services/cache_service_impl.dart';
import 'package:app_flutter_starter/app/services/lifecycle_service_impl.dart';
import 'package:app_flutter_starter/app/services/localization_service_impl.dart';
import 'package:app_flutter_starter/app/services/network_service_impl.dart';
import 'package:app_flutter_starter/core/contracts/network_contract.dart';
import 'package:app_flutter_starter/core/errors/app_error.dart';
import 'package:app_flutter_starter/core/errors/result.dart';
import 'package:app_flutter_starter/core/i18n/string_keys.dart';
import 'package:app_flutter_starter/features/home/domain/home_models.dart';
import 'package:app_flutter_starter/features/home/domain/home_repository.dart';
import 'package:app_flutter_starter/features/home/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_services.dart';

class SequenceHomeRepository implements HomeRepository {
  final List<Result<HomeData>> _responses;
  int callCount = 0;

  SequenceHomeRepository(this._responses);

  @override
  Future<Result<HomeData>> load({bool forceRefresh = false}) async {
    final index = callCount < _responses.length
        ? callCount
        : _responses.length - 1;
    final result = _responses[index];
    callCount++;
    return result;
  }

  @override
  Stream<HomeData> watch() => const Stream.empty();
}

void main() {
  group('Error handling integration – HomeScreen', () {
    late LocalizationServiceImpl localization;

    setUp(() async {
      ServiceLocator().clear();
      final storage = MockStorageService();
      localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();
    });

    tearDown(() {
      ServiceLocator().clear();
    });

    Future<void> pumpHome({
      required WidgetTester tester,
      required HomeRepository repository,
      NetworkStatus initialStatus = NetworkStatus.online,
    }) async {
      final nav = MockNavigationService();
      final config = MockConfigService();
      await config.initialize();

      final cacheStorage = MockStorageService();
      final cache = CacheServiceImpl(storage: cacheStorage);

      final network = SimulatedNetworkService(); // Default online
      await network.initialize();
      if (initialStatus != NetworkStatus.online) {
        network.setStatus(initialStatus);
      }

      final lifecycle = AppLifecycleServiceImpl();
      lifecycle.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            navigation: nav,
            configService: config,
            networkService: network,
            cacheService: cache,
            lifecycleService: lifecycle,
            homeRepository: repository,
          ),
        ),
      );
    }

    testWidgets('shows inline error when load fails and allows manual retry', (
      tester,
    ) async {
      final repo = SequenceHomeRepository([
        // First call: fail with timeout → inline ErrorCard
        const Failure<HomeData>(
          AppError(
            category: ErrorCategory.timeout,
            message: 'Simulated failure',
          ),
        ),
        // Second call: success after retry
        Success<HomeData>(
          HomeData(
            message: 'Loaded after retry',
            timestamp: DateTime(2025, 1, 1),
          ),
        ),
      ]);

      await pumpHome(tester: tester, repository: repo);

      // Let initial load complete → should land in error state
      await tester.pumpAndSettle();

      // 1) Error is shown inline
      expect(find.byType(ErrorCard), findsOneWidget);
      expect(find.text('Simulated failure'), findsOneWidget);

      // 2) Retry button is visible (use localization, not hardcoded string)
      final retryText = localization.get(L10nKeys.retry);
      final retryFinder = find.text(retryText);
      expect(retryFinder, findsOneWidget);

      // Tap retry
      await tester.tap(retryFinder);
      await tester.pumpAndSettle();

      // 3) After retry, error is gone and success content is shown
      expect(find.byType(ErrorCard), findsNothing);
      expect(find.text('Loaded after retry'), findsOneWidget);

      // Both repository calls happened
      expect(repo.callCount, 2);
    });

    testWidgets('does not crash when disposed before load completes', (
      tester,
    ) async {
      final slowRepo = _SlowFailingHomeRepository();

      await pumpHome(tester: tester, repository: slowRepo);

      // Immediately dispose the HomeScreen by swapping out the tree
      await tester.pumpWidget(const SizedBox.shrink());

      // Let the slow load finish; if HomeScreen calls setState after dispose,
      // flutter_test will throw and the test will fail.
      await tester.pump(const Duration(milliseconds: 200));

      // If we get here, no "setState() called after dispose()" happened.
      expect(slowRepo.callCount, 1);
    });
  });
}

class _SlowFailingHomeRepository implements HomeRepository {
  int callCount = 0;

  @override
  Future<Result<HomeData>> load({bool forceRefresh = false}) async {
    callCount++;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const Failure<HomeData>(
      AppError(category: ErrorCategory.timeout, message: 'Slow failure'),
    );
  }

  @override
  Stream<HomeData> watch() => const Stream.empty();
}
