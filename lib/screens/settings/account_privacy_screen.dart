import '../../providers/product_provider.dart';
import '../../features/category_nav/repositories/category_repository.dart';
import '../../features/address_book/presentation/providers/address_provider.dart';
import '../../features/wishlist/presentation/providers/wishlist_provider.dart';
import '../../features/gst_details/presentation/providers/gst_provider.dart';
import '../../features/gift_cards/presentation/providers/gift_card_provider.dart';
import '../../providers/referral_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/confirm_dialog.dart';
import '../../services/api_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../login_screen.dart';

const Color kGreen = Color(0xFF0C831F);

class AccountPrivacyScreen extends StatelessWidget {
  const AccountPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Account privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete account',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text('This action is permanent'),
              onTap: () async {
                final tok = await ApiService.getToken();
                if (tok == null || tok.isEmpty) {
                  if (!context.mounted) return;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  return;
                }
                if (!context.mounted) return;
                final ok = await ConfirmDialog.show(
                  context,
                  title: 'Delete account',
                  message:
                      'This will permanently delete your account and all associated data. This cannot be undone.',
                  confirmLabel: 'Delete',
                  confirmColor: Colors.red,
                );
                if (!ok || !context.mounted) return;
                try {
                  await ApiService.deleteAccount();
                  await ApiService.clearToken();
                  await PushNotificationService.unregisterDevice();
                  await ApiService.clearUserData();
                  final sp = await SharedPreferences.getInstance();
                  await sp.remove('notification_prefs_json');
                  await sp.remove('hide_sensitive');
                  // prefs.clear() removed -- was wiping saved profile name on logout
                  if (!context.mounted) return;
                  context.read<SettingsProvider>().clear();
                  context.read<CartProvider>().clearCartLocal();
                  context.read<OrderProvider>().clearAll();
                  context.read<WalletProvider>().clear();
                  context.read<AddressProvider>().clear();
                  CategoryRepository.clearLocation();
                  context.read<ProductProvider>().clear();
                  context.read<WishlistProvider>().clear();
                  context.read<ProfileProvider>().clear();
                  context.read<GstProvider>().clear();
                  context.read<GiftCardProvider>().clear();
                  context.read<ReferralProvider>().clear();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed to delete account: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
