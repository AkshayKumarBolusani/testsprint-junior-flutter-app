import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._prefs) : super(ThemeMode.system) {
    final raw = _prefs.getString(_kThemeKey);
    final pref = AppThemePreference.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => AppThemePreference.system,
    );
    state = switch (pref) {
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
      AppThemePreference.system => ThemeMode.system,
    };
  }

  final SharedPreferences _prefs;

  static const _kThemeKey = 'theme_preference';

  Future<void> setPreference(AppThemePreference pref) async {
    await _prefs.setString(_kThemeKey, pref.name);
    state = switch (pref) {
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
      AppThemePreference.system => ThemeMode.system,
    };
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return ThemeController(prefs);
});
