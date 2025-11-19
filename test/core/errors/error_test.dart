import 'package:app_flutter_starter/core/errors/app_error.dart';
import 'package:app_flutter_starter/core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core Error Taxonomy', () {
    test('Result.success holds data', () {
      const result = Success<String>('test_data');
      expect(result.data, 'test_data');
      expect(result, isA<Result<String>>());
    });

    test('Result.failure holds AppError', () {
      const error = AppError(
        category: ErrorCategory.networkOffline,
        message: 'No internet',
      );
      const result = Failure<String>(error);
      expect(result.error.category, ErrorCategory.networkOffline);
      expect(result.error.message, 'No internet');
    });

    test('AppError stringifies correctly', () {
      const error = AppError(
        category: ErrorCategory.server5xx,
        message: 'Server exploded',
      );
      expect(
        error.toString(),
        'AppError(ErrorCategory.server5xx): Server exploded',
      );
    });
  });
}
