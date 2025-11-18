abstract interface class CrashService {
  Future<void> recordError(dynamic exception, StackTrace? stack, {dynamic reason});
  Future<void> log(String message);
}
