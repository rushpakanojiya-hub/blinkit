import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/cart_provider.dart';
import '../models/order_model.dart';
import 'order_status_screen.dart';
import 'orders/request_return_screen.dart';
import 'cart_screen.dart';
import '../utils/invoice_generator.dart';
import 'home_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final Set<String> _generatingInvoiceIds = {};

  Color _statusColor(Order order) {
    switch (order.status) {
      case OrderStatus.delivered:
        return Colors.blue;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.active:
        return const Color(0xFF0C831F);
    }
  }

  Future<void> _downloadInvoice(Order order) async {
    if (_generatingInvoiceIds.contains(order.id)) return;
    setState(() => _generatingInvoiceIds.add(order.id));
    try {
      final profile = context.read<ProfileProvider>().profile;
      final customerName = (profile?.name.trim().isNotEmpty ?? false)
          ? profile!.name
          : 'Customer';
      final saved = await InvoiceGenerator.downloadInvoice(
        order: order,
        customerName: customerName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved ? 'Invoice saved to Downloads' : 'Could not save invoice',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: saved ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('INVOICE ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save invoice: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingInvoiceIds.remove(order.id));
    }
  }

  Future<void> _refreshAll() async {
    final provider = context.read<OrderProvider>();
    await Future.wait([
      provider.loadOrders(OrderStatus.active, refresh: true),
      provider.loadOrders(OrderStatus.delivered, refresh: true),
      provider.loadOrders(OrderStatus.cancelled, refresh: true),
    ]);
  }

  Future<void> _cancelOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Order',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel this order?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final orderId = int.tryParse(order.id);
      if (orderId == null) throw Exception('Invalid order id');
      await ApiService.cancelOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order cancelled successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF0C831F),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not cancel order. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _reorder(Order order) async {
    final cart = context.read<CartProvider>();
    try {
      for (final item in order.items) {
        if (item.productId == null) continue;
        await cart.addProduct(item.productId, quantity: item.quantity);
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not add items to cart. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _isCancellable(Order order) =>
      order.rawStatus == 'pending' || order.rawStatus == 'confirmed';

  Future<void> _loadIfNeeded() async {
    final provider = context.read<OrderProvider>();
    final futures = <Future<void>>[];
    for (final s in [
      OrderStatus.active,
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ]) {
      if (provider.statusFor(s) == LoadStatus.initial) {
        futures.add(provider.loadOrders(s));
      }
    }
    await Future.wait(futures);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical &&
            n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          final p = context.read<OrderProvider>();
          for (final s in const [
            OrderStatus.active,
            OrderStatus.delivered,
            OrderStatus.cancelled,
          ]) {
            if (p.statusFor(s) == LoadStatus.loaded) p.loadMore(s);
          }
        }
        return false;
      },
      child: _buildInner(context),
    );
  }

  Widget _buildInner(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final isInitialLoading = [
      orderProvider.statusFor(OrderStatus.active),
      orderProvider.statusFor(OrderStatus.delivered),
      orderProvider.statusFor(OrderStatus.cancelled),
    ].any((s) => s == LoadStatus.initial || s == LoadStatus.loading);
    final allFailed = [
      OrderStatus.active,
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ].every((s) => orderProvider.statusFor(s) == LoadStatus.error);
    final orders = [
      ...orderProvider.ordersFor(OrderStatus.active),
      ...orderProvider.ordersFor(OrderStatus.delivered),
      ...orderProvider.ordersFor(OrderStatus.cancelled),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: isInitialLoading && orders.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0C831F)),
            )
          : (orders.isEmpty && allFailed)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load orders. Check your internet connection.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refreshAll,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your orders will appear here',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C831F),
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
          : RefreshIndicator(
              color: const Color(0xFF0C831F),
              onRefresh: _refreshAll,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderStatusScreen(order: order),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0C831F,
                              ).withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${order.id}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${order.date.day}/${order.date.month}/${order.date.year}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      order,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    order.statusLabel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor(order),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        order.items
                                            .map((i) => i.name)
                                            .join(', '),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${order.itemCount} items',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Amount',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '\u20B9${order.grandTotal}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0C831F),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (_isCancellable(order)) ...[
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _isCancellable(order)
                                              ? () => _cancelOrder(order)
                                              : null,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                Colors.red.shade700,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 12,
                                            ),
                                            side: BorderSide(
                                              color: _isCancellable(order)
                                                  ? Colors.red.shade700
                                                  : Colors.grey,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            'Cancel',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              color: _isCancellable(order)
                                                  ? Colors.red.shade700
                                                  : Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => OrderStatusScreen(
                                                order: order,
                                              ),
                                            ),
                                          );
                                          if (mounted) _refreshAll();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF2196F3,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Track',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _reorder(order),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0C831F,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Reorder',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
