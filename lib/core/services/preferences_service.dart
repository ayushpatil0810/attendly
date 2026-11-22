import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppPreferencesState {
  const AppPreferencesState();
}

class AppPreferencesNotifier extends Notifier<AppPreferencesState> {
  @override
  AppPreferencesState build() => const AppPreferencesState();
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesNotifier, AppPreferencesState>(
      AppPreferencesNotifier.new,
    );
