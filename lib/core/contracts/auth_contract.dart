abstract interface class AuthService {
  Future<bool> get isAuthenticated;
  Future<String?> get userId;
  
  Future<void> login(String email, String password);
  Future<void> logout();
  Future<void> refreshSession();
}
