import 'package:flutter/material.dart';
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

  late Razorpay _razorpay;
  bool _isPaying = false;

  Map<String, dynamic>? _tracking;
  bool _isLoadingTracking = true;
  bool _isGeneratingInvoice = false;

  @override
  void initState() {
    super.initState();
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
  }

  Future<void> _loadTracking() async {
    setState(() => _isLoadingTracking = true);
    try {
      final orderId = int.tryParse(widget.order.id);
      if (orderId == null) throw Exception('Invalid order id');
      final data = await ApiService.getOrderTracking(orderId);
      setState(() {
        _tracking = data['tracking'] as Map<String, dynamic>?;
      });
    } catch (e) {
      setState(() => _tracking = null);
    } finally {
      if (mounted) setState(() => _isLoadingTracking = false);
    }
  }

  void _countdown() {
    if (!mounted) return;
    if (_minutes > 0) {
      setState(() => _minutes--);
      Future.delayed(const Duration(minutes: 1), _countdown);
    }
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
      final orderId = int.tryParse(widget.order.id);
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
      final orderId = int.tryParse(widget.order.id);
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
        'description': 'Order #${widget.order.id}',
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
        order: widget.order,
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
    _pulseController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final partnerName = _tracking?['delivery_partner_name']?.toString();
    final hasPartner = _tracking != null && partnerName != null && partnerName.isNotEmpty;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.error_outline, color: Colors.redAccent),
            onPressed: () {},
          ),
        ],
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
                  ),
                  const SizedBox(height: 12),
                  Text(order.statusLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildProgressSteps(),
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
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.image.startsWith('assets/')
                              ? Image.asset(item.image,
                              width: 44, height: 44, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 44, height: 44,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey, size: 20)))
                              : CachedNetworkImage(imageUrl: item.image,
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
                  )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (hasPartner)
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

            if (hasPartner) const SizedBox(height: 16),

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
              child: _isLoadingTracking
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
                      : Row(
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
            ),

            const SizedBox(height: 16),

            if (order.paymentMethod == 'online' && order.paymentStatus == 'pending')
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

  Widget _buildProgressSteps() {
    final steps = widget.order.timeline;
    final currentStep = steps.lastIndexWhere((s) => s.completed);

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep;
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
