import '../../../core/contracts/guard_contract.dart';
import '../../../core/contracts/storage_contract.dart';

/// Guards routes that require onboarding to be completed
class OnboardingGuard implements NavigationGuard {
  final StorageService _storage;

  OnboardingGuard(this._storage);

  @override
  Future<GuardResult> evaluate(
    String targetRouteId,
    String? currentRouteId,
  ) async {
    if (targetRouteId == 'onboarding') {
      return const GuardAllow();
    }

    final onboardingSeen = await _storage.getBool('onboarding_seen') ?? false;

    if (!onboardingSeen) {
      return const GuardRedirect('onboarding');
    }

    return const GuardAllow();
  }

  @override
  int get priority => 0;

  @override
  String get name => 'OnboardingGuard';
}
