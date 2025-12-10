import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerone/app/di.dart';
import 'package:ledgerone/app/presentation/error_presenter.dart';
import 'package:ledgerone/app/services/localization_service_impl.dart';
import 'package:ledgerone/core/contracts/analytics_contract.dart';
import 'package:ledgerone/core/contracts/storage_contract.dart';
import 'package:ledgerone/core/errors/app_error.dart';
import 'package:ledgerone/core/i18n/string_keys.dart';
import 'package:ledgerone/features/ledger/domain/models.dart';
import 'package:ledgerone/features/ledger/domain/services.dart';
import 'package:ledgerone/features/ledger/ui/crypto_screen.dart';

import '../helpers/mock_services.dart';

/// BalanceService that returns a sequence of results for getAllBalances().
/// We only implement what CryptoScreen actually uses.
class SequenceBalanceService implements BalanceService {
  final List<Future<List<TotalAssetBalance>> Function()> _responses;
  int callCount = 0;

  SequenceBalanceService(this._responses);

  @override
  Future<List<TotalAssetBalance>> getAllBalances({bool includeZero = false}) {
    final index = callCount < _responses.length
        ? callCount
        : _responses.length - 1;
    callCount++;
    return _responses[index]();
  }

  // Not used by CryptoScreen in these tests – keep them simple.
  @override
  Future<double> getBalance(String assetId, String accountId) =>
      Future.error(UnimplementedError());

  @override
  Future<double> getTotalBalance(String assetId) =>
      Future.error(UnimplementedError());

  @override
  Future<List<AssetBalance>> getAccountBalances(String accountId) =>
      Future.error(UnimplementedError());
}

/// Slow BalanceService that fails after a delay – used to prove we
/// don't call setState after dispose.
class SlowFailingBalanceService implements BalanceService {
  int callCount = 0;

  @override
  Future<List<TotalAssetBalance>> getAllBalances({
    bool includeZero = false,
  }) async {
    callCount++;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    throw const AppError(
      category: ErrorCategory.timeout,
      message: 'Slow failure',
    );
  }

  @override
  Future<double> getBalance(String assetId, String accountId) =>
      Future.error(UnimplementedError());

  @override
  Future<double> getTotalBalance(String assetId) =>
      Future.error(UnimplementedError());

  @override
  Future<List<AssetBalance>> getAccountBalances(String accountId) =>
      Future.error(UnimplementedError());
}

void main() {
  group('Error handling integration – CryptoScreen', () {
    late LocalizationServiceImpl localization;
    late MockStorageService storage;
    late ServiceLocator locator;
    late MockAnalyticsService analytics;

    setUp(() async {
      locator = ServiceLocator();
      locator.clear();

      storage = MockStorageService();
      localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();

      // Wire localization into global singleton so context.l10n works
      LocalizationServiceImpl.instance = localization;

      // Register storage + analytics so ErrorCard / ErrorPresenter can resolve them.
      locator.register<StorageService>(storage);
      analytics = MockAnalyticsService();
      locator.register<AnalyticsService>(analytics);
      locator.register<BalanceValuationService>(FakeBalanceValuationService());
    });

    tearDown(() {
      ServiceLocator().clear();
    });

    Future<void> pumpCrypto({
      required WidgetTester tester,
      required BalanceService balanceService,
    }) async {
      final nav = MockNavigationService();

      await tester.pumpWidget(
        MaterialApp(
          home: CryptoScreen(
            navigation: nav,
            balanceService: balanceService,
            analytics: analytics,
            valuationService: locator.get<BalanceValuationService>(),
          ),
        ),
      );
    }

    testWidgets('shows inline error when load fails and allows manual retry', (
      tester,
    ) async {
      // Build some dummy "success" data for the second call
      final asset = Asset(
        id: 'btc',
        name: 'Bitcoin',
        symbol: 'BTC',
        type: AssetType.crypto,
        decimals: 8,
        priceSourceConfig: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final account = Account(
        id: 'acc1',
        name: 'Main',
        type: AccountType.exchange,
        notes: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final successBalances = <TotalAssetBalance>[
        TotalAssetBalance(
          asset: asset,
          totalBalance: 1.23,
          accountBalances: [
            AssetBalance(
              assetId: asset.id,
              accountId: account.id,
              balance: 1.23,
              asset: asset,
              account: account,
            ),
          ],
        ),
      ];

      final service = SequenceBalanceService([
        // First call: throw timeout AppError -> ErrorCard
        () async => throw const AppError(
          category: ErrorCategory.timeout,
          message: 'Simulated failure',
        ),
        // Second call: succeed
        () async => successBalances,
      ]);

      await pumpCrypto(tester: tester, balanceService: service);

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

      // 3) After retry, error is gone and content is no longer in error state
      expect(find.byType(ErrorCard), findsNothing);

      // We don't assert on exact success UI text here because CryptoScreen
      // renders localized strings and list tiles; this is enough to prove
      // "error → retry → non-error".
      expect(service.callCount, 2);
    });

    testWidgets('does not crash when disposed before load completes', (
      tester,
    ) async {
      final slowService = SlowFailingBalanceService();

      await pumpCrypto(tester: tester, balanceService: slowService);

      // Immediately dispose the CryptoScreen by swapping out the tree
      await tester.pumpWidget(const SizedBox.shrink());

      // Let the slow load finish; if CryptoScreen calls setState after dispose,
      // flutter_test will throw and the test will fail.
      await tester.pump(const Duration(milliseconds: 200));

      // If we get here, no "setState() called after dispose()" happened.
      expect(slowService.callCount, 1);
    });
  });
}
