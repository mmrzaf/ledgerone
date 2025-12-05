import '../../core/contracts/config_provider.dart';
import '../../core/errors/app_error.dart';
import '../../core/network/http_client_contract.dart';

/// RemoteConfigProvider implementation backed by an HTTP endpoint.
///
/// This does not assume any specific backend path or shape beyond
/// returning a JSON object. You provide the path when constructing it.
class HttpRemoteConfigProvider implements RemoteConfigProvider {
  final HttpClient _httpClient;
  final String _path;

  /// [path] is the relative path under your API base URL, e.g.:
  ///   '/config/flags' or '/v1/mobile/config'
  ///
  /// DI is responsible for choosing a sensible path per environment.
  HttpRemoteConfigProvider({
    required HttpClient httpClient,
    required String path,
  }) : _httpClient = httpClient,
       _path = path;

  @override
  Future<Map<String, dynamic>> fetchConfig() async {
    final result = await _httpClient.get(_path);

    if (result is Map<String, dynamic>) {
      // Return a copy to avoid unexpectedly sharing mutable structures.
      return Map<String, dynamic>.from(result);
    }

    throw const AppError(
      category: ErrorCategory.parseError,
      message: 'Remote config did not return a JSON object',
    );
  }
}
