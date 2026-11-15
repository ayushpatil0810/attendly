import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _onboardingKey = 'has_completed_onboarding_v1';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_onboardingKey, true);
    state = true;
  }

  Future<void> resetOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_onboardingKey, false);
    state = false;
  }
}

final onboardingCompletedProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
