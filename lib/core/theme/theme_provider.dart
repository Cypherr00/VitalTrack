import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  bool isLoaded = false;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    if (isDark != null) {
      themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    isLoaded = true;
    notifyListeners();
  }

  bool get isDarkMode {
    return themeMode == ThemeMode.dark;
  }

  void toggleTheme(bool isDark) async {
    themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }
}
