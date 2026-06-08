import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark, blue }

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier() : super(AppTheme.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_theme') ?? 'light';
    state = _fromString(saved);
  }

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', _toKey(theme));
  }

  AppTheme _fromString(String s) {
    switch (s) {
      case 'dark': return AppTheme.dark;
      case 'blue': return AppTheme.blue;
      default: return AppTheme.light;
    }
  }

  String _toKey(AppTheme t) {
    switch (t) {
      case AppTheme.dark: return 'dark';
      case AppTheme.blue: return 'blue';
      default: return 'light';
    }
  }
}

ThemeData buildThemeData(AppTheme appTheme) {
  switch (appTheme) {
    case AppTheme.dark:
      return ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5100),
          secondary: Color(0xFF1A1AFF),
          surface: Color(0xFF1E1E1E),
        ),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.white12,
      );
    case AppTheme.blue:
      return ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F4FF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1A1AFF),
          secondary: Color(0xFFFF5100),
          surface: Color(0xFFE4EBFF),
        ),
        cardColor: const Color(0xFFE4EBFF),
        dividerColor: Colors.black12,
      );
    default:
      return ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF5100),
          secondary: Color(0xFF1A1AFF),
        ),
        cardColor: Colors.white,
        dividerColor: Colors.black12,
      );
  }
}

extension AppThemeX on AppTheme {
  String get label {
    switch (this) {
      case AppTheme.dark: return 'dark';
      case AppTheme.blue: return 'blue';
      default: return 'light';
    }
  }

  Color get bgColor {
    switch (this) {
      case AppTheme.dark: return const Color(0xFF121212);
      case AppTheme.blue: return const Color(0xFFF0F4FF);
      default: return Colors.white;
    }
  }

  Color get accentColor {
    switch (this) {
      case AppTheme.dark: return const Color(0xFFFF5100);
      case AppTheme.blue: return const Color(0xFF1A1AFF);
      default: return const Color(0xFFFF5100);
    }
  }
}
