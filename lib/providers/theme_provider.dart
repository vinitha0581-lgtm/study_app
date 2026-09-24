import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  final StorageService _storageService;
  bool _isDarkMode = true;

  ThemeProvider(this._storageService) {
    final settings = _storageService.getSettings();
    _isDarkMode = settings['darkMode'] as bool? ?? true;
  }

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    final settings = _storageService.getSettings();
    settings['darkMode'] = _isDarkMode;
    _storageService.saveSettings(settings);
    notifyListeners();
  }
}
