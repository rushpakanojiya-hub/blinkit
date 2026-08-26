import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

const Color kGreen = Color(0xFF0C831F);

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final prefs = settings.notificationPrefs;

    Widget row(String label, String key, bool value) {
      return SwitchListTile(
        value: value,
        activeThumbColor: kGreen,
        title: Text(label),
        onChanged: (v) => context.read<SettingsProvider>()
            .updateNotificationPref(key, v),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: const Text('Notification preferences')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          row('Orders', 'orders', prefs.orders),
          row('Offers', 'offers', prefs.offers),
          row('Wallet', 'wallet', prefs.wallet),
          row('Recommendations', 'recommendations', prefs.recommendations),
          row('Updates', 'updates', prefs.updates),
        ],
      ),
    );
  }
}
