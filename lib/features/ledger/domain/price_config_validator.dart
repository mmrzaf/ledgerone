import 'dart:convert';

import '../../../core/errors/app_error.dart';
import 'models.dart';

class PriceConfigValidationResult {
  final bool isValid;
  final String? error;
  final PriceSourceConfig? config;

  const PriceConfigValidationResult({
    required this.isValid,
    this.error,
    this.config,
  });

  factory PriceConfigValidationResult.success(PriceSourceConfig config) {
    return PriceConfigValidationResult(isValid: true, config: config);
  }

  factory PriceConfigValidationResult.failure(String error) {
    return PriceConfigValidationResult(isValid: false, error: error);
  }
}

class PriceConfigValidator {
  /// Validate a price config JSON string
  static PriceConfigValidationResult validate(String? configJson) {
    if (configJson == null || configJson.trim().isEmpty) {
      return PriceConfigValidationResult.failure(
        'Price config cannot be empty',
      );
    }

    // Parse JSON
    Map<String, dynamic> json;
    try {
      json = jsonDecode(configJson) as Map<String, dynamic>;
    } catch (e) {
      return PriceConfigValidationResult.failure(
        'Invalid JSON format: ${e.toString()}',
      );
    }

    // Validate URL
    if (!json.containsKey('url') || json['url'] == null) {
      return PriceConfigValidationResult.failure('URL is required');
    }

    final url = json['url'] as String?;
    if (url == null || url.trim().isEmpty) {
      return PriceConfigValidationResult.failure('URL cannot be empty');
    }

    // Basic URL validation
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return PriceConfigValidationResult.failure(
        'URL must start with http:// or https://',
      );
    }

    // Validate response path
    if (!json.containsKey('response_path') || json['response_path'] == null) {
      return PriceConfigValidationResult.failure('Response path is required');
    }

    final responsePath = json['response_path'] as String?;
    if (responsePath == null || responsePath.trim().isEmpty) {
      return PriceConfigValidationResult.failure(
        'Response path cannot be empty',
      );
    }

    // Validate HTTP method
    final method = (json['method'] as String?)?.toUpperCase() ?? 'GET';
    if (method != 'GET' && method != 'POST') {
      return PriceConfigValidationResult.failure(
        'HTTP method must be GET or POST',
      );
    }

    // Validate multiplier if present
    if (json.containsKey('multiplier')) {
      final multiplier = json['multiplier'];
      if (multiplier != null) {
        if (multiplier is! num) {
          return PriceConfigValidationResult.failure(
            'Multiplier must be a number',
          );
        }
        if (multiplier <= 0) {
          return PriceConfigValidationResult.failure(
            'Multiplier must be positive',
          );
        }
      }
    }

    // Validate invert if present
    if (json.containsKey('invert')) {
      final invert = json['invert'];
      if (invert != null && invert is! bool) {
        return PriceConfigValidationResult.failure(
          'Invert must be true or false',
        );
      }
    }

    // Validate query_params if present
    if (json.containsKey('query_params')) {
      final queryParams = json['query_params'];
      if (queryParams != null && queryParams is! Map) {
        return PriceConfigValidationResult.failure(
          'Query params must be an object',
        );
      }
    }

    // Validate headers if present
    if (json.containsKey('headers')) {
      final headers = json['headers'];
      if (headers != null && headers is! Map) {
        return PriceConfigValidationResult.failure('Headers must be an object');
      }
    }

    // Try to construct the config
    PriceSourceConfig config;
    try {
      config = PriceSourceConfig.fromJson(json);
    } catch (e) {
      return PriceConfigValidationResult.failure(
        'Invalid config: ${e.toString()}',
      );
    }

    return PriceConfigValidationResult.success(config);
  }

  /// Test a price config by making an actual API call
  static Future<PriceConfigTestResult> test(
    PriceSourceConfig config,
    Future<double> Function(PriceSourceConfig) fetchFunction,
  ) async {
    try {
      final price = await fetchFunction(config);
      return PriceConfigTestResult.success(price);
    } on AppError catch (e) {
      return PriceConfigTestResult.failure(e.message);
    } catch (e) {
      return PriceConfigTestResult.failure(e.toString());
    }
  }
}

class PriceConfigTestResult {
  final bool success;
  final double? price;
  final String? error;

  const PriceConfigTestResult({required this.success, this.price, this.error});

  factory PriceConfigTestResult.success(double price) {
    return PriceConfigTestResult(success: true, price: price);
  }

  factory PriceConfigTestResult.failure(String error) {
    return PriceConfigTestResult(success: false, error: error);
  }
}
