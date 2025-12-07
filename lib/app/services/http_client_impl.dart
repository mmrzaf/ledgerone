import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/environment.dart';
import '../../core/errors/app_error.dart';
import '../../core/network/http_client_contract.dart';

/// HTTP client implementation with:
/// - Base URL from AppConfig
/// - JSON (de)serialization
/// - AppError mapping from HTTP status codes and IO errors
class HttpClientImpl implements HttpClient {
  final AppConfig _config;
  final http.Client _client;
  final Duration _timeout;

  HttpClientImpl({
    required AppConfig config,
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  }) : _config = config,
       _client = client ?? http.Client(),
       _timeout = timeout;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) {
    return _request(method: 'GET', path: path, queryParams: queryParams);
  }

  @override
  Future<dynamic> post(String path, {dynamic body}) {
    return _request(method: 'POST', path: path, body: body);
  }

  @override
  Future<dynamic> put(String path, {dynamic body}) {
    return _request(method: 'PUT', path: path, body: body);
  }

  @override
  Future<dynamic> delete(String path) {
    return _request(method: 'DELETE', path: path);
  }

  Future<dynamic> _request({
    required String method,
    required String path,
    Map<String, dynamic>? queryParams,
    dynamic body,
  }) async {
    final uri = _buildUri(path, queryParams);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Add auth headers, tracing, etc. here when auth is reintroduced.
    };

    try {
      http.Response response;

      final encodedBody = body == null ? null : json.encode(body);

      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: encodedBody)
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: encodedBody)
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(_timeout);
          break;
        default:
          throw const AppError(
            category: ErrorCategory.badRequest,
            message: 'Unsupported HTTP method',
          );
      }

      return _handleResponse(response);
    } on AppError {
      // Re-throw AppErrors as-is
      rethrow;
    } on SocketException catch (e) {
      debugPrint('HTTP: Network error: $e');
      throw AppError(
        category: ErrorCategory.networkOffline,
        message: 'No internet connection',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      debugPrint('HTTP: Timeout: $e');
      throw AppError(
        category: ErrorCategory.timeout,
        message: 'Request timed out',
        originalError: e,
      );
    } on FormatException catch (e) {
      debugPrint('HTTP: Response parse error: $e');
      throw AppError(
        category: ErrorCategory.parseError,
        message: 'Failed to parse server response',
        originalError: e,
      );
    } catch (e, stack) {
      debugPrint('HTTP: Unknown error: $e');
      throw AppError(
        category: ErrorCategory.unknown,
        message: 'Unexpected error while calling API',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? queryParams) {
    Uri uri;

    final isAbsolute =
        path.startsWith('http://') || path.startsWith('https://');

    if (isAbsolute) {
      uri = Uri.parse(path);
    } else {
      final base = _config.apiBaseUrl.endsWith('/')
          ? _config.apiBaseUrl.substring(0, _config.apiBaseUrl.length - 1)
          : _config.apiBaseUrl;

      final normalizedPath = path.startsWith('/') ? path : '/$path';

      uri = Uri.parse('$base$normalizedPath');
    }

    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...queryParams.map((k, v) => MapEntry(k, '$v')),
      },
    );
  }

  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body;

    if (status >= 200 && status < 300) {
      if (body.isEmpty) return null;
      return json.decode(body);
    }

    // Map HTTP status → AppError category
    final category = _mapStatusToCategory(status);

    throw AppError(
      category: category,
      message: 'Request failed with status $status',
      originalError: body,
    );
  }

  ErrorCategory _mapStatusToCategory(int status) {
    if (status == 400) return ErrorCategory.badRequest;
    if (status == 401) return ErrorCategory.unauthorized;
    if (status == 403) return ErrorCategory.forbidden;
    if (status == 404) return ErrorCategory.notFound;
    if (status == 422) return ErrorCategory.badRequest;
    if (status >= 500 && status < 600) {
      return ErrorCategory.server5xx;
    }
    return ErrorCategory.unknown;
  }

  /// Call this from DI shutdown if you ever add an app-level teardown.
  void dispose() {
    _client.close();
  }
}
