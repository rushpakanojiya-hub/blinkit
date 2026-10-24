import 'package:flutter/material.dart';
import '../../data/repositories/settings_repository.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsRepository _repo = SettingsRepository();
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  String get label {
    switch (_mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Future<void> load() async {
    final saved = await _repo.fetchThemeMode();
    _mode = _fromString(saved);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _repo.saveThemeMode(_toString(mode));
  }

  ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
