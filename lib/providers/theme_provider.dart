import 'package:absensi/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Jalur impor yang benar

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isDarkMode;

  ThemeProvider(this._prefs)
    : _isDarkMode = _prefs.getBool(AppConstants.themeModeKey) ?? false;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs.setBool(AppConstants.themeModeKey, _isDarkMode);
    notifyListeners();
  }
}
