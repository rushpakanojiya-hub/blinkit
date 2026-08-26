import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/order_model.dart';
import '../../widgets/state_views.dart';
import '../../utils/invoice_generator.dart';
import 'request_return_screen.dart';

const Color kGreen = Color(0xFF0C831F);

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});
  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;
  bool _isGeneratingInvoice = false;

  Future<void> _downloadInvoice(Order order) async {
    if (_isGeneratingInvoice) return;
    setState(() => _isGeneratingInvoice = true);
    try {
      final profile = context.read<ProfileProvider>().profile;
      final customerName =
          (profile?.name.trim().isNotEmpty ?? false) ? profile!.name : 'Customer';
      final saved = await InvoiceGenerator.downloadInvoice(order: order, customerName: customerName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved ? 'Invoice saved to Downloads' : 'Could not save invoice',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: saved ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate invoice', style: GoogleFonts.poppins())),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingInvoice = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await context.read<OrderProvider>().fetchDetails(widget.orderId);
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load order details';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        title: Text('Order Details', style: GoogleFonts.poppins(color: scheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildContent(_order!, scheme),
    );
  }

  Widget _buildContent(Order order, ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration:
              BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.id}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: scheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(DateFormat('d MMM yyyy, hh:mm a').format(order.date),
                      style: GoogleFonts.poppins(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
              Text(order.statusLabel, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: kGreen)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Products', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface)),
        const SizedBox(height: 8),
        ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.image.startsWith('http')
                        ? CachedNetworkImage(imageUrl: item.image,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
                            errorWidget: (_, __, ___) =>
                                Container(width: 48, height: 48, color: scheme.surfaceContainerHighest))
                        : Image.asset(item.image,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(width: 48, height: 48, color: scheme.surfaceContainerHighest)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface)),
                        Text('${item.unit} Ãƒâ€” ${item.quantity}',
                            style: GoogleFonts.poppins(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  Text('${item.price * item.quantity}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: scheme.onSurface)),
                ],
              ),
            )),
        const Divider(height: 28),
        Text('Delivery Address',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface)),
        const SizedBox(height: 6),
        Text(order.address, style: GoogleFonts.poppins(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.7))),
        const Divider(height: 28),
        Text('Payment Method',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface)),
        const SizedBox(height: 6),
        Text(order.paymentMethod, style: GoogleFonts.poppins(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.7))),
        const Divider(height: 28),
        Text('Order Timeline',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface)),
        const SizedBox(height: 10),
        ...order.timeline.asMap().entries.map((entry) {
          final step = entry.value;
          final isLast = entry.key == order.timeline.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: step.completed ? kGreen : scheme.onSurface.withValues(alpha: 0.2)),
                    ),
                    if (!isLast)
                      Expanded(
                          child: Container(
                              width: 2, color: step.completed ? kGreen : scheme.onSurface.withValues(alpha: 0.15))),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title,
                            style:
                                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface)),
                        if (step.time != null)
                          Text(step.time!,
                              style: GoogleFonts.poppins(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 8),
        Text('Price Breakdown',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface)),
        const SizedBox(height: 10),
        _priceRow('Item Total', '${order.itemTotal}', scheme),
        _priceRow('Delivery Fee', '${order.deliveryFee}', scheme),
        _priceRow('Platform Fee', '${order.platformFee}', scheme),
        if (order.discount > 0) _priceRow('Discount', '-${order.discount}', scheme, isDiscount: true),
        const Divider(),
        _priceRow('Grand Total', '${order.grandTotal}', scheme, isBold: true),
        if (order.paymentStatus == 'paid') ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isGeneratingInvoice ? null : () => _downloadInvoice(order),
              style: OutlinedButton.styleFrom(
                foregroundColor: kGreen,
                side: const BorderSide(color: kGreen),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isGeneratingInvoice
                  ? const SizedBox(
                      width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download, size: 18),
              label: Text('Download Tax Invoice',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        if (order.rawStatus == 'delivered') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final submitted = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => RequestReturnScreen(order: order)),
                );
                if (submitted == true) _load();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade700),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.assignment_return_outlined, size: 18),
              label: Text('Request Return',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _priceRow(String label, String value, ColorScheme scheme, {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: scheme.onSurface)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isDiscount ? kGreen : (isBold ? kGreen : scheme.onSurface))),
        ],
      ),
    );
  }
}