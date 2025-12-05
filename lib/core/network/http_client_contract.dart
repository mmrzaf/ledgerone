abstract interface class HttpClient {
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams});

  Future<dynamic> post(String path, {dynamic body});

  Future<dynamic> put(String path, {dynamic body});

  Future<dynamic> delete(String path);
}
