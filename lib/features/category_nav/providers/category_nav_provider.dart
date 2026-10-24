import 'package:flutter/material.dart';
import '../models/category_models.dart';
import '../repositories/category_repository.dart';

/// Single provider driving both the home-screen category sections and
/// the category -> subcategory -> product grid flow. Kept as one
/// provider (rather than one per screen) since the two states are small
/// and closely related; split further if the module grows.
class CategoryNavProvider extends ChangeNotifier {
  CategoryNavProvider({CategoryRepository? repository})
      : _repo = repository ?? CategoryRepository();

  final CategoryRepository _repo;

  // ---------------- Home sections ----------------
  List<CategorySectionModel> _sections = [];
  LoadStatus _homeStatus = LoadStatus.idle;

  List<CategorySectionModel> get sections => _sections;
  LoadStatus get homeStatus => _homeStatus;

  Future<void> loadHomeSections() async {
    if (_sections.isNotEmpty) return;
    _homeStatus = LoadStatus.loading;
    notifyListeners();
    try {
      _sections = await _repo.fetchHomeSections();
      _homeStatus = LoadStatus.loaded;
    } catch (_) {
      _homeStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  // ---------------- Category product screen ----------------
  CategoryModel? _activeCategory;
  SubCategoryModel? _activeSubCategory;
  String _query = '';
  SortOption _sort = SortOption.relevance;
  bool _inStockOnly = false;
  List<ProductModel> _products = [];
  LoadStatus _productStatus = LoadStatus.idle;

  CategoryModel? get activeCategory => _activeCategory;
  SubCategoryModel? get activeSubCategory => _activeSubCategory;
  List<SubCategoryModel> _subCategories = [];
  List<SubCategoryModel> get subCategories => _subCategories;
  String get query => _query;
  SortOption get sort => _sort;
  bool get inStockOnly => _inStockOnly;
  LoadStatus get productStatus => _productStatus;

  Future<void> openCategory(CategoryModel category) async {
    _activeCategory = category;
    _activeSubCategory = null;
    _query = '';
    _sort = SortOption.relevance;
    _inStockOnly = false;
    _productStatus = LoadStatus.loading;
    notifyListeners();
    _repo.fetchSubCategoriesForCategory(category).then((subs) {
      if (_activeCategory?.id == category.id) {
        _subCategories = subs;
        notifyListeners();
      }
    });
    try {
      _products = await _repo.fetchProducts(categoryId: category.id);
      _productStatus = _products.isEmpty ? LoadStatus.empty : LoadStatus.loaded;
    } catch (_) {
      _productStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> retry() async {
    if (_activeCategory != null) await openCategory(_activeCategory!);
  }

  void selectSubCategory(SubCategoryModel? subCategory) {
    _activeSubCategory = subCategory;
    notifyListeners();
  }

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void updateSort(SortOption option) {
    _sort = option;
    notifyListeners();
  }

  void toggleInStockOnly() {
    _inStockOnly = !_inStockOnly;
    notifyListeners();
  }

  void resetFilters() {
    _query = '';
    _sort = SortOption.relevance;
    _inStockOnly = false;
    _activeSubCategory = null;
    notifyListeners();
  }

  /// Products for [activeCategory] after subcategory/search/stock
  /// filters and the current sort have been applied.
  List<ProductModel> get visibleProducts {
    var list = List<ProductModel>.from(_products);
    if (_activeSubCategory != null) {
      final activeId = _activeSubCategory!.id;
      list = activeId == 'backend_other'
          ? list.where((p) => !p.subCategoryId.startsWith('backend_')).toList()
          : list.where((p) => p.subCategoryId == activeId).toList();
    }
    if (_query.trim().isNotEmpty) {
      list = list.where((p) => p.matchesQuery(_query)).toList();
    }
    if (_inStockOnly) {
      list = list.where((p) => p.inStock).toList();
    }
    switch (_sort) {
      case SortOption.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.discount:
        list.sort((a, b) {
          final c = b.discountPercent.compareTo(a.discountPercent);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
        break;
      case SortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.relevance:
        break;
    }
    return list;
  }

  Future<List<ProductModel>> fetchSimilarProducts(ProductModel product) {
    return _repo.fetchSimilarProducts(product);
  }

  Future<ProductModel> fetchProductById(String id) {
    return _repo.fetchProductById(id);
  }
}
