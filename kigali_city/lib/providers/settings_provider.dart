import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';

const _kNotificationsKey = 'notifications_enabled';

class SettingsState {
  final bool notificationsEnabled;
  final bool isLoading;

  const SettingsState({
    this.notificationsEnabled = false,
    this.isLoading = false,
  });

  SettingsState copyWith({bool? notificationsEnabled, bool? isLoading}) =>
      SettingsState(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        isLoading: isLoading ?? this.isLoading,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const SettingsState()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kNotificationsKey) ?? false;
    state = state.copyWith(notificationsEnabled: enabled, isLoading: false);
  }

  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsKey, enabled);

    // Also persist to Firestore user profile
    final user = _ref.read(authStateChangesProvider).asData?.value;
    if (user != null) {
      await _ref
          .read(authServiceProvider)
          .updateNotificationPreference(user.uid, enabled);
    }
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
      return SettingsNotifier(ref);
    });
