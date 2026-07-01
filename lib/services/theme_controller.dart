import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple app-wide theme mode notifier — light/dark, persisted.
class ThemeController {
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier(ThemeMode.dark);

  static const _key = 'nemotron_theme_mode';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'light') mode.value = ThemeMode.light;
    else if (saved == 'dark') mode.value = ThemeMode.dark;
  }

  static Future<void> toggle() async {
    final newMode = mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    mode.value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newMode == ThemeMode.dark ? 'dark' : 'light');
  }

  static Future<void> set(ThemeMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, m == ThemeMode.dark ? 'dark' : 'light');
  }
}
