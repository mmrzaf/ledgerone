import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerone/core/errors/app_error.dart';
import 'package:ledgerone/core/errors/result.dart';

void main() {
  group('Result', () {
    test('should return correct data when Success', () {
      const result = Success<int>(42);
      expect(result.data, 42);
    });

    test('should return correct error when Failure', () {
      const result = Failure<int>(
        AppError(category: ErrorCategory.unknown, message: 'oops'),
      );
      expect(result.error, isA<Exception>());
    });
  });
}
