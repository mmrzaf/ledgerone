import 'package:app_flutter_starter/core/errors/app_error.dart';

import '../../../core/contracts/auth_contract.dart';
import '../../../core/contracts/guard_contract.dart';

/// Guards routes that require authentication
class AuthGuard implements NavigationGuard {
  final AuthService _authService;

  AuthGuard(this._authService);

  @override
  Future<GuardResult> evaluate(
    String targetRouteId,
    String? currentRouteId,
  ) async {
    if (targetRouteId == 'login' || targetRouteId == 'onboarding') {
      return const GuardAllow();
    }

    final isAuthenticated = await _authService.isAuthenticated;

    if (!isAuthenticated) {
      try {
        await _authService.refreshSession();
        final stillAuthenticated = await _authService.isAuthenticated;

        if (stillAuthenticated) {
          return const GuardAllow();
        }
      } on AppError catch (e) {
        // If we are offline, do NOT kick the user out.
        // Trust the local 'isAuthenticated' state or handle gracefully.
        if (e.category == ErrorCategory.networkOffline ||
            e.category == ErrorCategory.timeout) {
          if (await _authService.isAuthenticated) return const GuardAllow();
        }
      } catch (_) {
        // Refresh failed, redirect to login
      }

      return const GuardRedirect('login');
    }

    return const GuardAllow();
  }

  @override
  int get priority => 10;

  @override
  String get name => 'AuthGuard';
}
