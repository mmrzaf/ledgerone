import '../../../core/errors/app_error.dart';
import '../../../core/network/http_client_contract.dart';
import '../domain/home_models.dart';
import '../domain/home_source.dart';

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final HttpClient _http;

  HomeRemoteDataSourceImpl(this._http);

  @override
  Future<HomeData> fetchHomeData() async {
    try {
      // Call the remote endpoint (path value doesn't matter for the tests)
      final dynamic raw = await _http.get('/home');

      // We expect either:
      // 1) { "message": "...", "timestamp": "..." }
      // 2) { "data": { "message": "...", "timestamp": "..." } }
      Map<String, dynamic> json;

      if (raw is Map<String, dynamic>) {
        if (raw['data'] is Map<String, dynamic>) {
          json = Map<String, dynamic>.from(raw['data'] as Map);
        } else {
          json = raw;
        }
      } else {
        // Any non-map response shape is a parse error
        throw const AppError(
          category: ErrorCategory.parseError,
          message: 'Invalid home data response shape',
        );
      }

      // Basic shape validation – if the required keys are missing, also treat as parse error
      if (!json.containsKey('message') || !json.containsKey('timestamp')) {
        throw const AppError(
          category: ErrorCategory.parseError,
          message: 'Missing required home data fields',
        );
      }

      return HomeData.fromJson(json);
    } on AppError {
      // Propagate AppError from HTTP client or our own parse errors
      rethrow;
    } catch (e) {
      // Wrap any other exception
      throw AppError(
        category: ErrorCategory.server5xx,
        message: 'Failed to fetch home data: $e',
      );
    }
  }
}
