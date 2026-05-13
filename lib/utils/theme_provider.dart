import 'package:flutter/material.dart';

class ThemeProvider extends InheritedWidget {
  final ThemeMode themeMode;
  final VoidCallback toggleTheme;

  const ThemeProvider({
    super.key,
    required this.themeMode,
    required this.toggleTheme,
    required super.child,
  });

  static ThemeProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>()!;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) =>
      themeMode != oldWidget.themeMode;
}

extension ThemeProviderExtension on BuildContext {
  ThemeProvider get appTheme => ThemeProvider.of(this);
}
