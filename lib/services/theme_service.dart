import 'package:flutter/material.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._init();
  ThemeService._init();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  void toggleTheme() {
    if (themeModeNotifier.value == ThemeMode.dark) {
      themeModeNotifier.value = ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }
}
