import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's light/dark theme mode and persists the user's choice
/// using SharedPreferences so it's remembered across app restarts.
///
/// NOTE: Many existing screens in this project hardcode colors like
/// `Colors.white` or a local `themeColor` constant instead of reading from
/// `Theme.of(context)`. This provider correctly switches the global
/// MaterialApp theme (AppBar, Scaffold background, text colors, etc.), but
/// screens that hardcode their own colors will not visually change unless
/// they're updated to use `Theme.of(context)` instead.
class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'isDarkMode';

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_prefsKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, isDark);
  }

  // Shared theme color used across the user side (kept consistent with the
  // existing themeColor constant already used throughout user screens).
  static const Color userThemeColor = Color(0xff10B981);

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: userThemeColor,
    scaffoldBackgroundColor: Colors.white,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: userThemeColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: userThemeColor,
      elevation: 0,
      iconTheme: IconThemeData(color: userThemeColor),
    ),
    cardColor: Colors.white,
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: userThemeColor,
    scaffoldBackgroundColor: const Color(0xFF121212),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: userThemeColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: userThemeColor,
      elevation: 0,
      iconTheme: IconThemeData(color: userThemeColor),
    ),
    cardColor: const Color(0xFF1E1E1E),
  );
}
