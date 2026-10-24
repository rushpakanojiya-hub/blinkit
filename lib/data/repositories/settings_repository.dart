import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_prefs_model.dart';

class SettingsRepository {
  static const _notifKey = 'notification_prefs_json';
  static const _hideSensitiveKey = 'hide_sensitive';
  static const _themeKey = 'app_theme_mode';

  Future<NotificationPrefsModel> fetchNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_notifKey);
    if (saved != null) {
      return NotificationPrefsModel.fromJson(jsonDecode(saved));
    }
    final raw =
        await rootBundle.loadString('assets/data/notification_prefs.json');
    return NotificationPrefsModel.fromJson(jsonDecode(raw));
  }

  Future<void> saveNotificationPrefs(NotificationPrefsModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notifKey, jsonEncode(model.toJson()));
  }

  Future<bool> fetchHideSensitive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideSensitiveKey) ?? false;
  }

  Future<void> saveHideSensitive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideSensitiveKey, value);
  }

  Future<String> fetchThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'light';
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode);
  }
}
