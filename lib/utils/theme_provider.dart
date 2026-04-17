import 'package:flutter/material.dart';

class ThemeProvider extends StatefulWidget {
  final Widget child;

  const ThemeProvider({super.key, required this.child});

  @override
  State<ThemeProvider> createState() => ThemeProviderState();
}

class ThemeProviderState extends State<ThemeProvider> {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  static ThemeProviderState of(BuildContext context) {
    final state = context.findAncestorStateOfType<ThemeProviderState>();
    assert(state != null, 'ThemeProvider not found in widget tree');
    return state!;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

extension ThemeProviderExtension on BuildContext {
  ThemeProviderState? get themeProvider {
    try {
      return ThemeProviderState.of(this);
    } catch (_) {
      return null;
    }
  }
}
