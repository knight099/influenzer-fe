import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'app_theme_mode';

/// Chosen in [main] from SharedPreferences before [runApp].
late final ThemeMode kInitialUserThemeMode;

Future<void> loadInitialThemeFromPrefs(SharedPreferences prefs) async {
  kInitialUserThemeMode =
      prefs.getString(_kThemeModeKey) == 'light' ? ThemeMode.light : ThemeMode.dark;
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => kInitialUserThemeMode;

  void setTheme(ThemeMode mode) {
    if (state == mode) return;
    state = mode;
    SharedPreferences.getInstance().then((p) {
      p.setString(
        _kThemeModeKey,
        mode == ThemeMode.light ? 'light' : 'dark',
      );
    });
  }

  void setDark(bool isDark) {
    setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Maps [ThemeMode] to the brightness the UI palette should use (not system; only light/dark in prefs).
Brightness brightnessFor(ThemeMode mode) {
  if (mode == ThemeMode.light) return Brightness.light;
  return Brightness.dark;
}
