import 'package:flutter/foundation.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

class OrderRepository {
  static const int pageSize = 6;

  List<Order>? _cache;

  Future<List<Order>>? _inflight;

  /// Shares one in-flight /orders load between the Active / Delivered /
  /// Cancelled tabs instead of firing a separate request set per tab.
  Future<List<Order>> _loadAll() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    final existing = _inflight;
    if (existing != null) return existing;
    final myGen = _gen;
    late final Future<List<Order>> f;
    f = _fetchAll().then((list) {
      // invalidate() ran while this load was in flight: result is stale.
      if (myGen != _gen) _cache = null;
      return list;
    }).whenComplete(() {
      if (identical(_inflight, f)) _inflight = null;
    });
    _inflight = f;
    return f;
  }

  Future<List<Order>> _fetchAll() async {
    if (_cache != null) return _cache!;
    final raw = <dynamic>[];
    final seen = <String>{};
    for (var pg = 1; pg <= 50; pg++) {
      final chunk = await ApiService.getOrders(page: pg, limit: 100);
      var added = 0;
      for (final e in chunk) {
        if (seen.add((e as Map)['id'].toString())) {
          raw.add(e);
          added++;
        }
      }
      if (chunk.isEmpty || added == 0) break;
    }
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
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        if (c != 0) return c;
        return (int.tryParse(b.id) ?? 0).compareTo(int.tryParse(a.id) ?? 0);
      });
    return _cache!;
  }

  int _gen = 0;

  void invalidate() {
    _gen++;
    _inflight = null;
    _cache = null;
  }

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
    final orderIdInt0 = int.tryParse(id);
    if (orderIdInt0 != null) {
      try {
        final raw0 = await ApiService.getOrder(orderIdInt0);
        final fresh = Order.fromJson(raw0);
        if (_cache != null) {
          final idx = _cache!.indexWhere((o) => o.id == id);
          if (idx != -1) _cache![idx] = fresh;
        }
        return fresh;
      } catch (_) {
        // offline / server error - fall back to the cached copy below
      }
    }
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
