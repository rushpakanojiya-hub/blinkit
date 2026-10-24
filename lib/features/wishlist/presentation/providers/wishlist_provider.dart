import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../providers/cart_provider.dart';
import '../../domain/entities/wishlist_item_entity.dart';

class WishlistProvider extends ChangeNotifier {
  static const _storageKey = 'wishlist_v1';

  ViewStatus status = ViewStatus.empty;
  String? errorMessage;
  List<WishlistItemEntity> items = [];
  final Set<String> pendingIds = {};

  WishlistProvider() {
    _restore();
  }

  Map<String, dynamic> _toMap(WishlistItemEntity i) => {
    'id': i.id,
    'productId': i.productId,
    'name': i.name,
    'imageUrl': i.imageUrl,
    'price': i.price,
    'mrp': i.mrp,
    'discountPercent': i.discountPercent,
    'rating': i.rating,
    'ratingCount': i.ratingCount,
    'inStock': i.inStock,
    'unit': i.unit,
    'category': i.category,
    'description': i.description,
  };

  WishlistItemEntity _fromMap(Map<String, dynamic> m) => WishlistItemEntity(
    id: m['id'].toString(),
    productId: m['productId'].toString(),
    name: (m['name'] ?? '').toString(),
    imageUrl: (m['imageUrl'] ?? '').toString(),
    price: (m['price'] as num?)?.toDouble() ?? 0,
    mrp: (m['mrp'] as num?)?.toDouble() ?? 0,
    discountPercent: (m['discountPercent'] as num?)?.toInt() ?? 0,
    rating: (m['rating'] as num?)?.toDouble() ?? 0,
    ratingCount: (m['ratingCount'] as num?)?.toInt() ?? 0,
    inStock: m['inStock'] as bool? ?? true,
    unit: (m['unit'] ?? '1 pc').toString(),
    category: (m['category'] ?? 'Grocery').toString(),
    description: (m['description'] ?? '').toString(),
  );

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final stored = (jsonDecode(raw) as List)
          .map((e) => _fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      final known = items.map((i) => i.productId).toSet();
      items = [...stored.where((i) => !known.contains(i.productId)), ...items];
      status = items.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
      notifyListeners();
    } catch (e) {
      debugPrint('wishlist restore error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map(_toMap).toList()),
      );
    } catch (e) {
      debugPrint('wishlist persist error: $e');
    }
  }

  void clear() {
    items = [];
    pendingIds.clear();
    errorMessage = null;
    status = ViewStatus.empty;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.remove(_storageKey))
        .catchError((e) {
          debugPrint('wishlist clear error: $e');
          return false;
        });
  }

  Future<void> loadWishlist() async {
    status = items.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
    notifyListeners();
  }

  bool isWishlisted(String productId) =>
      items.any((item) => item.productId == productId);

  /// Adds the product if it isn't already saved, removes it if it is.
  void toggle(WishlistItemEntity item) {
    if (isWishlisted(item.productId)) {
      items = items.where((i) => i.productId != item.productId).toList();
    } else {
      items = [...items, item];
    }
    status = items.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
    notifyListeners();
    _persist();
  }

  Future<void> removeItem(String id) async {
    items = items.where((item) => item.id != id).toList();
    status = items.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
    notifyListeners();
    _persist();
  }

  /// Adds the item to the cart first; it is removed from the wishlist only
  /// if the add actually succeeded. Returns false (item stays in wishlist)
  /// when out of stock, already in progress, or the cart add fails.
  Future<bool> moveToCart(String id, CartProvider cart) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx == -1) return false;
    final item = items[idx];
    if (!item.inStock) return false;
    if (pendingIds.contains(id)) return false;

    pendingIds.add(id);
    try {
      await cart.addProduct(
        item.productId,
        productData: {
          'name': item.name,
          'price': item.price,
          'image': item.imageUrl,
        },
      );
    } catch (e) {
      debugPrint('moveToCart error: $e');
      pendingIds.remove(id);
      notifyListeners();
      return false;
    }
    pendingIds.remove(id);
    items = items.where((i) => i.id != id).toList();
    status = items.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
    notifyListeners();
    _persist();
    return true;
  }
}
