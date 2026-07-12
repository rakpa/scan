import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has completed first-run onboarding.
class OnboardingStore {
  OnboardingStore(this._prefs);

  static const _completeKey = 'onboarding_complete_v3';
  static const _premiumKey = 'premium_unlocked_v1';
  final SharedPreferences _prefs;

  bool get isComplete => _prefs.getBool(_completeKey) ?? false;

  bool get premiumUnlocked => _prefs.getBool(_premiumKey) ?? false;

  Future<void> markComplete() => _prefs.setBool(_completeKey, true);

  Future<void> unlockPremium() => _prefs.setBool(_premiumKey, true);
}

/// Async singleton — resolved once at startup.
final onboardingStoreProvider = FutureProvider<OnboardingStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return OnboardingStore(prefs);
});
