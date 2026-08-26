import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../widgets/order_card.dart';
import '../../widgets/state_views.dart';
import 'order_details_screen.dart';

const Color kGreen = Color(0xFF0C831F);

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});
  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<OrderStatus> _statuses = [OrderStatus.active, OrderStatus.delivered, OrderStatus.cancelled];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final s in _statuses) {
        context.read<OrderProvider>().loadOrders(s);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text('Your Orders', style: GoogleFonts.poppins(color: scheme.onSurface, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kGreen,
          unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.5),
          indicatorColor: kGreen,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Active'), Tab(text: 'Delivered'), Tab(text: 'Cancelled')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((s) => _OrderTab(status: s)).toList(),
      ),
    );
  }
}

class _OrderTab extends StatefulWidget {
  final OrderStatus status;
  const _OrderTab({required this.status});
  @override
  State<_OrderTab> createState() => _OrderTabState();
}

class _OrderTabState extends State<_OrderTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<OrderProvider>().loadMore(widget.status);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData get _emptyIcon {
    switch (widget.status) {
      case OrderStatus.active:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String get _emptyMessage {
    switch (widget.status) {
      case OrderStatus.active:
        return 'No active orders right now';
      case OrderStatus.delivered:
        return 'No delivered orders yet';
      case OrderStatus.cancelled:
        return 'No cancelled orders';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final status = provider.statusFor(widget.status);
        final orders = provider.ordersFor(widget.status);

        if (status == LoadStatus.loading) return const LoadingView();
        if (status == LoadStatus.error && orders.isEmpty) {
          return ErrorView(
            message: provider.errorFor(widget.status) ?? 'Something went wrong',
            onRetry: () => provider.loadOrders(widget.status, refresh: true),
          );
        }
        if (orders.isEmpty) return EmptyView(icon: _emptyIcon, message: _emptyMessage);

        return RefreshIndicator(
          color: kGreen,
          onRefresh: () => provider.loadOrders(widget.status, refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: orders.length + 1,
            itemBuilder: (context, index) {
              if (index == orders.length) {
                if (status == LoadStatus.loadingMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(color: kGreen, strokeWidth: 2)),
                  );
                }
                return const SizedBox(height: 20);
              }
              final order = orders[index];
              return OrderCard(
                order: order,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: order.id))),
              );
            },
          ),
        );
      },
    );
  }
}
