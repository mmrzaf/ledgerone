import 'dart:async';

import 'package:flutter/foundation.dart';

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
    debugPrint('[DEV HTTP] GET $path params=$queryParams');
    final result = await _withDelay(_inner.get(path, queryParams: queryParams));
    debugPrint('[DEV HTTP] GET $path → $result');
    return result;
  }

  @override
  Future<dynamic> post(String path, {dynamic body}) async {
    debugPrint('[DEV HTTP] POST $path body=$body');
    final result = await _withDelay(_inner.post(path, body: body));
    debugPrint('[DEV HTTP] POST $path → $result');
    return result;
  }

  @override
  Future<dynamic> put(String path, {dynamic body}) async {
    debugPrint('[DEV HTTP] PUT $path body=$body');
    final result = await _withDelay(_inner.put(path, body: body));
    debugPrint('[DEV HTTP] PUT $path → $result');
    return result;
  }

  @override
  Future<dynamic> delete(String path) async {
    debugPrint('[DEV HTTP] DELETE $path');
    final result = await _withDelay(_inner.delete(path));
    debugPrint('[DEV HTTP] DELETE $path → $result');
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
