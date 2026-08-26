import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../providers/settings_provider.dart';
import '../providers/profile_provider.dart';
import '../core/avatar/avatar_catalog.dart';
import 'login_screen.dart';
import 'profile/edit_profile_screen.dart';
import 'settings/notification_preferences_screen.dart';
import 'notifications/notification_list_screen.dart';
import 'settings/account_privacy_screen.dart';
import 'share/share_app_screen.dart';
import 'order_screen.dart';
import 'wallet/wallet_screen.dart';
import 'support/support_home_screen.dart';
import 'about/about_us_screen.dart';
import '../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../features/gst_details/presentation/screens/gst_list_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';

const Color kGreen = Color(0xFF0C831F);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Make sure we have the latest saved profile (e.g. after returning from
    // Edit profile on a previous visit, or first load in this session).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final name = (profile?.name.trim().isNotEmpty ?? false) ? profile!.name : 'User';
    final phone = profile?.phone ?? '';
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      },
      child: Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(scheme, name, phone, profile?.avatarId),
              const SizedBox(height: 16),
              _buildQuickActions(scheme),
              const SizedBox(height: 16),
              _buildSettingsCard(settings, scheme),
              const SizedBox(height: 20),
              _buildSectionLabel('Your information', scheme),
              _buildSectionCard(scheme, [
                _tile(Icons.favorite_border, 'Your wishlist', () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const WishlistScreen()));
                }, scheme),
                _tile(Icons.description_outlined, 'GST details', () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GstListScreen()));
                }, scheme, isLast: true),
              ]),
              const SizedBox(height: 20),
              _buildSectionLabel('Payment and coupons', scheme),
              _buildSectionCard(scheme, [
                _tile(Icons.account_balance_wallet_outlined, 'GoFresh Money', () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const WalletScreen()));
                }, scheme),
                _tile(Icons.credit_card_outlined, 'Payment settings',
                    () => _showComingSoon('Payment settings'), scheme, isLast: true),
              ]),
              const SizedBox(height: 20),
              _buildSectionLabel('Other information', scheme),
              _buildSectionCard(scheme, [
                _tile(Icons.ios_share_outlined, 'Share the app', () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ShareAppScreen()));
                }, scheme),
                _tile(Icons.info_outline, 'About us', () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AboutUsScreen()));
                }, scheme),
                _tile(Icons.lock_outline, 'Account privacy', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AccountPrivacyScreen()));
                }, scheme),
                _tile(Icons.notifications_active_outlined,
                    'Notifications', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationListScreen()));
                }, scheme),
                _tile(Icons.notifications_none_outlined,
                    'Notification preferences', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationPreferencesScreen()));
                }, scheme),
                _tile(Icons.logout, 'Log out', _confirmLogout, scheme, isLast: true),
              ]),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.popUntil(context, (route) => route.isFirst);
              break;
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()));
              break;
            case 2:
              break;
          }
        },
        selectedItemColor: kGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      ),
    );
  }

  // ---------- Header ----------

  Widget _buildHeader(ColorScheme scheme, String name, String phone, String? avatarId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.primaryContainer, scheme.surface],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: scheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
            child: AvatarDisplay(
              avatarId: avatarId,
              fallbackName: name,
              radius: 42,
            ),
          ),
          const SizedBox(height: 12),
          Text('Your account',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold, color: scheme.onSurface)),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('+91 $phone',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.6))),
          ],
        ],
      ),
    );
  }

  // ---------- Quick actions ----------

  Widget _buildQuickActions(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _quickAction(Icons.shopping_bag_outlined, 'Your orders', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OrderScreen()));
            }, scheme),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickAction(Icons.account_balance_wallet_outlined,
                'GoFresh Money', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()));
            }, scheme),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickAction(Icons.headset_mic_outlined, 'Need help?', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SupportHomeScreen()));
            }, scheme),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap, ColorScheme scheme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: kGreen, size: 24),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }

  // ---------- Settings ----------

  Widget _buildSettingsCard(SettingsProvider settings, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            SwitchListTile(
              value: settings.hideSensitive,
              activeThumbColor: kGreen,
              onChanged: (val) {
                context.read<SettingsProvider>().setHideSensitive(val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(val
                        ? 'Sensitive items hidden'
                        : 'Sensitive items visible'),
                    backgroundColor: kGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              secondary: Icon(Icons.visibility_off_outlined, color: scheme.onSurface),
              title: Text('Hide sensitive items',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface)),
              subtitle: Text('Hide sensitive products from recommendations and search',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.6))),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Generic section helpers ----------

  Widget _buildSectionLabel(String title, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface)),
      ),
    );
  }

  Widget _buildSectionCard(ColorScheme scheme, List<Widget> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: tiles),
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap, ColorScheme scheme,
      {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: scheme.onSurface),
          title: Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface)),
          trailing: Icon(Icons.chevron_right, color: scheme.onSurface.withValues(alpha: 0.5)),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(height: 1, indent: 16, endIndent: 16, color: scheme.outlineVariant),
      ],
    );
  }

  // ---------- Actions ----------

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon',
            style: GoogleFonts.poppins()),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
              onPressed: () async {
                await ApiService.clearToken();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  context.read<SettingsProvider>().clear();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Logout', style: GoogleFonts.poppins(color: Colors.white))),
        ],
      ),
    );
  }
}
