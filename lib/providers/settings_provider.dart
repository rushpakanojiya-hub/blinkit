import 'package:flutter/material.dart';
import '../data/models/notification_prefs_model.dart';
import '../data/repositories/settings_repository.dart';
import '../services/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repo = SettingsRepository();

  bool hideSensitive = false;
  NotificationPrefsModel notificationPrefs = NotificationPrefsModel(
    orders: true,
    offers: true,
    wallet: true,
    recommendations: false,
    updates: true,
  );

  Future<void> load() async {
    hideSensitive = await _repo.fetchHideSensitive();
    notificationPrefs = await _repo.fetchNotificationPrefs();
    try {
      final tok = await ApiService.getToken();
      if (tok != null && tok.isNotEmpty) {
        final remote = await ApiService.getNotificationPrefs();
        notificationPrefs = NotificationPrefsModel.fromJson(remote);
        await _repo.saveNotificationPrefs(notificationPrefs);
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setHideSensitive(bool value) async {
    hideSensitive = value;
    notifyListeners();
    await _repo.saveHideSensitive(value);
  }

  Future<void> updateNotificationPref(String key, bool value) async {
    notificationPrefs = NotificationPrefsModel(
      orders: key == 'orders' ? value : notificationPrefs.orders,
      offers: key == 'offers' ? value : notificationPrefs.offers,
      wallet: key == 'wallet' ? value : notificationPrefs.wallet,
      recommendations:
          key == 'recommendations' ? value : notificationPrefs.recommendations,
      updates: key == 'updates' ? value : notificationPrefs.updates,
    );
    notifyListeners();
    await _repo.saveNotificationPrefs(notificationPrefs);
    try {
      await ApiService.updateNotificationPrefs({key: value});
    } catch (_) {}
  }

  /// Clears in-memory provider state on logout.
  void clear() {
    hideSensitive = false;
    notificationPrefs = NotificationPrefsModel(
      orders: true,
      offers: true,
      wallet: true,
      recommendations: false,
      updates: true,
    );
    notifyListeners();
  }
}
