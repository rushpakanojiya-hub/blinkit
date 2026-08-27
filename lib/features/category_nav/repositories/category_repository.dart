import '../../../services/api_service.dart';
import '../data/category_mock_data.dart';
import '../models/category_models.dart';

/// Products/categories now come from the real backend where available.
/// Category/section navigation structure stays mock (pure UI taxonomy),
/// but actual product listings are fetched from ApiService and matched
/// to a mock category by name, so cart/checkout works end-to-end.
class CategoryRepository {
  static List<Map<String, dynamic>>? _cachedProducts;
  static DateTime? _cachedAt;

  // Backend category names (from the real DB, e.g. "Fruits", "Shampoo")
  // don't line up 1:1 with the mock taxonomy's category titles (e.g.
  // "Vegetables & Fruits", "Hair"). Matching on exact title equality meant
  // every backend product silently failed to match and the screen fell
  // back to fully-mock (non-purchasable) products. This maps each real
  // backend category name to the mock categoryId it should appear under,
  // so real products route into a real tab and stay purchasable.
  static const Map<String, String> _backendToMockCategoryId = {
    'fruits': 'cat_veg_fruits',
'vegetables': 'cat_veg_fruits',
    'chocolate': 'cat_sweets_choco',
    'beverages': 'cat_drinks_juices',
    'ice creams': 'cat_ice_creams',
    'bakery': 'cat_bakery_biscuits',
    'biscuits': 'cat_biscuits',
    'namkeen': 'cat_chips_namkeen',
    'wafers': 'cat_chips',
    'ketchup': 'cat_sauces_spreads',
    'shampoo': 'cat_hair',
    'soap': 'cat_bath_body',
    'personal care': 'cat_bath_body',
    'pickle': 'cat_sauces_spreads',
    'puja items': 'cat_home_lifestyle',
    'toys': 'cat_stationery_games',
    'clothes': 'cat_clothes',
    'atta & rice': 'cat_atta_rice_dal',
    'oil & spices': 'cat_oil_ghee_masala',
    'dairy & eggs': 'cat_dairy_bread_eggs',
    'dry fruits': 'cat_dryfruits_cereals',
    'kitchenware': 'cat_kitchenware',
    'meat & fish': 'cat_chicken_meat_fish',
    'tea & coffee': 'cat_tea_coffee',
    'instant food': 'cat_instant_food',
    'mouth fresheners': 'cat_paan_corner',
    'skin care': 'cat_skin_face',
    'feminine hygiene': 'cat_feminine_hygiene',
    'baby care': 'cat_baby_care',
    'health care': 'cat_health_pharma',
    'cleaning supplies': 'cat_cleaners_repellents',
    'electronics': 'cat_electronics',
  };

  /// True if a backend product's category name belongs on this mock
  /// [categoryId]'s tab, using the explicit mapping above (falling back to
  /// exact title equality for any backend category not yet mapped, so new
  /// categories that happen to share their exact name with a mock one
  /// still work automatically).
  bool _backendCategoryBelongsTo(String backendCategoryName, CategoryModel category) {
    final key = backendCategoryName.toLowerCase();
    final mappedId = _backendToMockCategoryId[key];
    if (mappedId != null) return mappedId == category.id;
    return key == category.title.toLowerCase();
  }

  Future<List<Map<String, dynamic>>> _allBackendProducts() async {
    final isCacheValid = _cachedProducts != null && _cachedAt != null && DateTime.now().difference(_cachedAt!).inSeconds < 30;
    if (isCacheValid) return _cachedProducts!;
    try {
      final raw = await ApiService.getProducts();
      _cachedProducts = raw.cast<Map<String, dynamic>>();
      _cachedAt = DateTime.now();
    } catch (_) {
      _cachedProducts = [];
    }
    return _cachedProducts!;
  }

  // Category ids to hide from the Home screen's category grid only.
  // They stay fully visible/browsable in the Categories tab - this list
  // only controls what shows up inline on Home.
  static const Set<String> _hiddenOnHome = {'cat_chips', 'cat_biscuits'};

  Future<List<CategorySectionModel>> fetchHomeSections() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return CategoryMockData.sections
        .map((section) => CategorySectionModel(
              id: section.id,
              title: section.title,
              categories: section.categories
                  .where((c) => !_hiddenOnHome.contains(c.id))
                  .toList(),
            ))
        .where((section) => section.categories.isNotEmpty)
        .toList();
  }

  Future<List<SubCategoryModel>> fetchSubCategories(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final category = CategoryMockData.sections
        .expand((s) => s.categories)
        .firstWhere((c) => c.id == categoryId);
    return category.subCategories;
  }

  CategoryModel _findCategoryById(String categoryId) {
    return CategoryMockData.sections
        .expand((s) => s.categories)
        .firstWhere((c) => c.id == categoryId);
  }

  String _categoryName(Map<String, dynamic> raw) {
    final cat = raw['category'];
    if (cat is Map) return (cat['name'] ?? '').toString();
    return '';
  }

  /// Explicit product-name keyword overrides, keyed by subcategory id.
  /// Subcategory *titles* (e.g. "Fresh Fruits", "Bhujia & Sev", "Cream
  /// Biscuits") almost never appear literally inside real backend
  /// product names ("Apple", "Aashirvaad Atta", "KitKat"...), so the
  /// generic title-word match further below misses for most real
  /// products and silently falls back to round-robin bucketing -
  /// scattering real products across every subcategory tab regardless
  /// of what they actually are. These lists are checked first, across
  /// every mock category with a real backend mapping, so real products
  /// land on the subcategory a person would actually expect.
  static const Map<String, List<String>> _subCategoryKeywordOverrides = {
    // Vegetables & Fruits
    'cat_veg_fruits_sub0': [ // Fresh Vegetables
      'tomato', 'onion', 'potato', 'capsicum', 'cabbage', 'cauliflower',
      'brinjal', 'okra', 'bhindi', 'spinach', 'palak', 'carrot',
      'cucumber', 'peas', 'corn', 'mushroom', 'garlic', 'ginger',
      'chilli', 'chili', 'beans', 'beetroot', 'pumpkin', 'radish',
      'gourd', 'coriander', 'methi', 'drumstick', 'lauki',
      'green leaves', 'leafy', 'saag', 'vegetable', 'veggies',
    ],
    'cat_veg_fruits_sub1': [ // Fresh Fruits
      'apple', 'banana', 'mango', 'orange', 'papaya', 'watermelon',
      'pear', 'guava', 'chiku', 'sapota', 'plum', 'litchi', 'grape',
      'jackfruit', 'custard apple', 'sitaphal', 'muskmelon',
    ],
    'cat_veg_fruits_sub2': ['organic'], // Organic Produce
    'cat_veg_fruits_sub3': [ // Exotic Fruits
      'dragon fruit', 'kiwi', 'pineapple', 'pomegranate', 'avocado',
      'blueberr', 'strawberr', 'passion fruit', 'persimmon', 'fig',
    ],

    // Atta, Rice & Dal
    'cat_atta_rice_dal_sub0': ['atta', 'flour', 'maida', 'besan', 'sooji', 'rava'],
    'cat_atta_rice_dal_sub1': ['rice', 'basmati', 'poha', 'idli rice'],
    'cat_atta_rice_dal_sub2': [
      'dal', 'chana', 'moong', 'toor', 'urad', 'rajma', 'lentil', 'masoor', 'pulses',
    ],
    'cat_atta_rice_dal_sub3': ['sugar', 'jaggery', 'gur'],

    // Oil, Ghee & Masala
    'cat_oil_ghee_masala_sub0': [
      'sunflower oil', 'mustard oil', 'groundnut oil', 'coconut oil',
      'olive oil', 'refined oil', 'cooking oil', 'edible oil',
    ],
    'cat_oil_ghee_masala_sub1': ['ghee', 'vanaspati', 'dalda'],
    'cat_oil_ghee_masala_sub2': [
      'jeera', 'cumin', 'mustard seed', 'cardamom', 'clove', 'cinnamon',
      'pepper', 'bay leaf', 'star anise', 'fennel', 'saunf',
    ],
    'cat_oil_ghee_masala_sub3': [
      'masala', 'garam masala', 'chilli powder', 'turmeric', 'haldi',
      'coriander powder', 'dhania powder',
    ],

    // Dairy, Bread & Eggs
    'cat_dairy_bread_eggs_sub0': ['milk'],
    'cat_dairy_bread_eggs_sub1': ['bread', 'pav', 'bun'],
    'cat_dairy_bread_eggs_sub2': ['egg'],
    'cat_dairy_bread_eggs_sub3': ['butter', 'cheese', 'paneer', 'curd', 'yogurt', 'cream'],

    // Bakery
    'cat_bakery_biscuits_sub0': ['cake', 'swiss roll', 'roll'],
    'cat_bakery_biscuits_sub1': ['pastry', 'pastries', 'cupcake'],
    'cat_bakery_biscuits_sub2': ['bread', 'bun', 'pav'],
    'cat_bakery_biscuits_sub3': ['rusk', 'toast'],

    // Biscuits
    'cat_biscuits_sub0': ['cookie', 'chocochip', 'choco chip'],
    'cat_biscuits_sub1': ['cream biscuit', 'oreo', 'bourbon', 'treat', 'good day'],
    'cat_biscuits_sub2': ['glucose', 'parle-g', 'parle g', 'tiger'],
    'cat_biscuits_sub3': ['marie', 'digestive', 'monaco', 'krackjack', 'thin arrowroot'],

    // Dry Fruits & Cereals
    'cat_dryfruits_cereals_sub0': ['almond', 'cashew', 'walnut', 'pista', 'pistachio', 'nuts'],
    'cat_dryfruits_cereals_sub1': ['raisin', 'dates', 'kishmish', 'anjeer', 'fig'],
    'cat_dryfruits_cereals_sub2': ['cereal', 'cornflakes', 'corn flakes'],
    'cat_dryfruits_cereals_sub3': ['muesli', 'oats', 'oatmeal', 'granola'],

    // Kitchenware & Appliances
    'cat_kitchenware_sub0': [
      'tawa', 'pan', 'kadhai', 'cookware', 'chopping board', 'kitchen scissors', 'knife',
    ],
    'cat_kitchenware_sub1': ['container', 'storage', 'box', 'jar'],
    'cat_kitchenware_sub2': ['mixer', 'grinder', 'toaster', 'blender', 'appliance', 'iron'],
    'cat_kitchenware_sub3': ['bottle', 'flask', 'water bottle'],

    // Chicken & Meat
    'cat_chicken_meat_fish_sub0': ['chicken'],
    'cat_chicken_meat_fish_sub1': ['mutton', 'lamb', 'goat'],
    'cat_chicken_meat_fish_sub2': ['fish', 'rohu', 'prawn', 'shrimp', 'seafood', 'pomfret'],
    'cat_chicken_meat_fish_sub3': ['egg'],

    // Namkeen
    'cat_chips_namkeen_sub0': ['namkeen', 'chivda'],
    'cat_chips_namkeen_sub1': ['bhujia', 'sev'],
    'cat_chips_namkeen_sub2': ['popcorn'],
    'cat_chips_namkeen_sub3': ['mixture', 'mix namkeen'],

    // Chips
    'cat_chips_sub0': ['potato chip', 'lays', 'chips'],
    'cat_chips_sub1': ['corn chip', 'nachos', 'doritos'],
    'cat_chips_sub2': ['kurkure', 'cheetos', 'extruded'],
    'cat_chips_sub3': ['multigrain'],

    // Sweets & Chocolates
    'cat_sweets_choco_sub0': ['sweet', 'mithai', 'ladoo', 'barfi', 'rasgulla', 'gulab jamun'],
    'cat_sweets_choco_sub1': [
      'kitkat', 'hersheys', 'snickers', 'dairy milk', 'mars', 'five star',
      'munch', 'perk', 'bournville', 'dark chocolate', 'fantasy', 'chocolate bar',
    ],
    'cat_sweets_choco_sub2': ['gift pack', 'celebration', 'assorted box'],
    'cat_sweets_choco_sub3': ['candy', 'lollipop', 'eclairs', 'toffee', 'alpenliebe'],

    // Drinks & Juices
    'cat_drinks_juices_sub0': [
      'sprite', 'thums up', 'coca-cola', 'coke', 'pepsi', 'fanta', 'soft drink', 'soda',
    ],
    'cat_drinks_juices_sub1': ['juice', 'real ', 'tropicana', 'mango juice'],
    'cat_drinks_juices_sub2': ['red bull', 'energy drink', 'monster', 'gatorade'],
    'cat_drinks_juices_sub3': ['horlicks', 'health drink', 'protein shake'],

    // Tea, Coffee & Milk Drinks
    'cat_tea_coffee_sub0': ['tea', 'chai', 'tetley', 'red label', 'taj mahal'],
    'cat_tea_coffee_sub1': ['coffee', 'nescafe', 'bru'],
    'cat_tea_coffee_sub2': ['green tea', 'lipton green'],
    'cat_tea_coffee_sub3': ['bournvita', 'horlicks', 'boost', 'complan', 'malt'],

    // Instant Food
    'cat_instant_food_sub0': ['noodle', 'maggi', 'pasta'],
    'cat_instant_food_sub1': ['ready to eat', 'pulao', 'biryani'],
    'cat_instant_food_sub2': ['frozen', 'nugget', 'samosa', 'spring roll'],
    'cat_instant_food_sub3': ['soup'],

    // Sauces & Spreads
    'cat_sauces_spreads_sub0': ['ketchup', 'sauce', 'mayonnaise'],
    'cat_sauces_spreads_sub1': ['jam', 'spread', 'nutella'],
    'cat_sauces_spreads_sub2': ['honey'],
    'cat_sauces_spreads_sub3': ['peanut butter'],

    // Paan Corner
    'cat_paan_corner_sub0': ['mouth freshener'],
    'cat_paan_corner_sub1': ['supari'],
    'cat_paan_corner_sub2': ['digestive', 'hajmola', 'churan'],
    'cat_paan_corner_sub3': ['mint', 'mentos', 'polo'],

    // Ice Creams & More
    'cat_ice_creams_sub0': ['tub', 'family pack', 'litre'],
    'cat_ice_creams_sub1': ['cup', 'stick', 'cone', 'magnum', 'cornetto'],
    'cat_ice_creams_sub2': ['kulfi'],
    'cat_ice_creams_sub3': ['frozen dessert', 'sundae'],

    // Bath & Body
    'cat_bath_body_sub0': ['soap', 'body wash', 'shower gel'],
    'cat_bath_body_sub1': ['lotion', 'moisturi'],
    'cat_bath_body_sub2': ['talcum', 'talc', 'powder'],
    'cat_bath_body_sub3': ['deodorant', 'deo', 'perfume', 'body spray'],

    // Hair
    'cat_hair_sub0': ['shampoo'],
    'cat_hair_sub1': ['conditioner'],
    'cat_hair_sub2': ['hair oil'],
    'cat_hair_sub3': ['hair color', 'hair dye', 'mehendi'],

    // Skin & Face
    'cat_skin_face_sub0': ['face wash', 'facewash', 'cleanser'],
    'cat_skin_face_sub1': ['moisturizer', 'moisturiser'],
    'cat_skin_face_sub2': ['sunscreen', 'sunblock', 'spf'],
    'cat_skin_face_sub3': ['face mask', 'facemask', 'sheet mask'],

    // Feminine Hygiene
    'cat_feminine_hygiene_sub0': ['sanitary pad', 'pad'],
    'cat_feminine_hygiene_sub1': ['tampon'],
    'cat_feminine_hygiene_sub2': ['intimate wash'],
    'cat_feminine_hygiene_sub3': ['menstrual cup'],

    // Baby Care
    'cat_baby_care_sub0': ['diaper'],
    'cat_baby_care_sub1': ['baby food', 'cerelac', 'formula'],
    'cat_baby_care_sub2': ['baby lotion', 'baby oil', 'baby powder', 'baby cream'],
    'cat_baby_care_sub3': ['wipes', 'baby wipe'],

    // Health & Pharma
    'cat_health_pharma_sub0': ['paracetamol', 'medicine', 'tablet', 'syrup'],
    'cat_health_pharma_sub1': ['supplement', 'multivitamin', 'vitamin'],
    'cat_health_pharma_sub2': ['first aid', 'sanitizer', 'bandage', 'antiseptic'],
    'cat_health_pharma_sub3': ['protein powder', 'protein', 'whey', 'nutrition'],

    // Home & Lifestyle
    'cat_home_lifestyle_sub0': ['bedsheet', 'bed linen', 'pillow cover', 'blanket'],
    'cat_home_lifestyle_sub1': [
      'decor', 'showpiece', 'candle', 'puja', 'agarbatti', 'camphor',
      'pooja thali', 'bell', 'ghanti',
    ],
    'cat_home_lifestyle_sub2': ['storage', 'organizer'],
    'cat_home_lifestyle_sub3': ['plant', 'pot', 'planter'],

    // Clothes
    'cat_clothes_sub0': ['tshirt', 't-shirt', 'full sleeve', 'sando', 'vest', 'tank top', 'sleeveless'],
    'cat_clothes_sub1': ['jean', 'trouser'],
    'cat_clothes_sub2': ['dress', 'floral dress', 'gown', 'skirt', 'denim dress'],
    'cat_clothes_sub3': ['jacket', 'hoodie', 'sweater', 'sweatshirt'],

    // Cleaners & Repellents
    'cat_cleaners_repellents_sub0': ['floor cleaner', 'toilet cleaner', 'phenyl', 'harpic'],
    'cat_cleaners_repellents_sub1': [
      'detergent', 'surf excel', 'washing powder', 'tide', 'ariel',
    ],
    'cat_cleaners_repellents_sub2': ['dishwash', 'vim', 'dish soap'],
    'cat_cleaners_repellents_sub3': [
      'mosquito', 'repellent', 'odomos', 'coil', 'good knight', 'all out',
    ],

    // Electronics
    'cat_electronics_sub0': ['earphone', 'headphone', 'speaker'],
    'cat_electronics_sub1': ['charger', 'cable'],
    'cat_electronics_sub2': ['battery', 'batteries'],
    'cat_electronics_sub3': ['bulb', 'led', 'tubelight'],

    // Stationery & Games
    'cat_stationery_games_sub0': ['notebook', 'pen', 'pencil', 'eraser'],
    'cat_stationery_games_sub1': ['board game', 'playing cards', 'ludo', 'carrom'],
    'cat_stationery_games_sub2': ['crayon', 'sketch pen', 'paint'],
    'cat_stationery_games_sub3': ['toy', 'doll', 'puzzle', 'hot wheels', 'car', 'rc ', 'remote control', 'action figure'],
  };

  /// Finds which subcategory (by position, 0-based) a backend product
  /// belongs to. Checks explicit keyword overrides first (for cases
  /// where the subcategory title's own words never appear in real
  /// product names), then falls back to matching any word from the
  /// subcategory's title against the product name (e.g. "Farm Eggs
  /// (6 pcs)" -> the "Eggs" subcategory). Only spreads products evenly
  /// by [index] as a last resort, so every tab has something to show
  /// even without a real match.
  int _guessSubCategoryIndex(String productName, CategoryModel category, int index) {
    final subs = category.subCategories;
    if (subs.isEmpty) return 0;
    final nameLower = productName.toLowerCase();

    for (var s = 0; s < subs.length; s++) {
      final overrides = _subCategoryKeywordOverrides[subs[s].id];
      if (overrides != null) {
        for (final keyword in overrides) {
          if (nameLower.contains(keyword)) return s;
        }
      }
    }

    for (var s = 0; s < subs.length; s++) {
      // Skip subcategories that have explicit overrides above - if none
      // of their keywords matched, the generic title-word fallback below
      // would just misfire on unrelated words (e.g. "Fruits" from
      // "Exotic Fruits" matching every fruit, undoing the overrides).
      if (_subCategoryKeywordOverrides.containsKey(subs[s].id)) continue;
      final words = subs[s]
          .title
          .toLowerCase()
          .split(RegExp(r'[ &,]+'))
          .where((w) => w.length > 2);
      for (final word in words) {
        if (nameLower.contains(word)) return s;
      }
    }
    return index % subs.length;
  }

  // Backend image_url comes back as a relative path (e.g. "/uploads/x.png").
  // ProductCard decides network-vs-asset purely by checking if the string
  // starts with "http", so without this prefix it was treated as a bundled
  // asset (and failed to load, since it isn't one).
  static String _resolveImageUrl(String url) {
    if (url.isEmpty || url.startsWith('http') || url.startsWith('assets/')) return url;
    final host = ApiService.baseUrl.replaceAll('/api/v1', '');
    return '$host$url';
  }

  ProductModel _fromBackend(Map<String, dynamic> raw, CategoryModel category, int index) {
    final price = (raw['price'] is num) ? (raw['price'] as num).toDouble() : 0.0;
    final imgUrl = _resolveImageUrl((raw['image_url'] ?? '').toString());
    final name = (raw['name'] ?? '').toString();
    final subIndex = _guessSubCategoryIndex(name, category, index);
    final subs = category.subCategories;
    final subCategoryId = subs.isEmpty ? '' : subs[subIndex].id;
    // Pick an image from the same 3-slot block as the matched subcategory
    // (pool is laid out in blocks of 3 per subcategory, in subcategory
    // order), so e.g. an "Eggs" product gets an egg photo, not whichever
    // image happens to sit at the product's raw list position.
    final poolIndex = subIndex * 3 + (index % 3);
    final fallbackImage = imgUrl.isEmpty
        ? CategoryMockData.imageForCategory(category.id, poolIndex)
        : null;
    return ProductModel(
      id: raw['id'].toString(),
      name: name,
      brand: '',
      weight: '1 pc',
      price: price,
      mrp: price,
      rating: 4.2,
      ratingCount: 0,
      icon: category.icon,
      color: category.color,
      categoryId: category.id,
      subCategoryId: subCategoryId,
      description: (raw['description'] ?? '').toString(),
      nutrition: const [],
      deliveryTime: '10 mins',
      inStock: true,
      image: imgUrl.isEmpty ? fallbackImage : imgUrl,
    );
  }

  Future<List<ProductModel>> fetchProducts({required String categoryId}) async {
    final category = _findCategoryById(categoryId);
    final all = await _allBackendProducts();
    final filtered = all
        .where((p) => _backendCategoryBelongsTo(_categoryName(p), category))
        .toList();
    if (filtered.isEmpty) {
      // No real backend products for this category yet - return empty
      // rather than falling back to unpurchasable mock filler.
      return [];
    }

    final subs = category.subCategories;
    final bucketCount = subs.isEmpty ? 1 : subs.length;
    final buckets = List.generate(bucketCount, (_) => <ProductModel>[]);
    for (var i = 0; i < filtered.length; i++) {
      final name = (filtered[i]['name'] ?? '').toString();
      final subIndex = subs.isEmpty ? 0 : _guessSubCategoryIndex(name, category, i);
      buckets[subIndex].add(_fromBackend(filtered[i], category, i));
    }

    // Only real backend products are shown - every visible product is
    // always purchasable (no mock filler that fails silently at checkout).
    final result = <ProductModel>[];
    for (var s = 0; s < bucketCount; s++) {
      result.addAll(buckets[s]);
    }
    return result;
  }

  Future<ProductModel> fetchProductById(String productId) async {
    final intId = int.tryParse(productId);
    if (intId != null) {
      final all = await _allBackendProducts();
      final match = all.where((p) => p['id'] == intId).toList();
      if (match.isNotEmpty) {
        final raw = match.first;
        final catName = _categoryName(raw);
        final mappedId = _backendToMockCategoryId[catName.toLowerCase()];
        final allCategories =
            CategoryMockData.sections.expand((s) => s.categories);
        final category = allCategories.firstWhere(
          (c) => mappedId != null
              ? c.id == mappedId
              : c.title.toLowerCase() == catName.toLowerCase(),
          orElse: () => allCategories.first,
        );
        return _fromBackend(raw, category, 0);
      }
    }
    return CategoryMockData.allProducts.firstWhere((p) => p.id == productId);
  }

  Future<List<ProductModel>> fetchSimilarProducts(ProductModel product) async {
    final intId = int.tryParse(product.id);
    if (intId != null) {
      final category = _findCategoryById(product.categoryId);
      final all = await _allBackendProducts();
      final filtered = all
          .where((p) =>
              _backendCategoryBelongsTo(_categoryName(p), category) && p['id'] != intId)
          .toList();
      final matched = <ProductModel>[
        for (var i = 0; i < filtered.length && i < 10; i++)
          _fromBackend(filtered[i], category, i),
      ];
      if (matched.isNotEmpty) return matched;
    }
    return CategoryMockData.allProducts
        .where((p) => p.categoryId == product.categoryId && p.id != product.id)
        .take(10)
        .toList();
  }
}


