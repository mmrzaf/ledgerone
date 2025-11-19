abstract interface class RemoteConfigProvider {
  Future<Map<String, dynamic>> fetchConfig();
}
