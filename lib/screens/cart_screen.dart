import '../utils/cart_safe.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'address_screen.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

const Color kBrandGreen = Color(0xFF0C831F);
const Color kLightGreenBg = Color(0xFFEAF7EA);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const int deliveryFee = 50;
  static const int platformFee = 5;
  static const double freeDeliveryThreshold = 500;

  final TextEditingController _couponController = TextEditingController();
  String? _appliedCouponCode;
  double _discount = 0;
  String? _couponError;
  String? _applyingCode;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    final token = await ApiService.getToken();
    if (mounted) setState(() => _isLoggedIn = token != null);
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(double cartTotal) async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _couponError = 'Please enter a coupon code';
      });
      return;
    }
    if (cartTotal <= 0) {
      setState(() {
        _couponError = 'Add items to your cart before applying a coupon';
        _appliedCouponCode = null;
        _discount = 0;
      });
      return;
    }

    setState(() {
      _applyingCode = code;
      _couponError = null;
    });

    try {
      // Always validate against the backend (POST /coupons/validate) so
      // dynamic coupons created in the admin panel work, and so the
      // discount amount/eligibility rules can never be bypassed or go
      // stale by hardcoding them client-side.
      final result = await ApiService.validateCoupon(code, cartTotal);
      final discount = (result['discount_amount'] is num)
          ? (result['discount_amount'] as num).toDouble()
          : 0.0;
      if (!mounted) return;
      setState(() {
        _appliedCouponCode = (result['code'] ?? code).toString();
        _discount = discount;
        _couponError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon $_appliedCouponCode applied! You saved ${discount.toStringAsFixed(0)}',
          ),
          backgroundColor: kBrandGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _couponError = e.toString().replaceFirst('Exception: ', '');
        _appliedCouponCode = null;
        _discount = 0;
      });
    } finally {
      if (mounted) setState(() => _applyingCode = null);
    }
  }

  double? _lastCouponCartTotal;

  Future<void> _revalidateCoupon(double cartTotal) async {
    final code = _appliedCouponCode;
    if (code == null) return;
    try {
      final result = await ApiService.validateCoupon(code, cartTotal);
      if (!mounted) return;
      final d = (result['discount_amount'] is num)
          ? (result['discount_amount'] as num).toDouble()
          : 0.0;
      setState(() => _discount = d);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _appliedCouponCode = null;
        _discount = 0;
        _couponError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _discount = 0;
      _couponError = null;
      _couponController.clear();
    });
  }

  static const bool _kCouponsLocked = false;

  static const List<Map<String, dynamic>> _offers = [
    {'code': 'SAVE50', 'label': 'Save \u20B950 with SAVE50', 'minCart': 300.0},
    {
      'code': 'FLAT100',
      'label': 'Flat \u20B9100 off with FLAT100',
      'minCart': 600.0,
    },
    {'code': 'SAVE20', 'label': 'Save 20% with SAVE20', 'minCart': 400.0},
    {'code': 'NEW40', 'label': 'Save \u20B940 with NEW40', 'minCart': 250.0},
  ];

  Widget _buildManualCouponField(double cartTotal) {
    final applied = _appliedCouponCode != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                enabled: !applied && _applyingCode == null,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            applied
                ? TextButton(
                    onPressed: _removeCoupon,
                    child: const Text('Remove'),
                  )
                : ElevatedButton(
                    onPressed: _applyingCode != null
                        ? null
                        : () => _applyCoupon(cartTotal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: _applyingCode != null
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Apply'),
                  ),
          ],
        ),
        if (_couponError != null && !applied)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _couponError!,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildCouponsSection(double cartTotal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coupons & offers',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildManualCouponField(cartTotal),
          const SizedBox(height: 12),
          for (int i = 0; i < _offers.length; i++) ...[
            _buildOfferRow(_offers[i], cartTotal),
            if (i != _offers.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildOfferRow(Map<String, dynamic> offer, double cartTotal) {
    final String code = offer['code'] as String;
    final String label = offer['label'] as String;
    final double minCart = offer['minCart'] as double;
    final bool applied = _appliedCouponCode == code;
    final bool eligible = !_kCouponsLocked && cartTotal >= minCart;
    final double remaining = minCart - cartTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kLightGreenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_offer,
                color: kBrandGreen,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    applied
                        ? 'Coupon applied'
                        : eligible
                        ? 'Tap to apply'
                        : remaining > 0
                        ? 'Shop for ${remaining.toStringAsFixed(0)} more to apply'
                        : 'Currently unavailable',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: applied || eligible ? kBrandGreen : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            if (applied)
              TextButton(
                onPressed: _removeCoupon,
                child: Text(
                  'Remove',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (eligible)
              OutlinedButton(
                onPressed: _applyingCode != null
                    ? null
                    : () {
                        _couponController.text = code;
                        _applyCoupon(cartTotal);
                      },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kBrandGreen),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: _applyingCode == code
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Apply',
                        style: GoogleFonts.poppins(
                          color: kBrandGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Locked',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (applied && _couponError != null) ...[
          const SizedBox(height: 6),
          Text(
            _couponError!,
            style: GoogleFonts.poppins(color: Colors.red, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildCartImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        color: kLightGreenBg,
        child: const Icon(Icons.image_not_supported, color: kBrandGreen),
      );
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 60,
          height: 60,
          color: kLightGreenBg,
          child: const Icon(Icons.image_not_supported, color: kBrandGreen),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imagePath,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        width: 60,
        height: 60,
        color: kLightGreenBg,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, _, _) => Container(
        width: 60,
        height: 60,
        color: kLightGreenBg,
        child: const Icon(Icons.image_not_supported, color: kBrandGreen),
      ),
    );
  }

  Widget _billRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold
                  ? kBrandGreen
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _imageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http') || raw.startsWith('assets/')) return raw;
    final host = ApiService.baseUrl.replaceAll('/api/v1', '');
    return '$host$raw';
  }

  Widget _localItemRow(Map<String, dynamic> item) {
    final id = item['id'] as String;
    final name = (item['name'] ?? '').toString();
    final unit = [
      item['brand'],
      item['weight'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(' \u2022 ');
    final price = ((item['price'] as num?) ?? 0).round();
    final rawImage = (item['image'] ?? '').toString();
    final image = rawImage.startsWith('assets/')
        ? rawImage
        : _imageUrl(rawImage);
    final quantity = item['quantity'] ?? 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildCartImage(image),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '\u20B9$price',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: kBrandGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () =>
                      context.read<CartProvider>().safeDecrement(context, id),
                  child: const SizedBox(
                    width: 28,
                    height: 32,
                    child: Icon(Icons.remove, color: Colors.white, size: 16),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    try {
                      await context.read<CartProvider>().increment(id);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Color(0xFFF5C518),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF2D2D2D),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 80,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  child: const SizedBox(
                    width: 28,
                    height: 32,
                    child: Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartTotal = cart.cartTotal.round();
    if (_appliedCouponCode != null &&
        _lastCouponCartTotal != cartTotal.toDouble()) {
      _lastCouponCartTotal = cartTotal.toDouble();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revalidateCoupon(cartTotal.toDouble());
      });
    }
    final total = cartTotal + deliveryFee + platformFee;
    final remaining = freeDeliveryThreshold - cartTotal;
    final unlocked = remaining <= 0;
    final preDiscountTotal = unlocked ? cartTotal + platformFee : total;
    final grandTotal = (preDiscountTotal - _discount)
        .clamp(0, double.infinity)
        .round();
    final isCartEmpty = cart.items.isEmpty && cart.localCartItems.isEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          'My Cart (${cart.cartCount} items)',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: isCartEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Shop Now',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kLightGreenBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unlocked
                                ? 'Yay! Free delivery unlocked'
                                : 'Delivery in 10 minutes',
                            style: GoogleFonts.poppins(
                              color: kBrandGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (!unlocked) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Add items worth ${remaining.toStringAsFixed(0)} more to unlock FREE delivery',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCouponsSection(cartTotal.toDouble()),
                    ...cart.items.map((item) {
                      final product = item['product'] ?? {};
                      final productId = item['product_id'];
                      final name = (product['name'] ?? '').toString();
                      final price = (product['price'] is num)
                          ? (product['price'] as num).round()
                          : 0;
                      final unit = (product['description'] ?? '').toString();
                      final image = _imageUrl(product['image_url']?.toString());
                      final quantity = item['quantity'] ?? 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _buildCartImage(image),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    unit,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\u20B9$price',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: kBrandGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => context
                                        .read<CartProvider>()
                                        .safeDecrement(context, productId),
                                    child: const SizedBox(
                                      width: 28,
                                      height: 32,
                                      child: Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '$quantity',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      try {
                                        await context
                                            .read<CartProvider>()
                                            .increment(productId);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).hideCurrentSnackBar();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.shopping_bag_outlined,
                                                    color: Color(0xFFF5C518),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      e.toString().replaceFirst(
                                                        'Exception: ',
                                                        '',
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: const Color(
                                                0xFF2D2D2D,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: const EdgeInsets.only(
                                                left: 16,
                                                right: 16,
                                                bottom: 80,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const SizedBox(
                                      width: 28,
                                      height: 32,
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    ...cart.localCartItems.map((item) => _localItemRow(item)),
                    const Divider(height: 24),
                    Text(
                      'Bill details',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _billRow('Item Total', '\u20B9$cartTotal'),
                    _billRow(
                      'Delivery Fee',
                      unlocked ? 'FREE' : '\u20B9$deliveryFee',
                    ),
                    _billRow('Platform Fee', '\u20B9$platformFee'),
                    if (_discount > 0)
                      _billRow(
                        'Coupon Discount',
                        '-\u20B9${_discount.toStringAsFixed(0)}',
                      ),
                    const Divider(),
                    _billRow('Grand Total', '\u20B9$grandTotal', isBold: true),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Material(
                        color: kBrandGreen,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            if (!_isLoggedIn) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                              // Re-check in case the user logged in and came back.
                              await _checkLoginState();
                              if (!mounted || !context.mounted) return;
                              if (_isLoggedIn) {
                                await context
                                    .read<CartProvider>()
                                    .syncLocalCartToServer();
                              }
                              return;
                            }
                            final cartProv = context.read<CartProvider>();
                            if (cartProv.localCartItems.isNotEmpty) {
                              await cartProv.syncLocalCartToServer();
                              if (!mounted || !context.mounted) return;
                              if (cartProv.localCartItems.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Some items in your cart could not be added to your order. Please remove them and try again.',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }
                            final freshCartTotal = cartProv.cartTotal.round();
                            final freshPreDiscount =
                                (freshCartTotal >= freeDeliveryThreshold)
                                ? freshCartTotal + platformFee
                                : freshCartTotal + deliveryFee + platformFee;
                            final finalTotal = (freshPreDiscount - _discount)
                                .clamp(0, double.infinity)
                                .round();
                            final items = [
                              ...cart.items.map((item) {
                                final product = item['product'] ?? {};
                                return {
                                  'name': product['name'],
                                  'price': product['price'],
                                  'quantity': item['quantity'],
                                };
                              }),
                              ...cartProv.localCartItems.map(
                                (item) => {
                                  'name': item['name'],
                                  'price': item['price'],
                                  'quantity': item['quantity'],
                                },
                              ),
                            ];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddressScreen(
                                  items: items,
                                  totalAmount: finalTotal,
                                  couponCode: _appliedCouponCode,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            child: _isLoggedIn
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\u20B9$grandTotal',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Proceed to Address',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Login to proceed',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
          }
        },
        selectedItemColor: const Color(0xFF0C831F),
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
    );
  }
}
