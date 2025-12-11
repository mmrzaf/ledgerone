import 'dart:async';

import 'package:ledgerone/core/observability/app_logger.dart';

import '../../../core/network/http_client_contract.dart';

/// Dev-only HttpClient wrapper:
/// - Logs requests and responses
/// - Can add artificial delay to simulate slow networks
///
/// Still uses a real inner HttpClientImpl; no fake responses.
class DevHttpClient implements HttpClient {
  final HttpClient _inner;
  final Duration artificialDelay;

  DevHttpClient({
    required HttpClient inner,
    this.artificialDelay = Duration.zero,
  }) : _inner = inner;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    AppLogger.debug('GET $path params=$queryParams', tag: 'HTTP');
    final result = await _withDelay(_inner.get(path, queryParams: queryParams));
    AppLogger.debug('GET $path → $result', tag: 'HTTP');
    return result;
  }

  @override
  Future<dynamic> post(String path, {dynamic body}) async {
    AppLogger.debug('POST $path body=$body', tag: 'HTTP');
    final result = await _withDelay(_inner.post(path, body: body));
    AppLogger.debug('POST $path → $result', tag: 'HTTP');
    return result;
  }

  @override
  Future<dynamic> put(String path, {dynamic body}) async {
    AppLogger.debug('PUT $path body=$body', tag: 'HTTP');
    final result = await _withDelay(_inner.put(path, body: body));
    AppLogger.debug('PUT $path → $result', tag: 'HTTP');
    return result;
  }

  @override
  Future<dynamic> delete(String path) async {
    AppLogger.debug('DELETE $path', tag: 'HTTP');
    final result = await _withDelay(_inner.delete(path));
    AppLogger.debug('DELETE $path → $result', tag: 'HTTP');
    return result;
  }

  Future<T> _withDelay<T>(Future<T> future) async {
    final result = await future;
    if (artificialDelay > Duration.zero) {
      await Future<void>.delayed(artificialDelay);
    }
    return result;
  }
}
