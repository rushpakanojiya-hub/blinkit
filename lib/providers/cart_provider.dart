import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider extends ChangeNotifier {
  List<dynamic> _items = [];
  int _totalItems = 0;
  double _totalAmount = 0;
  bool _isLoading = false;

  // Local-only cart used for two cases:
  // 1. Demo/mock catalog products that don't exist in the backend database
  //    yet (their id is a non-numeric string like "cat_dairy_p3").
  // 2. Guest (not logged in) users adding a real, purchasable product.
  //    We can't call the backend cart API without a token, so the item is
  //    kept here (keyed by the product's real id, as a string) until the
  //    user logs in and it gets pushed to the server cart.
  final Map<String, Map<String, dynamic>> _localItems = {};

  static const _localCartKey = 'local_cart_v1';

  CartProvider() {
    _restoreLocalCart();
  }

  Future<void> _restoreLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localCartKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _localItems
        ..clear()
        ..addAll(decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))));
      notifyListeners();
    }
  }

  Future<void> _persistLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localCartKey, jsonEncode(_localItems));
  }

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
      // Not synced to the server yet (guest cart) - check local store too.
      return (_localItems[realId.toString()]?['quantity'] as int?) ?? 0;
    }
    final key = productId.toString();
    return (_localItems[key]?['quantity'] as int?) ?? 0;
  }

  void _applyCartData(Map<String, dynamic> data) {
    
    
    final newItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
    // Keep items in their existing on-screen order instead of whatever
    // order the backend returns them in (which tends to bump the most
    // recently updated item to the front, making rows jump around on
    // every + / - tap). Items already known keep their old position;
    // brand-new items are appended at the end.
    final existingOrder = _items.map((e) => e['product_id']).toList();
    final indexed = newItems.asMap().entries.toList();
    indexed.sort((x, y) {
      final aIdx = existingOrder.indexOf(x.value['product_id']);
      final bIdx = existingOrder.indexOf(y.value['product_id']);
      final aRank = aIdx == -1 ? existingOrder.length + x.key : aIdx;
      final bRank = bIdx == -1 ? existingOrder.length + y.key : bIdx;
      return aRank.compareTo(bRank);
    });
    final sortedItems = indexed.map((e) => e.value).toList();
    _items = sortedItems;
    _totalItems = data['total_items'] ?? 0;
    _totalAmount = (data['total_amount'] ?? 0).toDouble();
  }

  Future<void> loadCart() async {
    debugPrint('loadCart() CALLED');
    _isLoading = true;
    notifyListeners();
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        // Guest: nothing to fetch from the server, local cart already
        // holds whatever has been added.
        _isLoading = false;
        notifyListeners();
        return;
      }
      final data = await ApiService.getCart();
      _applyCartData(data);
    } catch (e) {
      debugPrint('loadCart error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void _addOrUpdateLocal(String key, dynamic productId, int quantity, Map<String, dynamic>? productData) {
    final existing = _localItems[key];
    if (existing != null) {
      existing['quantity'] = (existing['quantity'] as int) + quantity;
    } else {
      _localItems[key] = {
        'id': key,
        'name': productData?['name'] ?? '',
        'brand': productData?['brand'] ?? '',
        'weight': productData?['weight'] ?? productData?['unit'] ?? '',
        'price': productData?['price'] ?? 0,
        'image': productData?['image'] ?? '',
        'quantity': quantity,
      };
    }
    notifyListeners();
    _persistLocalCart();
  }

  Future<void> addProduct(dynamic productId,
      {int quantity = 1, Map<String, dynamic>? productData}) async {
    final int? realId = productId is int
        ? productId
        : (productId is String ? int.tryParse(productId) : null);

    if (productData?['inStock'] == false) {
      throw Exception('This item is out of stock.');
    }
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

    final token = await ApiService.getToken();
    if (token == null) {
      // Guest: keep the item in the local cart. It gets synced to the
      // server cart once the user logs in (see syncLocalCartToServer).
      _addOrUpdateLocal(realId.toString(), realId, quantity, productData);
      return;
    }

    try {
      final data = await ApiService.addToCart(realId, quantity);
      _applyCartData(data);
      notifyListeners();
    } catch (e) {
      debugPrint('addProduct error: $e');
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Failed host lookup') || msg.contains('ClientException') || msg.contains('TimeoutException')) {
        throw Exception('No internet connection. Please check your network and try again.');
      }
      throw Exception(msg.replaceFirst('Exception: ', ''));
    }
  }

  Future<void> increment(dynamic productId, {Map<String, dynamic>? productData}) async {
    await addProduct(productId, quantity: 1, productData: productData);
  }

  Future<void> decrement(dynamic productId) async {
    final int? realId = productId is int
        ? productId
        : (productId is String ? int.tryParse(productId) : null);

    final key = (realId ?? productId).toString();
    final localExisting = _localItems[key];
    if (localExisting != null) {
      // Guest item or mock-catalog item living only in the local cart.
      final currentQty = localExisting['quantity'] as int;
      if (currentQty <= 1) {
        _localItems.remove(key);
      } else {
        localExisting['quantity'] = currentQty - 1;
      }
      await _persistLocalCart();
      notifyListeners();
      return;
    }

    if (realId == null) return;

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
      _applyCartData(data);
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

    final key = (realId ?? productId).toString();
    if (_localItems.containsKey(key)) {
      _localItems.remove(key);
      await _persistLocalCart();
      notifyListeners();
      return;
    }

    if (realId == null) return;

    final itemId = getCartItemId(realId);
    if (itemId == null) return;
    try {
      final data = await ApiService.removeCartItem(itemId);
      _applyCartData(data);
      notifyListeners();
    } catch (e) {
      debugPrint('removeItemByProductId error: $e');
    }
  }

  // Call this right after a successful login/OTP-verify so any items a
  // guest added before logging in end up in their real server-side cart
  // instead of silently disappearing.
  Future<void> syncLocalCartToServer() async {
    final token = await ApiService.getToken();
    if (token == null) return;

    final entries = _localItems.entries.toList();
    for (final entry in entries) {
      final realId = int.tryParse(entry.key);
      if (realId == null) continue; // mock/filler items stay local-only
      final quantity = entry.value['quantity'] as int;
      try {
        await ApiService.addToCart(realId, quantity);
        _localItems.remove(entry.key);
      } catch (e) {
        debugPrint('syncLocalCartToServer error for $realId: $e');
      }
    }
    await _persistLocalCart();
    await loadCart();
  }

  void clearCartLocal() {
    _items = [];
    _totalItems = 0;
    _totalAmount = 0;
    _localItems.clear();
    _persistLocalCart();
    notifyListeners();
  }
}






