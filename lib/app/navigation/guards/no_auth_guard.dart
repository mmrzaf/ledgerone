import '../../../core/contracts/auth_contract.dart';
import '../../../core/contracts/guard_contract.dart';

/// Guards routes that require the user to NOT be authenticated
class NoAuthGuard implements NavigationGuard {
  final AuthService _authService;

  NoAuthGuard(this._authService);

  @override
  Future<GuardResult> evaluate(
    String targetRouteId,
    String? currentRouteId,
  ) async {
    if (targetRouteId != 'login') {
      return const GuardAllow();
    }

    final isAuthenticated = await _authService.isAuthenticated;

    if (isAuthenticated) {
      return const GuardRedirect('home');
    }

    return const GuardAllow();
  }

  @override
  int get priority => 20;

  @override
  String get name => 'NoAuthGuard';
}
