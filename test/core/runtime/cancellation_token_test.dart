import 'package:app_flutter_starter/core/runtime/cancellation_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CancellationToken', () {
    test('starts not cancelled', () {
      final token = CancellationToken();
      expect(token.isCancelled, isFalse);
    });

    test('cancel sets isCancelled to true', () {
      final token = CancellationToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('throwIfCancelled throws when cancelled', () {
      final token = CancellationToken();
      token.cancel();

      expect(
        () => token.throwIfCancelled(),
        throwsA(isA<OperationCancelledException>()),
      );
    });

    test('throwIfCancelled does not throw when not cancelled', () {
      final token = CancellationToken();
      expect(() => token.throwIfCancelled(), returnsNormally);
    });

    test('onCancel callback called immediately if already cancelled', () {
      final token = CancellationToken();
      token.cancel();

      var called = false;
      token.onCancel(() => called = true);

      expect(called, isTrue);
    });

    test('onCancel callback called when cancelled later', () {
      final token = CancellationToken();
      var called = false;

      token.onCancel(() => called = true);
      expect(called, isFalse);

      token.cancel();
      expect(called, isTrue);
    });

    test('multiple onCancel callbacks are all called', () {
      final token = CancellationToken();
      var count = 0;

      token.onCancel(() => count++);
      token.onCancel(() => count++);
      token.onCancel(() => count++);

      token.cancel();
      expect(count, equals(3));
    });

    test('callbacks cleared after cancel', () {
      final token = CancellationToken();
      var count = 0;

      token.onCancel(() => count++);
      token.cancel();
      expect(count, equals(1));

      // Cancel again shouldn't call callbacks again
      token.cancel();
      expect(count, equals(1));
    });

    test('callback exceptions do not prevent other callbacks', () {
      final token = CancellationToken();
      var callback1Called = false;
      var callback2Called = false;

      token.onCancel(() {
        callback1Called = true;
        throw Exception('Error in callback');
      });
      token.onCancel(() => callback2Called = true);

      token.cancel();

      expect(callback1Called, isTrue);
      expect(callback2Called, isTrue);
    });
  });

  group('CancellationToken.none', () {
    test('is never cancelled', () {
      expect(CancellationToken.none.isCancelled, isFalse);
    });

    test('cancel does nothing', () {
      CancellationToken.none.cancel();
      expect(CancellationToken.none.isCancelled, isFalse);
    });

    test('throwIfCancelled never throws', () {
      expect(() => CancellationToken.none.throwIfCancelled(), returnsNormally);
    });
  });

  group('CancellationTokenSource', () {
    test('creates token', () {
      final source = CancellationTokenSource();
      expect(source.token, isNotNull);
      expect(source.token.isCancelled, isFalse);
    });

    test('cancel cancels the token', () {
      final source = CancellationTokenSource();
      source.cancel();
      expect(source.token.isCancelled, isTrue);
    });

    test('dispose cancels the token', () {
      final source = CancellationTokenSource();
      source.dispose();
      expect(source.token.isCancelled, isTrue);
    });
  });

  group('OperationCancelledException', () {
    test('has default message', () {
      const exception = OperationCancelledException();
      expect(exception.message, equals('Operation was cancelled'));
    });

    test('accepts custom message', () {
      const exception = OperationCancelledException('Custom message');
      expect(exception.message, equals('Custom message'));
    });

    test('toString includes message', () {
      const exception = OperationCancelledException('Test');
      expect(exception.toString(), contains('Test'));
    });
  });
}
