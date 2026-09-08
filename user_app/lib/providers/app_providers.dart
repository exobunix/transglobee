import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

// Demo user state - simple notifier to track login state
class DemoUserNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void login() => state = true;
  void logout() => state = false;
}

// Demo user state provider for testing without Firebase
final demoUserProvider = NotifierProvider<DemoUserNotifier, bool>(
  DemoUserNotifier.new,
);

// Theme mode notifier
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
