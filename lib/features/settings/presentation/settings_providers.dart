import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-facing app preferences persisted across launches.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  static const _key = 'pref_theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key);
    if (index != null && index >= 0 && index < ThemeMode.values.length) {
      state = ThemeMode.values[index];
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Whether new scan sessions start with auto-capture enabled.
class AutoCaptureDefaultNotifier extends StateNotifier<bool> {
  AutoCaptureDefaultNotifier() : super(true) {
    _load();
  }

  static const _key = 'pref_auto_capture_default';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}

final autoCaptureDefaultProvider =
    StateNotifierProvider<AutoCaptureDefaultNotifier, bool>((ref) {
  return AutoCaptureDefaultNotifier();
});
