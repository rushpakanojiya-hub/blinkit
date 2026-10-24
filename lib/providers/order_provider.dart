import 'package:flutter/material.dart';
import '../data/repositories/order_repository.dart';
import '../models/order_model.dart';

enum LoadStatus { initial, loading, loaded, error, loadingMore }

class _TabState {
  List<Order> orders = [];
  LoadStatus status = LoadStatus.initial;
  int page = 0;
  int gen = 0;
  bool hasMore = true;
  bool refreshing = false;
  String? errorMessage;
}

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repo = OrderRepository();
  final Map<OrderStatus, _TabState> _tabs = {
    OrderStatus.active: _TabState(),
    OrderStatus.delivered: _TabState(),
    OrderStatus.cancelled: _TabState(),
  };

  List<Order> ordersFor(OrderStatus status) => _tabs[status]!.orders;
  LoadStatus statusFor(OrderStatus status) => _tabs[status]!.status;
  bool hasMoreFor(OrderStatus status) => _tabs[status]!.hasMore;
  String? errorFor(OrderStatus status) => _tabs[status]!.errorMessage;

  Future<void> loadOrders(OrderStatus status, {bool refresh = false}) async {
    final tab = _tabs[status]!;
    if (refresh) {
      // Keep the current list on screen until fresh data arrives, so a slow
      // or failed refresh never wipes it.
      tab.gen++;
      tab.refreshing = true;
      _repo.invalidate();
    } else if (tab.refreshing ||
        tab.status == LoadStatus.loading ||
        tab.status == LoadStatus.loadingMore) {
      return;
    }

    final myGen = tab.gen;
    final hadOrders = tab.orders.isNotEmpty;
    if (refresh) {
      tab.status = hadOrders ? LoadStatus.loaded : LoadStatus.loading;
    } else {
      tab.status = hadOrders ? LoadStatus.loadingMore : LoadStatus.loading;
    }
    tab.errorMessage = null;
    notifyListeners();

    try {
      final result =
          await _repo.fetchOrders(status, page: refresh ? 0 : tab.page);
      if (myGen != tab.gen) return;
      if (refresh) {
        tab.orders = result;
        tab.page = 1;
      } else {
        tab.orders.addAll(result);
        tab.page++;
      }
      tab.hasMore = result.length == OrderRepository.pageSize;
      tab.status = LoadStatus.loaded;
    } catch (e) {
      if (myGen != tab.gen) return;
      tab.errorMessage = e.toString().replaceAll('Exception: ', '');
      tab.status =
          (refresh && hadOrders) ? LoadStatus.loaded : LoadStatus.error;
    }
    tab.refreshing = false;
    notifyListeners();
  }

  Future<void> loadMore(OrderStatus status) async {
    final tab = _tabs[status]!;
    if (!tab.hasMore || tab.status == LoadStatus.loadingMore) return;
    await loadOrders(status);
  }

  Future<Order> fetchDetails(String id) => _repo.fetchOrderDetails(id);

  /// Clears in-memory order state on logout so the next user
  /// doesn't see the previous user's orders before refreshing.
  void clearAll() {
    for (final tab in _tabs.values) {
      tab.gen++;
      tab.orders = [];
      tab.status = LoadStatus.initial;
      tab.page = 0;
      tab.hasMore = true;
      tab.refreshing = false;
      tab.errorMessage = null;
    }
    _repo.invalidate();
    notifyListeners();
  }
}