import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<bool> {
  static const _key = 'is_dark_mode';

  @override
  bool build() {
    // We'll manage persistence in a simple way for the demo
    // In a real app, we'd use a repository
    return true; // Default to dark mode
  }

  void toggle() {
    state = !state;
  }
}
