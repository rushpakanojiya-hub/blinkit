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

const Color kBrandGreen = Color(0xFF0C831F);
const Color kLightGreenBg = Color(0xFFEAF7EA);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const int deliveryFee = 25;
  static const int platformFee = 5;
  static const double freeDeliveryThreshold = 299;

  final TextEditingController _couponController = TextEditingController();
  String? _appliedCouponCode;
  double _discount = 0;
  String? _couponError;
  bool _isValidatingCoupon = false;

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
      _isValidatingCoupon = true;
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
              'Coupon $_appliedCouponCode applied! You saved ${discount.toStringAsFixed(0)}'),
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
      if (mounted) setState(() => _isValidatingCoupon = false);
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

  Widget _buildCartImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
          width: 60, height: 60, color: kLightGreenBg,
          child: const Icon(Icons.image_not_supported, color: kBrandGreen));
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, width: 60, height: 60, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              width: 60, height: 60, color: kLightGreenBg,
              child: const Icon(Icons.image_not_supported, color: kBrandGreen)));
    }
    return CachedNetworkImage(
        imageUrl: imagePath, width: 60, height: 60, fit: BoxFit.cover,
        placeholder: (_, __) => Container(width: 60, height: 60, color: kLightGreenBg, child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
        errorWidget: (_, __, ___) => Container(
            width: 60, height: 60, color: kLightGreenBg,
            child: const Icon(Icons.image_not_supported, color: kBrandGreen)));
  }

  Widget _billRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Theme.of(context).colorScheme.onSurface : Colors.grey[600])),
          Text(value, style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? kBrandGreen : Theme.of(context).colorScheme.onSurface)),
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
    final unit = [item['brand'], item['weight']]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(' \u2022 ');
    final price = ((item['price'] as num?) ?? 0).round();
    final rawImage = (item['image'] ?? '').toString();
    final image = rawImage.startsWith('assets/') ? rawImage : _imageUrl(rawImage);
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
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                if (unit.isNotEmpty)
                  Text(unit, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text('$price', style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.bold)),
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
                  onTap: () => context.read<CartProvider>().decrement(id),
                  child: const SizedBox(width: 28, height: 32,
                      child: Icon(Icons.remove, color: Colors.white, size: 16)),
                ),
                SizedBox(
                  width: 24,
                  child: Text('$quantity', textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                InkWell(
                  onTap: () => context.read<CartProvider>().increment(id),
                  child: const SizedBox(width: 28, height: 32,
                      child: Icon(Icons.add, color: Colors.white, size: 16)),
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
    final total = cartTotal + deliveryFee + platformFee;
    final remaining = freeDeliveryThreshold - cartTotal;
    final unlocked = remaining <= 0;
    final preDiscountTotal = unlocked ? cartTotal + platformFee : total;
    final grandTotal = (preDiscountTotal - _discount).clamp(0, double.infinity).round();
    final isCartEmpty = cart.items.isEmpty && cart.localCartItems.isEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: Text('My Cart (${cart.cartCount} items)',
            style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: isCartEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Your cart is empty',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Shop Now',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      unlocked ? 'Yay! Free delivery unlocked' : 'Delivery in 10 minutes',
                      style: GoogleFonts.poppins(
                          color: kBrandGreen, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    if (!unlocked) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Add items worth ${remaining.toStringAsFixed(0)} more to unlock FREE delivery',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...cart.items.map((item) {
                final product = item['product'] ?? {};
                final productId = item['product_id'];
                final name = (product['name'] ?? '').toString();
                final price = (product['price'] is num) ? (product['price'] as num).round() : 0;
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
                            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(unit, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text('$price', style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.bold)),
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
                              onTap: () => context.read<CartProvider>().decrement(productId),
                              child: const SizedBox(width: 28, height: 32,
                                  child: Icon(Icons.remove, color: Colors.white, size: 16)),
                            ),
                            SizedBox(
                              width: 24,
                              child: Text('$quantity', textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            InkWell(
                              onTap: () => context.read<CartProvider>().increment(productId),
                              child: const SizedBox(width: 28, height: 32,
                                  child: Icon(Icons.add, color: Colors.white, size: 16)),
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
              Text('Apply Coupon', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              if (_appliedCouponCode == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.poppins(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Enter coupon code',
                          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kBrandGreen),
                          ),
                        ),
                        onSubmitted: (_) => _applyCoupon(cartTotal.toDouble()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: kBrandGreen,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _isValidatingCoupon
                            ? null
                            : () => _applyCoupon(cartTotal.toDouble()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          child: _isValidatingCoupon
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text('Apply',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    ),
                  ],
                ),
                if (_couponError != null) ...[
                  const SizedBox(height: 6),
                  Text(_couponError!,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
                ],
                const SizedBox(height: 6),
              ] else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kLightGreenBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBrandGreen.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer, color: kBrandGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            "'$_appliedCouponCode' applied - you saved ${_discount.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600, color: kBrandGreen)),
                      ),
                      InkWell(
                        onTap: _removeCoupon,
                        child: Text('Remove',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Text('Bill details', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              _billRow('Item Total', '$cartTotal'),
              _billRow('Delivery Fee', unlocked ? 'FREE' : '$deliveryFee'),
              _billRow('Platform Fee', '$platformFee'),
              if (_discount > 0)
                _billRow('Coupon Discount', '-${_discount.toStringAsFixed(0)}'),
              const Divider(),
              _billRow('Grand Total', '$grandTotal', isBold: true),
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
                    onTap: () {
                      final items = [
                        ...cart.items.map((item) {
                          final product = item['product'] ?? {};
                          return {
                            'name': product['name'],
                            'price': product['price'],
                            'quantity': item['quantity'],
                          };
                        }),
                        ...cart.localCartItems.map((item) => {
                              'name': item['name'],
                              'price': item['price'],
                              'quantity': item['quantity'],
                            }),
                      ];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddressScreen(
                            items: items,
                            totalAmount: grandTotal,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$grandTotal',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Row(
                            children: [
                              Text('Proceed to Address',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                            ],
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
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()));
              break;
            case 1:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()));
              break;
            case 2:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
              break;
          }
        },
        selectedItemColor: const Color(0xFF0C831F),
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
    );
  }
}
