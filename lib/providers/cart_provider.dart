import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  List<dynamic> _items = [];
  int _totalItems = 0;
  double _totalAmount = 0;
  bool _isLoading = false;

  // Local-only cart for demo/mock catalog products that don't exist in the
  // backend database yet (their id is a non-numeric string like
  // "cat_dairy_p3"). These are kept in-memory only (not synced to the
  // server) so the Add button and View Cart bar still work for them
  // instead of silently failing.
  final Map<String, Map<String, dynamic>> _localItems = {};

  List<dynamic> get items => _items;
  bool get isLoading => _isLoading;

  int get _localItemsCount =>
      _localItems.values.fold(0, (sum, item) => sum + (item['quantity'] as int));

  double get _localItemsTotal => _localItems.values.fold(
      0.0, (sum, item) => sum + ((item['price'] as num).toDouble() * (item['quantity'] as int)));

  int get cartCount => _totalItems + _localItemsCount;

  double get cartTotal => _totalAmount + _localItemsTotal;

  List<Map<String, dynamic>> get localCartItems => _localItems.values.toList();

  int? getCartItemId(int productId) {
    for (final item in _items) {
      if (item['product_id'] == productId) return item['id'];
    }
    return null;
  }

  int getQuantityByProductId(dynamic productId) {
    final int? realId = productId is int
        ? productId
        : (productId is String ? int.tryParse(productId) : null);
    if (realId != null) {
      for (final item in _items) {
        if (item['product_id'] == realId) return item['quantity'];
      }
      return 0;
    }
    final key = productId.toString();
    return (_localItems[key]?['quantity'] as int?) ?? 0;
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.getCart();
      _items = data['items'] ?? [];
      _totalItems = data['total_items'] ?? 0;
      _totalAmount = (data['total_amount'] ?? 0).toDouble();
    } catch (e) {
      debugPrint('loadCart error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(dynamic productId,
      {int quantity = 1, Map<String, dynamic>? productData}) async {
    final int? realId = productId is int
        ? productId
        : (productId is String ? int.tryParse(productId) : null);

    if (realId == null || realId <= 0) {
      // This product doesn't exist in the real backend catalog (a
      // Categories-tab filler item shown when a category has too few
      // real products). Previously this silently added to a local-only
      // cart that displayed a total but could never actually be checked
      // out, causing a confusing "cart is empty" error at payment time.
      // Block it here instead, at the single source of truth for adding
      // to cart, so every screen gets the same clear behavior.
      throw Exception('This item is not available for purchase yet.');
    }
    try {
      final data = await ApiService.addToCart(realId, quantity);
      _items = data['items'] ?? [];
      _totalItems = data['total_items'] ?? 0;
      _totalAmount = (data['total_amount'] ?? 0).toDouble();
      notifyListeners();
    } catch (e) {
      debugPrint('addProduct error: $e');
      throw Exception('Could not add item to cart. Please try again.');
    }
  }

  Future<void> increment(dynamic productId, {Map<String, dynamic>? productData}) async {
    await addProduct(productId, quantity: 1, productData: productData);
  }

  Future<void> decrement(dynamic productId) async {
    final int? realId = productId is int
        ? productId
        : (productId is String ? int.tryParse(productId) : null);

    if (realId == null) {
      final key = productId.toString();
      final existing = _localItems[key];
      if (existing == null) return;
      final currentQty = existing['quantity'] as int;
      if (currentQty <= 1) {
        _localItems.remove(key);
      } else {
        existing['quantity'] = currentQty - 1;
      }
      notifyListeners();
      return;
    }

    final itemId = getCartItemId(realId);
    if (itemId == null) return;
    final currentQty = getQuantityByProductId(realId);
    try {
      Map<String, dynamic> data;
      if (currentQty <= 1) {
        data = await ApiService.removeCartItem(itemId);
      } else {
        data = await ApiService.updateCartItem(itemId, currentQty - 1);
      }
      _items = data['items'] ?? [];
      _totalItems = data['total_items'] ?? 0;
      _totalAmount = (data['total_amount'] ?? 0).toDouble();
      notifyListeners();
    } catch (e) {
      debugPrint('decrement error: $e');
      throw Exception('Could not update cart. Please try again.');
    }
  }

  Future<void> removeItemByProductId(dynamic productId) async {
    final int? realId = productId is int
        ? productId
        : (productId is String ? int.tryParse(productId) : null);

    if (realId == null) {
      _localItems.remove(productId.toString());
      notifyListeners();
      return;
    }

    final itemId = getCartItemId(realId);
    if (itemId == null) return;
    try {
      final data = await ApiService.removeCartItem(itemId);
      _items = data['items'] ?? [];
      _totalItems = data['total_items'] ?? 0;
      _totalAmount = (data['total_amount'] ?? 0).toDouble();
      notifyListeners();
    } catch (e) {
      debugPrint('removeItemByProductId error: $e');
    }
  }

  void clearCartLocal() {
    _items = [];
    _totalItems = 0;
    _totalAmount = 0;
    _localItems.clear();
    notifyListeners();
  }
}
