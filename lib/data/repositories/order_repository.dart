import 'package:flutter/foundation.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

class OrderRepository {
  static const int pageSize = 6;

  List<Order>? _cache;

  Future<List<Order>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await ApiService.getOrders(page: 1, limit: 100);
    if (kDebugMode) {
      for (final e in raw) {
        final m = e as Map<String, dynamic>;
        debugPrint(
            '[ORDER DEBUG] id=${m['id']} status=${m['status']} payment_method=${m['payment_method']} payment_status=${m['payment_status']}');
      }
    }
    _cache = raw
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return _cache!;
  }

  void invalidate() => _cache = null;

  Future<List<Order>> fetchOrders(OrderStatus status,
      {int page = 0, bool simulateError = false}) async {
    if (simulateError) {
      throw Exception('Unable to load orders. Please check your connection.');
    }
    final all = await _loadAll();
    final filtered = all.where((o) => o.status == status).toList();
    final start = page * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  Future<Order> fetchOrderDetails(String id) async {
    final all = await _loadAll();
    for (final o in all) {
      if (o.id == id) return o;
    }
    // Not in the cached list (e.g. opened via push notification/deep link
    // before the list has ever been loaded, or the order is newer than the
    // cached page) - fall back to a direct network fetch instead of
    // crashing with an unhandled StateError from firstWhere.
    final orderIdInt = int.tryParse(id);
    if (orderIdInt != null) {
      try {
        final raw = await ApiService.getOrder(orderIdInt);
        return Order.fromJson(raw);
      } catch (_) {
        // fall through to the exception below
      }
    }
    throw Exception('Order not found. It may have been removed or the link is invalid.');
  }
}
