import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ledgerone/app/services/http_client_impl.dart';
import 'package:ledgerone/core/config/environment.dart';
import 'package:ledgerone/core/errors/app_error.dart';

void main() {
  group('HttpClientImpl', () {
    const config = AppConfig.dev;

    test('GET request succeeds with valid response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/test');
        return http.Response('{"data": "success"}', 200);
      });

      final client = HttpClientImpl(config: config, client: mockClient);
      final result = await client.get('/api/test');

      expect(result, {'data': 'success'});
    });

    test('POST request sends body correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.body, '{"key":"value"}');
        expect(request.headers['Content-Type'], 'application/json');
        return http.Response('{"status": "created"}', 201);
      });

      final client = HttpClientImpl(config: config, client: mockClient);
      final result = await client.post('/api/test', body: {'key': 'value'});

      expect(result, {'status': 'created'});
    });

    test('PUT request sends body correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.body, '{"updated":"data"}');
        return http.Response('{"status": "updated"}', 200);
      });

      final client = HttpClientImpl(config: config, client: mockClient);
      final result = await client.put('/api/test', body: {'updated': 'data'});

      expect(result, {'status': 'updated'});
    });

    test('DELETE request works correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response('', 204);
      });

      final client = HttpClientImpl(config: config, client: mockClient);
      final result = await client.delete('/api/test');

      expect(result, isNull); // Empty body
    });

    test('handles query parameters correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['limit'], '10');
        return http.Response('{"data": []}', 200);
      });

      final client = HttpClientImpl(config: config, client: mockClient);
      await client.get('/api/test', queryParams: {'page': 1, 'limit': 10});
    });

    test('throws networkOffline on SocketException', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('No internet');
      });

      final client = HttpClientImpl(config: config, client: mockClient);

      expect(
        () => client.get('/api/test'),
        throwsA(
          isA<AppError>().having(
            (e) => e.category,
            'category',
            ErrorCategory.networkOffline,
          ),
        ),
      );
    });

    test('throws timeout on TimeoutException', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Request timeout');
      });

      final client = HttpClientImpl(
        config: config,
        client: mockClient,
        timeout: const Duration(seconds: 1),
      );

      expect(
        () => client.get('/api/test'),
        throwsA(
          isA<AppError>().having(
            (e) => e.category,
            'category',
            ErrorCategory.timeout,
          ),
        ),
      );
    });

    test('maps 400 status to badRequest', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Bad request', 400);
      });

      final client = HttpClientImpl(config: config, client: mockClient);

      expect(
        () => client.get('/api/test'),
        throwsA(
          isA<AppError>().having(
            (e) => e.category,
            'category',
            ErrorCategory.badRequest,
          ),
        ),
      );
    });

    test('maps 401 status to unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final client = HttpClientImpl(config: config, client: mockClient);

      expect(
        () => client.get('/api/test'),
        throwsA(
          isA<AppError>().having(
            (e) => e.category,
            'category',
            ErrorCategory.unauthorized,
          ),
        ),
      );
    });

    test('maps 403 status to forbidden', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      final client = HttpClientImpl(config: config, client: mockClient);

      expect(
        () => client.get('/api/test'),
        throwsA(
          isA<AppError>().having(
            (e) => e.category,
            'category',
            ErrorCategory.forbidden,
          ),
        ),
      );
    });

    test('maps 404 status to notFound', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not found', 404);
      });

      final client = HttpClientImpl(config: config, client: mockClient);

      expect(
        () => client.get('/api/test'),
        throwsA(
          isA<AppError>().having(
            (e) => e.category,
            'category',
            ErrorCategory.notFound,
          ),
        ),
      );
    });

    test('maps 5xx status to server5xx', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal server error', 500);
      });

      final client = HttpClientImpl(config: config, client: mockClient);

      expect(
        () => client.get('/api/test'),
        throwsA(
          isA<AppError>().having(
            (e) => e.category,
            'category',
            ErrorCategory.server5xx,
          ),
        ),
      );
    });

    test('throws parseError on invalid JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response('not json', 200);
      });

      final client = HttpClientImpl(config: config, client: mockClient);

      expect(
        () => client.get('/api/test'),
        throwsA(
          isA<AppError>().having(
            (e) => e.category,
            'category',
            ErrorCategory.parseError,
          ),
        ),
      );
    });

    test('handles empty response body', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 200);
      });

      final client = HttpClientImpl(config: config, client: mockClient);
      final result = await client.get('/api/test');

      expect(result, isNull);
    });

    test('normalizes paths correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/test');
        return http.Response('{}', 200);
      });

      final client = HttpClientImpl(config: config, client: mockClient);

      // Test with leading slash
      await client.get('/api/test');

      // Test without leading slash
      await client.get('api/test');
    });
  });
}
