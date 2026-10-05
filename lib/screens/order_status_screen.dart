import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/delivery_rating_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../providers/profile_provider.dart';
import '../utils/invoice_generator.dart';
import 'support/support_home_screen.dart';
import 'orders/request_return_screen.dart';
import '../widgets/complaint_window_card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/mini_tracking_map.dart';
import 'tracking_map_screen.dart';
import '../services/partner_poll.dart';

class OrderStatusScreen extends StatefulWidget {
  final Order order;

  const OrderStatusScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _minutes = 10;
  Timer? _pollTimer;

  late Razorpay _razorpay;
  bool _isPaying = false;

  Map<String, dynamic>? _tracking;
  bool _isLoadingTracking = true;
  bool _isGeneratingInvoice = false;
  late Order _order;
  Map<String, dynamic>? _myReturn;
  bool? _windowOpen; // null until the return/complaint window is known

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    Future.delayed(const Duration(seconds: 1), _countdown);

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadTracking();
    _loadReturnStatus();
    // Poll so a delivery partner accepting the order (or a new one being
    // assigned after a rejection) shows up without the customer having to
    // leave and re-open this screen.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadTracking();
        _refreshOrderStatus();
      }
    });
  }

  Future<void> _refreshOrderStatus() async {
    try {
      final orderId = int.tryParse(_order.id);
      if (orderId == null) return;
      final raw = await ApiService.getOrder(orderId);
      final updated = Order.fromJson(raw);
      if (mounted && updated.rawStatus != _order.rawStatus) {
        setState(() => _order = updated);
      }
    } catch (_) {
      // ignore transient errors, keep last known state
    }
  }

  Future<void> _loadReturnStatus() async {
    try {
      final returns = await ApiService.getMyReturns();
      Map<String, dynamic>? match;
      for (final r in returns) {
        final m = r as Map<String, dynamic>;
        if (m['order_id']?.toString() == _order.id) {
          match = m;
          break;
        }
      }
      if (mounted) setState(() => _myReturn = match);
    } catch (_) {
      // ignore; button just won't be hidden if this fails
    }
  }

  String _returnSummary() {
    final r = _myReturn;
    if (r == null) return '';
    final reason = r['reason']?.toString() ?? '-';
    final status = r['status']?.toString() ?? '-';
    return 'Reason: $reason - Status: $status';
  }

  Future<void> _loadTracking() async {
    if (mounted && _tracking == null) setState(() => _isLoadingTracking = true);
    try {
      final orderId = int.tryParse(_order.id);
      if (orderId == null) throw Exception('Invalid order id');
      final data = await ApiService.getOrderTracking(orderId);
      setState(() {
        _tracking = data['tracking'] as Map<String, dynamic>?;
      });
    } catch (e) {
      if (mounted && _tracking == null) setState(() => _tracking = null);
    } finally {
      if (mounted) setState(() => _isLoadingTracking = false);
    }
  }

  bool _isPartnerAccepted() {
    final partnerName = _tracking?['delivery_partner_name']?.toString();
    final deliveryStatus = _tracking?['delivery_status']?.toString();
    final hasPartner = _tracking != null && partnerName != null && partnerName.isNotEmpty;
    return hasPartner && deliveryStatus != null && deliveryStatus != 'assigned';
  }

  void _countdown() {
    if (!mounted) return;
    // Don't start ticking down the ETA until the order has actually been
    // confirmed - while it's still 'pending' there's no confirmed delivery
    // window yet, so the countdown just re-checks every second without
    // decrementing.
    if (_order.rawStatus == 'pending' || !_isPartnerAccepted()) {
      Future.delayed(const Duration(seconds: 1), _countdown);
      return;
    }
    if (_minutes > 0) {
      setState(() => _minutes--);
      Future.delayed(const Duration(minutes: 1), _countdown);
    }
  }

  // Product images can come back from the backend as a relative path
  // (e.g. "/uploads/carrot.jpg") rather than a full URL. Without prefixing
  // the API host, CachedNetworkImage silently fails to load them and we
  // fall back to the "no image" placeholder - which is why some items
  // (like Carrot/Cucumber) showed no image while others did.
  String _imageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http') || raw.startsWith('assets/')) return raw;
    final host = ApiService.baseUrl.replaceAll('/api/v1', '');
    return '$host$raw';
  }

  Future<void> _callDeliveryPartner() async {
    final phone = _tracking?['phone']?.toString();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Phone number not available', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not start call', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final orderId = int.tryParse(_order.id);
      if (orderId == null) throw Exception('Invalid order id');
      await ApiService.verifyPayment(
        orderId: orderId,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment Successful! \u{1F389}', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error confirming payment', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) setState(() => _isPaying = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment Failed: ${response.message}', style: GoogleFonts.poppins()),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) setState(() => _isPaying = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('External Wallet: ${response.walletName}', style: GoogleFonts.poppins()),
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _startPayNow() async {
    setState(() => _isPaying = true);
    try {
      final orderId = int.tryParse(_order.id);
      if (orderId == null) throw Exception('Invalid order id');

      final orderData = await ApiService.createPaymentOrder(orderId);
      if (orderData['key_id'] == null || orderData['razorpay_order_id'] == null) {
        throw Exception(orderData['error']?.toString() ?? 'Could not start payment');
      }

      var options = {
        'key': orderData['key_id'],
        'amount': orderData['amount'],
        'name': 'Mepto',
        'order_id': orderData['razorpay_order_id'],
        'description': 'Order #${_order.id}',
        'prefill': {
          'contact': '9999999999',
          'email': 'test@mepto.com',
        },
        'method': {'upi': true, 'card': true, 'netbanking': true, 'wallet': true},
        'theme': {'color': '#D4A574'},
      };
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isPaying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error initiating payment', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _downloadInvoice() async {
    if (_isGeneratingInvoice) return;
    setState(() => _isGeneratingInvoice = true);
    try {
      final profile = context.read<ProfileProvider>().profile;
      final customerName = (profile?.name.trim().isNotEmpty ?? false)
          ? profile!.name
          : 'Customer';
      await InvoiceGenerator.downloadInvoice(
        order: _order,
        customerName: customerName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save invoice: ${e.toString().replaceFirst('Exception: ', '')}', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingInvoice = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final partnerName = _tracking?['delivery_partner_name']?.toString();
    final hasPartner = _tracking != null && partnerName != null && partnerName.isNotEmpty;
    // Partner has only ACCEPTED the delivery once delivery_status moves past
    // 'assigned'. Before that, an offer is pending and must not be shown to
    // the customer as an active/on-the-way delivery.
    final partnerAccepted = _isPartnerAccepted();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Order Status',
            style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.rawStatus == 'delivered')
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text('Delivered',
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    )
                  else if (order.rawStatus == 'cancelled')
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text('Cancelled',
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ],
                    )
                  else if (partnerAccepted)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Arriving in',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.grey)),
                            Text('$_minutes mins',
                                style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2196F3))),
                          ],
                        ),
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Early',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Waiting for delivery partner to accept your order...',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey))),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text(order.rawStatus == 'cancelled' ? 'Cancelled' : (partnerAccepted ? order.statusLabel : 'Order Placed'),
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildProgressSteps(partnerAccepted),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08), blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C831F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined,
                            color: Color(0xFF0C831F)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${order.items.length} Item(s)',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Order #${order.id}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ...order.items.map((item) {
                    final image = _imageUrl(item.image);
                    return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: image.isEmpty
                              ? Container(
                                  width: 44, height: 44,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey, size: 20))
                              : image.startsWith('assets/')
                              ? Image.asset(image,
                              width: 44, height: 44, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 44, height: 44,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey, size: 20)))
                              : CachedNetworkImage(imageUrl: image,
                              width: 44, height: 44, fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
                              errorWidget: (_, __, ___) => Container(
                                  width: 44, height: 44,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey, size: 20))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text(item.unit,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('x${item.quantity}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey)),
                            Text('\u20B9${item.price * item.quantity}',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0C831F))),
                          ],
                        ),
                      ],
                    ),
                  );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (partnerAccepted && order.rawStatus != 'delivered')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Text(
                  'Your delivery partner is on the way with your order',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.brown[700]),
                ),
              ),

            if (partnerAccepted && order.rawStatus != 'delivered') const SizedBox(height: 16),

            if (order.rawStatus != 'delivered')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08), blurRadius: 8)
                ],
              ),
              child: order.rawStatus == 'cancelled'
                  ? Text('This order was cancelled.',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey))
                  : _isLoadingTracking
                      ? Row(
                      children: [
                        const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text('Loading delivery partner...',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                      ],
                    )
                  : !hasPartner
                      ? Text('No delivery partner assigned yet.',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey))
                      : !partnerAccepted
                          ? Row(
                              children: [
                                const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2)),
                                const SizedBox(width: 12),
                                Expanded(child: Text('Waiting for delivery partner to accept...',
                                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey))),
                              ],
                            )
                          : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                              radius: 24,
                              backgroundColor:
                              const Color(0xFF0C831F).withValues(alpha: 0.2),
                              child: const Icon(Icons.delivery_dining,
                                  color: Color(0xFF0C831F), size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Delivery Partner',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11, color: Colors.grey)),
                                  Text(partnerName,
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                                IconButton(
                                  onPressed: _callDeliveryPartner,
                                  icon: const Icon(Icons.phone, color: Color(0xFF0C831F)),
                                ),
                              ],
                            ),
                            if (_tracking?['current_lat'] != null &&
                                _tracking?['current_lng'] != null &&
                                _tracking?['address_lat'] != null &&
                                _tracking?['address_lng'] != null) ...[
                              const SizedBox(height: 12),
                              MiniTrackingMap(
                                destination: LatLng(
                                  (_tracking!['address_lat'] as num).toDouble(),
                                  (_tracking!['address_lng'] as num).toDouble(),
                                ),
                                partner: LatLng(
                                  (_tracking!['current_lat'] as num).toDouble(),
                                  (_tracking!['current_lng'] as num).toDouble(),
                                ),
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => TrackingMapScreen(
                                    title: 'Track your order',
                                    destination: LatLng(
                                      (_tracking!['address_lat'] as num).toDouble(),
                                      (_tracking!['address_lng'] as num).toDouble(),
                                    ),
                                    partnerStream: pollPartner(
                                        () => ApiService.getOrderTracking(int.parse(order.id))),
                                    bottom: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: ElevatedButton.icon(
                                        onPressed: _callDeliveryPartner,
                                        icon: const Icon(Icons.phone),
                                        label: const Text('Call partner'),
                                      ),
                                    ),
                                  ),
                                )),
                              ),
                            ],
                          ],
                        ),
            ),

            const SizedBox(height: 16),

            if (order.paymentMethod == 'online' && order.paymentStatus == 'pending' && order.rawStatus != 'cancelled')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pink.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'You can pay online now while we deliver your order',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('To Pay:',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey)),
                            Text(
                                '\u20B9${order.grandTotal}',
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _isPaying ? null : _startPayNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: _isPaying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text('Pay Online',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            if (order.paymentMethod == 'online' && order.paymentStatus == 'pending') const SizedBox(height: 16),

            if (order.paymentStatus == 'paid' || order.paymentMethod == 'cod')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.08), blurRadius: 8)
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C831F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_outlined,
                          color: Color(0xFF0C831F)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tax Invoice',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Payment successful \u2022 download your bill',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isGeneratingInvoice ? null : _downloadInvoice,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0C831F),
                        side: const BorderSide(color: Color(0xFF0C831F)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isGeneratingInvoice
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download, size: 16),
                      label: Text('Download',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

            if (order.paymentStatus == 'paid' || order.paymentMethod == 'cod') const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08), blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bill Details',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  _billRow('Item Total', order.itemTotal),
                  const SizedBox(height: 6),
                  _billRow('Handling charge', order.platformFee),
                  const SizedBox(height: 6),
                  _billRow('Delivery charges', order.deliveryFee),
                  if (order.discount > 0) ...[
                    const SizedBox(height: 6),
                    _billRow('Discount', -order.discount, isDiscount: true),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bill Total',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('\u20B9${order.grandTotal}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 28),
                  Text('Order Details',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  _orderDetailRow('Order id', 'Order #${order.id}'),
                  const SizedBox(height: 10),
                  _orderDetailRow(
                      'Payment',
                      order.paymentMethod == 'cod'
                          ? 'Cash on Delivery'
                          : (order.paymentStatus == 'paid'
                              ? 'Paid Online'
                              : 'Online (Pending)')),
                  const SizedBox(height: 10),
                  _orderDetailRow('Deliver to',
                      order.address.isEmpty ? 'N/A' : order.address),
                  const SizedBox(height: 10),
                  _orderDetailRow('Order placed', _formatOrderDate(order.date)),
                  if (order.deliveredAt != null) ...[
                    const SizedBox(height: 10),
                    _orderDetailRow('Order delivered', _formatOrderDate(order.deliveredAt!)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            ComplaintWindowCard(
              orderId: order.id,
              onLoaded: (open) {
                if (mounted) setState(() => _windowOpen = open);
              },
            ),
            if (order.rawStatus == 'delivered' && _windowOpen != false)
              const SizedBox(height: 12),
            if (order.rawStatus == 'delivered' && _myReturn == null && _windowOpen != false)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final result = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => RequestReturnScreen(order: order)));
                  if (result == true && mounted) {
                    _loadReturnStatus();
                    _refreshOrderStatus();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.08), blurRadius: 8)
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C831F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_return_outlined,
                            color: Color(0xFF0C831F)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Request Return',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Not happy with an item? Start a return',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            if (order.rawStatus == 'delivered' && _myReturn != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.08), blurRadius: 8)
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.assignment_return_outlined,
                          color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Return requested',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(_returnSummary(),
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (order.rawStatus == 'delivered') const SizedBox(height: 16),
            if (order.rawStatus == 'delivered') ...[DeliveryRatingCard(orderId: order.id, autoPrompt: true), const SizedBox(height: 16)],

            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SupportHomeScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need help with this order?',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Find your issue or reach out via chat',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, int amount, {bool isDiscount = false}) {
    final sign = amount < 0 ? '-' : '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
        Text('$sign\u20B9${amount.abs()}',
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDiscount ? Colors.green : Colors.black87)),
      ],
    );
  }

  Widget _orderDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  String _formatOrderDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[date.month - 1];
    final year = (date.year % 100).toString().padLeft(2, '0');
    var hour12 = date.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return "${date.day} $month'$year, $hour12:$minute $period";
  }

  Widget _buildProgressSteps(bool partnerAccepted) {
    final steps = _order.timeline;
    var currentStep = steps.lastIndexWhere((s) => s.completed);

    // The granular delivery_status (picked_up/out_for_delivery/
    // arrived_at_customer/delivered) from the tracking endpoint is the
    // real source of truth for delivery progress - order.status often
    // lags behind it (stays 'confirmed' until the warehouse explicitly
    // marks it shipped). So bump the stepper forward using it, on top
    // of whatever order.status-derived step we already have.
    final deliveryStatus = _tracking?['delivery_status']?.toString();
    if (deliveryStatus != null) {
      const outForDeliveryStatuses = {
        'picked_up',
        'out_for_delivery',
        'arrived_at_customer',
      };
      if (deliveryStatus == 'delivered' && _order.rawStatus == 'delivered') {
        final idx = steps.indexWhere((s) => s.title == 'Delivered');
        if (idx != -1 && idx > currentStep) currentStep = idx;
      } else if (outForDeliveryStatuses.contains(deliveryStatus) || deliveryStatus == 'delivered') {
        final idx = steps.indexWhere((s) => s.title == 'Out for delivery');
        if (idx != -1 && idx > currentStep) currentStep = idx;
      }
    }

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep && (index == 0 || partnerAccepted);
        final isLast = index == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF2196F3)
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(steps[index].title,
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: isCompleted
                                ? const Color(0xFF2196F3)
                                : Colors.grey),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: index < currentStep
                        ? const Color(0xFF2196F3)
                        : Colors.grey[300],
                    margin: const EdgeInsets.only(bottom: 20),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}


