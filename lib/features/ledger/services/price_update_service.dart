import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/network/http_client_contract.dart';
import '../data/database.dart';
import '../domain/models.dart';

/// Result of updating a single asset's price
class PriceUpdateResult {
  final Asset asset;
  final bool success;
  final double? price;
  final String? errorMessage;
  final DateTime timestamp;

  const PriceUpdateResult({
    required this.asset,
    required this.success,
    this.price,
    this.errorMessage,
    required this.timestamp,
  });
}

/// Aggregate result of updating multiple assets
class BulkPriceUpdateResult {
  final List<PriceUpdateResult> results;
  final int successCount;
  final int failureCount;

  const BulkPriceUpdateResult({
    required this.results,
    required this.successCount,
    required this.failureCount,
  });
}

/// Service for updating asset prices from configured sources
class PriceUpdateService {
  final HttpClient _httpClient;
  final AssetRepository _assetRepo;
  final PriceRepository _priceRepo;
  final LedgerDatabase _db;

  PriceUpdateService({
    required HttpClient httpClient,
    required AssetRepository assetRepo,
    required PriceRepository priceRepo,
    required LedgerDatabase db,
  }) : _httpClient = httpClient,
       _assetRepo = assetRepo,
       _priceRepo = priceRepo,
       _db = db;

  /// Update prices for all assets that have price source configs
  Future<BulkPriceUpdateResult> updateAllPrices() async {
    final assets = await _assetRepo.getAll();
    final assetsWithConfig = assets
        .where(
          (a) => a.priceSourceConfig != null && a.priceSourceConfig!.isNotEmpty,
        )
        .toList();

    final results = <PriceUpdateResult>[];
    int successCount = 0;
    int failureCount = 0;

    for (final asset in assetsWithConfig) {
      final result = await updatePrice(asset);
      results.add(result);

      if (result.success) {
        successCount++;
      } else {
        failureCount++;
      }
    }

    return BulkPriceUpdateResult(
      results: results,
      successCount: successCount,
      failureCount: failureCount,
    );
  }

  /// Update price for a single asset
  Future<PriceUpdateResult> updatePrice(Asset asset) async {
    if (asset.priceSourceConfig == null || asset.priceSourceConfig!.isEmpty) {
      return PriceUpdateResult(
        asset: asset,
        success: false,
        errorMessage: 'No price source configured',
        timestamp: DateTime.now(),
      );
    }

    try {
      // Parse config
      final config = PriceSourceConfig.fromJson(
        json.decode(asset.priceSourceConfig!) as Map<String, dynamic>,
      );

      // Fetch price
      final price = await _fetchPriceFromSource(config);

      // Store snapshot
      final snapshot = PriceSnapshot(
        id: _db.generateId(),
        assetId: asset.id,
        currencyCode: 'USD',
        price: price,
        timestamp: DateTime.now(),
        source: config.url,
      );

      await _priceRepo.insert(snapshot);

      return PriceUpdateResult(
        asset: asset,
        success: true,
        price: price,
        timestamp: snapshot.timestamp,
      );
    } catch (e) {
      debugPrint('Error updating price for ${asset.symbol}: $e');

      return PriceUpdateResult(
        asset: asset,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Test a price source config without saving
  Future<double> testPriceSource(PriceSourceConfig config) async {
    return await _fetchPriceFromSource(config);
  }

  /// Fetch price from a configured source
  Future<double> _fetchPriceFromSource(PriceSourceConfig config) async {
    try {
      // Make HTTP request
      dynamic response;

      if (config.method.toUpperCase() == 'GET') {
        response = await _httpClient.get(
          config.url,
          queryParams: config.queryParams.isEmpty
              ? null
              : config.queryParams.map((k, v) => MapEntry(k, v as dynamic)),
        );
      } else if (config.method.toUpperCase() == 'POST') {
        response = await _httpClient.post(config.url);
      } else {
        throw AppError(
          category: ErrorCategory.badRequest,
          message: 'Unsupported HTTP method: ${config.method}',
        );
      }

      // Extract price using response path
      final price = _extractPriceFromResponse(response, config.responsePath);

      // Apply multiplier
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

  /// Extract numeric price from response using dot notation path
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

    // Convert to double
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

/// Example price source configs for common APIs

class ExamplePriceConfigs {
  /// CoinGecko example
  static String coinGeckoConfig(String coinId) => json.encode({
    'method': 'GET',
    'url': 'https://api.coingecko.com/api/v3/simple/price',
    'query_params': {'ids': coinId, 'vs_currencies': 'usd'},
    'response_path': '$coinId.usd',
    'multiplier': 1.0,
  });

  /// Binance example
  static String binanceConfig(String symbol) => json.encode({
    'method': 'GET',
    'url': 'https://api.binance.com/api/v3/ticker/price',
    'query_params': {'symbol': symbol},
    'response_path': 'price',
    'multiplier': 1.0,
  });

  /// Generic JSON API
  static String genericConfig({
    required String url,
    required String responsePath,
    Map<String, String>? queryParams,
    double multiplier = 1.0,
  }) => json.encode({
    'method': 'GET',
    'url': url,
    'query_params': queryParams ?? {},
    'response_path': responsePath,
    'multiplier': multiplier,
  });
}
