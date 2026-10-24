import '../core/avatar/avatar_catalog.dart';
import '../providers/product_provider.dart';
import '../features/category_nav/repositories/category_repository.dart';
import '../features/address_book/presentation/providers/address_provider.dart';
import '../features/wishlist/presentation/providers/wishlist_provider.dart';
import '../features/gst_details/presentation/providers/gst_provider.dart';
import '../features/gift_cards/presentation/providers/gift_card_provider.dart';
import '../providers/referral_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/profile_provider.dart';
import 'login_screen.dart';
import 'settings/account_privacy_screen.dart';
import 'payment_settings_screen.dart';
import 'share/share_app_screen.dart';
import 'order_screen.dart';
import 'wallet/wallet_screen.dart';
import 'support/support_home_screen.dart';
import 'about/about_us_screen.dart';
import '../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../features/gst_details/presentation/screens/gst_list_screen.dart';
import 'categories_screen.dart';
import 'settings/notification_preferences_screen.dart';
import '../features/address_book/presentation/screens/address_list_screen.dart';
import '../features/gift_cards/presentation/screens/gift_cards_screen.dart';
import 'home_screen.dart';

const Color kGreen = Color(0xFF0C831F);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isGuest = false;
  bool _checkedGuest = false;
  String _loginPhone = '';

  @override
  void initState() {
    super.initState();
    _loadLoginPhone();
    _checkGuestStatus();
    // Make sure we have the latest saved profile (e.g. after returning from
    // Edit profile on a previous visit, or first load in this session).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().load();
    });
  }

  Future<void> _loadLoginPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString('user_phone') ?? '';
    if (mounted) setState(() => _loginPhone = p);
  }

  Future<void> _checkGuestStatus() async {
    final token = await ApiService.getToken();
    final skipped = await ApiService.getSkippedLogin();
    debugPrint(
      'GUEST CHECK: hasToken=${token != null && token.isNotEmpty} | skipped=$skipped',
    );
    if (mounted) {
      setState(() {
        _isGuest = token == null || token.isEmpty;
        _checkedGuest = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final name = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name
        : 'User';
    final phone = _loginPhone;

    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                !_checkedGuest
                    ? const SizedBox(height: 220)
                    : (_isGuest
                          ? _buildGuestHeader(scheme)
                          : _buildHeader(
                              scheme,
                              name,
                              phone,
                              profile?.avatarId,
                            )),
                const SizedBox(height: 16),
                _buildQuickActions(scheme),
                const SizedBox(height: 20),
                _buildSectionLabel('Your information', scheme),
                _buildSectionCard(scheme, [
                  _tile(Icons.favorite_border, 'Your wishlist', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WishlistScreen()),
                    );
                  }, scheme),
                  _tile(
                    Icons.notifications_outlined,
                    'Notification preferences',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPreferencesScreen(),
                        ),
                      );
                    },
                    scheme,
                  ),
                  _tile(Icons.location_on_outlined, 'Saved addresses', () {
                    _guarded(
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddressListScreen(),
                        ),
                      ),
                    );
                  }, scheme),
                  _tile(Icons.card_giftcard_outlined, 'Gift cards', () {
                    _guarded(
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GiftCardsScreen(),
                        ),
                      ),
                    );
                  }, scheme),
                  _tile(
                    Icons.description_outlined,
                    'GST details',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GstListScreen(),
                        ),
                      );
                    },
                    scheme,
                    isLast: true,
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionLabel('Payment and coupons', scheme),
                _buildSectionCard(scheme, [
                  _tile(
                    Icons.account_balance_wallet_outlined,
                    'GoFresh Money',
                    () {
                      if (_isGuest) {
                        _goLogin();
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WalletScreen()),
                      );
                    },
                    scheme,
                  ),
                  _tile(
                    Icons.credit_card_outlined,
                    'Payment settings',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymentSettingsScreen(),
                        ),
                      );
                    },
                    scheme,
                    isLast: true,
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionLabel('Other information', scheme),
                _buildSectionCard(scheme, [
                  _tile(Icons.ios_share_outlined, 'Share the app', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShareAppScreen()),
                    );
                  }, scheme),
                  _tile(Icons.info_outline, 'About us', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                    );
                  }, scheme),
                  _tile(
                    Icons.lock_outline,
                    'Account privacy',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountPrivacyScreen(),
                        ),
                      );
                    },
                    scheme,
                    isLast: _isGuest,
                  ),
                  if (!_isGuest)
                    _tile(
                      Icons.logout,
                      'Log out',
                      _confirmLogout,
                      scheme,
                      isLast: true,
                    ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
                break;
              case 2:
                break;
            }
          },
          selectedItemColor: kGreen,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.category),
              label: 'Categories',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  // ---------- Header ----------

  Widget _buildGuestHeader(ColorScheme scheme) {
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
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 42,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: 44,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your account',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Log in to view your complete profile',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: kGreen,
                side: const BorderSide(color: kGreen),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ColorScheme scheme,
    String name,
    String phone,
    String? avatarId,
  ) {
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
          CircleAvatar(
            radius: 42,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(Icons.person, size: 44, color: scheme.onSurface),
          ),
          const SizedBox(height: 12),
          if (phone.isNotEmpty)
            Text(
              '+91 $phone',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderScreen()),
              );
            }, scheme),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickAction(
              Icons.account_balance_wallet_outlined,
              'GoFresh Money',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
              scheme,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickAction(Icons.headset_mic_outlined, 'Need help?', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportHomeScreen()),
              );
            }, scheme),
          ),
        ],
      ),
    );
  }

  void _goLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _guarded(VoidCallback action) {
    if (_isGuest) {
      _goLogin();
    } else {
      action();
    }
  }

  Widget _quickAction(
    IconData icon,
    String label,
    VoidCallback onTap,
    ColorScheme scheme,
  ) {
    return InkWell(
      onTap: () => _guarded(onTap),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: kGreen, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
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
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
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

  Widget _tile(
    IconData icon,
    String title,
    VoidCallback onTap,
    ColorScheme scheme, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: scheme.onSurface),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: scheme.outlineVariant,
          ),
      ],
    );
  }

  // ---------- Actions ----------

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.clearToken();
              await PushNotificationService.unregisterDevice();
              final prefs = await SharedPreferences.getInstance();
              // Only clear profile-specific keys, not the whole prefs
              // store (that previously wiped unrelated settings). This
              // profile data is keyed globally, not per-phone-number, so
              // it must be cleared on logout or the next person to log
              // in on this device sees the previous user's saved name
              // and avatar.
              await prefs.remove('user_profile_json');
              await ApiService.clearUserData();
              if (context.mounted) {
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
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
