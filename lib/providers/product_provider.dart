import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../features/category_nav/data/category_mock_data.dart';
import '../features/category_nav/repositories/category_repository.dart';

class ProductProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  Map<String, List<Map<String, dynamic>>> _productsByCategory = {};
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get products => _products;
  Map<String, List<Map<String, dynamic>>> get productsByCategory => _productsByCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const Map<String, String> _categoryAlias = {
    'Atta & Rice': 'Atta, Rice & Dal',
    'Beverages': 'Drinks & Juices',
    'Chocolate': 'Sweets & Chocolates',
    'Cleaning Supplies': 'Cleaners & Repellents',
    'Dairy & Eggs': 'Dairy, Bread & Eggs',
    'Dry Fruits': 'Dry Fruits & Cereals',
    'Fruits': 'Vegetables & Fruits',
    'Health Care': 'Health & Pharma',
    'Ice Creams': 'Ice Creams & More',
    'Ketchup': 'Sauces & Spreads',
    'Pickle': 'Sauces & Spreads',
    'Kitchenware': 'Kitchenware & Appliances',
    'Meat & Fish': 'Chicken & Meat',
    'Mouth Fresheners': 'Paan Corner',
    'Oil & Spices': 'Oil, Ghee & Masala',
    'Personal Care': 'Bath & Body',
    'Puja Items': 'Pooja Essentials',
    'Shampoo': 'Hair',
    'Skin Care': 'Skin & Face',
    'Soap': 'Bath & Body',
    'Tea & Coffee': 'Tea, Coffee & Milk Drinks',
    'Toys': 'Stationery & Games',
    'Wafers': 'Chips',
  };

  static String get _imageHost => ApiService.baseUrl.replaceAll('/api/v1', '');

  String _resolveImage(dynamic imageUrl) {
    final url = (imageUrl ?? '').toString();
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '$_imageHost$url';
  }

  Map<String, dynamic> _toDisplayMap(Map<String, dynamic> raw) {
    final categoryData = raw['category'];
    final categoryName = (categoryData is Map && categoryData['name'] != null)
        ? categoryData['name'].toString()
        : 'Others';
    final name = (raw['name'] ?? '').toString();
    final resolvedImage = _resolveImage(raw['image_url']);
    final id = raw['id'];
    final image = resolvedImage.isNotEmpty
        ? resolvedImage
        : (CategoryMockData.imageForProductByCategoryTitle(
                (_categoryAlias[categoryName] ?? categoryName), name, id is int ? id : 0) ??
            '');
    final inventories = raw['inventories'];
    final computedInStock = raw.containsKey('nearest_in_stock')
        ? raw['nearest_in_stock'] == true
        : (inventories is List && inventories.isNotEmpty)
            ? inventories.any((inv) =>
                inv is Map &&
                (inv['in_stock'] == true) &&
                (inv['stock'] is num) &&
                (inv['stock'] as num) > 0)
            : true;
    return {
      'id': raw['id'],
      'name': name,
      'price': (raw['price'] is num) ? (raw['price'] as num).round() : 0,
      'mrp': (raw['mrp'] is num) ? (raw['mrp'] as num).round() : null,
      'unit': ((raw['weight'] ?? '').toString().trim().isEmpty ? '1 pc' : raw['weight'].toString().trim()),
      'category': categoryName,
      'image': image,
      'inStock': computedInStock,
    };
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Wait for the user's saved address to load (if not already), then
      // pass lat/lng along so the backend can compute nearest-warehouse
      // stock. Without this the backend falls back to combined-warehouse
      // totals and out-of-stock items show as purchasable here even
      // though the Categories tab (which already passes lat/lng) shows
      // them correctly as out of stock.
      await CategoryRepository.ensureLocationLoaded();
      final raw = await ApiService.getProducts(
        lat: CategoryRepository.userLat,
        lng: CategoryRepository.userLng,
      );
      final mapped = raw.map((p) => _toDisplayMap(p as Map<String, dynamic>)).toList();

      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final p in mapped) {
        final cat = p['category'] as String;
        grouped.putIfAbsent(cat, () => []).add(p);
      }

      _products = mapped;
      _productsByCategory = grouped;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}







