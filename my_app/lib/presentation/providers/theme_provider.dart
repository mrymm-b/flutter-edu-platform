import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ──────────────────────────────────────────────────────────────────────────────
// ThemeMode provider — Light / Dark / System
// Key: 'app_theme_mode'   values: 'light' | 'dark' | 'system'
//
// Legacy key 'selected_theme_index' is ignored (preset system removed).
// ──────────────────────────────────────────────────────────────────────────────

const _kKey = 'app_theme_mode_v2';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = _parse(prefs.getString(_kKey));
  }

  ThemeMode _parse(String? s) => switch (s) {
        'light'  => ThemeMode.light,
        'dark'   => ThemeMode.dark,
        _        => ThemeMode.light,
      };

  String _key(ThemeMode m) => switch (m) {
        ThemeMode.light  => 'light',
        ThemeMode.dark   => 'dark',
        _                => 'system',
      };

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, _key(mode));
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

// ── Legacy alias ───────────────────────────────────────────────────────────────
// Old code that called ref.watch(themeProvider) expected an int index.
// We keep the name but alias it to themeModeProvider for safe migration.
// Screens that previously read "kThemePresets[index]" should migrate to Tok.of(context).
final themeProvider = themeModeProvider;
