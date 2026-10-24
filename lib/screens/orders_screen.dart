import 'package:provider/provider.dart';
import '../features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'login_screen.dart';
import 'order_detail_screen.dart';
import 'earnings_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;

  bool? _isOnline; // null while the initial status fetch is in flight
  bool _statusLoading = true;
  bool _statusUpdating = false;
  String? _statusError;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadOnlineStatus();
    LocationService.startTracking();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await ApiService.getMyDeliveries();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load orders';
        _loading = false;
      });
    }
  }

  // Fetches the partner's real online/offline status from the backend, so
  // it reflects what was last persisted after an app refresh or relogin
  // instead of resetting to a hardcoded default.
  Future<void> _loadOnlineStatus() async {
    setState(() {
      _statusLoading = true;
      _statusError = null;
    });
    try {
      final isOnline = await ApiService.getOnlineStatus();
      if (!mounted) return;
      setState(() {
        _isOnline = isOnline;
        _statusLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusError = 'Failed to load status';
        _statusLoading = false;
      });
    }
  }

  Future<void> _toggleOnlineStatus() async {
    if (_isOnline == null || _statusUpdating) return;
    final next = !_isOnline!;
    setState(() {
      _statusUpdating = true;
      _statusError = null;
    });
    try {
      final confirmed = await ApiService.updateOnlineStatus(next);
      if (!mounted) return;
      setState(() {
        _isOnline = confirmed;
        _statusUpdating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusUpdating = false;
        _statusError = 'Failed to update status';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update status. Please try again.'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    await ApiService.clearUserData();
    if (mounted) context.read<WishlistProvider>().clear();
    LocationService.stopTracking();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOnlineToggle() {
    if (_statusLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (_statusError != null && _isOnline == null) {
      return IconButton(
        icon: const Icon(Icons.error_outline),
        tooltip: 'Status unavailable, tap to retry',
        onPressed: _loadOnlineStatus,
      );
    }

    final online = _isOnline == true;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          online ? 'Online' : 'Offline',
          style: const TextStyle(fontSize: 13),
        ),
        if (_statusUpdating)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          )
        else
          Switch(
            value: online,
            onChanged: (_) => _toggleOnlineStatus(),
            activeThumbColor: Colors.greenAccent,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deliveries'),
        actions: [
          _buildOnlineToggle(),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Earnings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EarningsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _orders.isEmpty
          ? const Center(child: Text('No orders assigned yet'))
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text('Order #${order['id']}'),
                      subtitle: Text(
                        '${order['address']?['city'] ?? ''} • ₹${order['total_amount']} • ${order['payment_method']?.toString().toUpperCase() ?? ''}',
                      ),
                      trailing: Chip(
                        label: Text(
                          order['status'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: _statusColor(order['status'] ?? ''),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: order),
                          ),
                        );
                        _loadOrders();
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
