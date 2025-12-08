import 'dart:async';
import 'dart:convert';

import '../../../core/contracts/analytics_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/network/http_client_contract.dart';
import '../../../core/observability/performance_tracker.dart';
import '../data/database.dart';
import '../data/repositories_interfaces.dart';
import '../domain/models.dart';
import '../domain/services.dart';

class PriceUpdateServiceImpl implements PriceUpdateService {
  final HttpClient httpClient;
  final AssetRepository assetRepo;
  final PriceRepository priceRepo;
  final LedgerDatabase db;
  final AnalyticsService analytics;
  final PerformanceTracker performance;

  static const int maxConcurrentRequests = 3;

  PriceUpdateServiceImpl({
    required this.httpClient,
    required this.assetRepo,
    required this.priceRepo,
    required this.db,
    required this.analytics,
    required this.performance,
  });

  @override
  Future<BulkPriceUpdateResult> updateAllPrices() async {
    final startedAt = DateTime.now();
    performance.start('price_update_all');

    await analytics.logEvent('price_update_started');

    try {
      final assets = await assetRepo.getAll();
      final assetsWithConfig = assets
          .where(
            (a) =>
                a.priceSourceConfig != null && a.priceSourceConfig!.isNotEmpty,
          )
          .toList();

      if (assetsWithConfig.isEmpty) {
        final completedAt = DateTime.now();
        return BulkPriceUpdateResult(
          results: [],
          successCount: 0,
          failureCount: 0,
          startedAt: startedAt,
          completedAt: completedAt,
        );
      }

      final results = await _updateWithConcurrency(assetsWithConfig);

      final successCount = results.where((r) => r.success).length;
      final failureCount = results.where((r) => !r.success).length;
      final completedAt = DateTime.now();

      final bulkResult = BulkPriceUpdateResult(
        results: results,
        successCount: successCount,
        failureCount: failureCount,
        startedAt: startedAt,
        completedAt: completedAt,
      );

      final metric = performance.stop('price_update_all');
      await analytics.logEvent(
        'price_update_finished',
        parameters: {
          'success_count': successCount,
          'failure_count': failureCount,
          'duration_ms': metric?.durationMs ?? 0,
        },
      );

      return bulkResult;
    } catch (e) {
      performance.stop('price_update_all');
      final completedAt = DateTime.now();

      await analytics.logEvent(
        'price_update_failed',
        parameters: {'error': e.toString()},
      );

      return BulkPriceUpdateResult(
        results: [],
        successCount: 0,
        failureCount: 0,
        startedAt: startedAt,
        completedAt: completedAt,
      );
    }
  }

  Future<List<PriceUpdateResult>> _updateWithConcurrency(
    List<Asset> assets,
  ) async {
    final results = <PriceUpdateResult>[];
    final queue = List<Asset>.from(assets);
    final inFlight = <Future<PriceUpdateResult>>[];

    while (queue.isNotEmpty || inFlight.isNotEmpty) {
      while (inFlight.length < maxConcurrentRequests && queue.isNotEmpty) {
        final asset = queue.removeAt(0);
        inFlight.add(updatePrice(asset));
      }

      if (inFlight.isNotEmpty) {
        final completed = await Future.any(
          inFlight.map((f) => f.then((r) => MapEntry(f, r))),
        );

        inFlight.remove(completed.key);
        results.add(completed.value);
      }
    }

    return results;
  }

  @override
  Future<PriceUpdateResult> updatePrice(Asset asset) async {
    if (asset.priceSourceConfig == null || asset.priceSourceConfig!.isEmpty) {
      return PriceUpdateResult(
        asset: asset,
        success: false,
        error: const AppError(
          category: ErrorCategory.badRequest,
          message: 'No price source configured',
        ),
        timestamp: DateTime.now(),
      );
    }

    try {
      final config = PriceSourceConfig.fromJson(
        json.decode(asset.priceSourceConfig!) as Map<String, dynamic>,
      );

      final price = await _fetchPriceFromSource(config);

      final snapshot = PriceSnapshot(
        id: db.generateId(),
        assetId: asset.id,
        currencyCode: 'USD',
        price: price,
        timestamp: DateTime.now(),
        source: config.url,
      );

      await priceRepo.insert(snapshot);

      await analytics.logEvent(
        'price_update_success',
        parameters: {'asset_id': asset.id, 'price': price},
      );

      return PriceUpdateResult(
        asset: asset,
        success: true,
        price: price,
        timestamp: snapshot.timestamp,
      );
    } on AppError catch (e) {
      return PriceUpdateResult(
        asset: asset,
        success: false,
        error: e,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      final appError = AppError(
        category: ErrorCategory.unknown,
        message: 'Failed to update price: ${e.toString()}',
        originalError: e,
      );

      return PriceUpdateResult(
        asset: asset,
        success: false,
        error: appError,
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  Future<double> testPriceSource(PriceSourceConfig config) async {
    return await _fetchPriceFromSource(config);
  }

  Future<double> _fetchPriceFromSource(PriceSourceConfig config) async {
    try {
      dynamic response;

      if (config.method.toUpperCase() == 'GET') {
        response = await httpClient.get(
          config.url,
          queryParams: config.queryParams.isEmpty
              ? null
              : config.queryParams.map((k, v) => MapEntry(k, v as dynamic)),
        );
      } else if (config.method.toUpperCase() == 'POST') {
        response = await httpClient.post(config.url);
      } else {
        throw AppError(
          category: ErrorCategory.badRequest,
          message: 'Unsupported HTTP method: ${config.method}',
        );
      }

      final price = _extractPriceFromResponse(response, config.responsePath);
      return price * config.multiplier;
    } on AppError {
      rethrow;
    } catch (e) {
      throw AppError(
        category: ErrorCategory.parseError,
        message: 'Failed to fetch price: $e',
        originalError: e,
      );
    }
  }

  double _extractPriceFromResponse(dynamic response, String path) {
    if (response == null) {
      throw const AppError(
        category: ErrorCategory.parseError,
        message: 'Empty response from price source',
      );
    }

    dynamic current = response;
    final parts = path.split('.');

    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else {
        throw AppError(
          category: ErrorCategory.parseError,
          message: 'Cannot navigate path "$path" in response',
        );
      }

      if (current == null) {
        throw AppError(
          category: ErrorCategory.parseError,
          message: 'Path "$path" not found in response',
        );
      }
    }

    if (current is num) {
      return current.toDouble();
    }

    if (current is String) {
      final parsed = double.tryParse(current);
      if (parsed != null) return parsed;
    }

    throw AppError(
      category: ErrorCategory.parseError,
      message: 'Value at path "$path" is not a number: $current',
    );
  }
}
