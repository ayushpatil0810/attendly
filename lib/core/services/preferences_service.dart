import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';

const String _hapticFeedbackKey = 'pref_haptic_feedback_enabled_v1';

class AppPreferencesState {
  const AppPreferencesState({this.hapticFeedbackEnabled = true});

  final bool hapticFeedbackEnabled;

  AppPreferencesState copyWith({bool? hapticFeedbackEnabled}) {
    return AppPreferencesState(
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    );
  }
}

class AppPreferencesNotifier extends Notifier<AppPreferencesState> {
  @override
  AppPreferencesState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final haptic = prefs.getBool(_hapticFeedbackKey) ?? true;
    return AppPreferencesState(hapticFeedbackEnabled: haptic);
  }

  void setHapticFeedback(bool enabled) {
    state = state.copyWith(hapticFeedbackEnabled: enabled);
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool(_hapticFeedbackKey, enabled);
  }
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesNotifier, AppPreferencesState>(
      AppPreferencesNotifier.new,
    );

/// Global haptic utility respecting user preference
abstract final class AppHaptics {
  static void lightImpact(WidgetRef ref) {
    final enabled = ref.read(appPreferencesProvider).hapticFeedbackEnabled;
    if (enabled) {
      HapticFeedback.lightImpact();
    }
  }

  static void selectionClick(WidgetRef ref) {
    final enabled = ref.read(appPreferencesProvider).hapticFeedbackEnabled;
    if (enabled) {
      HapticFeedback.selectionClick();
    }
  }
}
