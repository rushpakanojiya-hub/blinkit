import 'package:flutter/material.dart';
import '../../../constants/asset_constants.dart';
import '../models/category_models.dart';

/// Static mock dataset for the home category-navigation module.
/// No backend/API calls -- everything is generated locally.
/// wraps it in Futures to simulate network latency.
class CategoryMockData {
  CategoryMockData._();

  static final List<CategorySectionModel> sections = _buildSections();

  static List<ProductModel> get allProducts =>
      sections.expand((s) => s.categories).expand((c) => _productsFor(c)).toList();

  static List<CategorySectionModel> _buildSections() {
    return [
      CategorySectionModel(
        id: 'sec_grocery',
        title: 'Grocery & Kitchen',
        categories: [
          _category('cat_veg_fruits', 'Vegetables & Fruits', 'sec_grocery',
              Icons.eco, const Color(0xFF3AA655),
              ['Fresh Vegetables', 'Fresh Fruits', 'Organic Produce', 'Exotic Fruits'],
              image: AssetConstants.vegetablesFruits),
          _category('cat_atta_rice_dal', 'Atta, Rice & Dal', 'sec_grocery',
              Icons.grain, const Color(0xFFC08A3E),
              ['Atta & Flours', 'Rice & Rice Products', 'Dals & Pulses', 'Sugar & Jaggery'],
              image: AssetConstants.attaRiceDal),
          _category('cat_oil_ghee_masala', 'Oil, Ghee & Masala', 'sec_grocery',
              Icons.local_fire_department, const Color(0xFFE0592A),
              ['Edible Oils', 'Ghee & Vanaspati', 'Whole Spices', 'Masala & Blends'],
              image: AssetConstants.oilGheeMasala),
          _category('cat_dairy_bread_eggs', 'Dairy, Bread & Eggs', 'sec_grocery',
              Icons.egg_alt, const Color(0xFF2F8FD1),
              ['Milk', 'Bread & Pav', 'Eggs', 'Butter & Cheese'],
              image: AssetConstants.dairyBreadEggs),
          _category('cat_bakery_biscuits', 'Bakery', 'sec_grocery',
              Icons.bakery_dining, const Color(0xFFB07A2E),
              ['Cakes & Rolls', 'Pastries', 'Bread & Buns', 'Rusk'],
              image: AssetConstants.bakery),
          _category('cat_biscuits', 'Biscuits', 'sec_grocery',
              Icons.cookie, const Color(0xFFC9A227),
              ['Cookies', 'Cream Biscuits', 'Glucose Biscuits', 'Marie & Digestive'],
              image: AssetConstants.biscuits),
          _category('cat_dryfruits_cereals', 'Dry Fruits & Cereals', 'sec_grocery',
              Icons.scatter_plot, const Color(0xFF8A5A2E),
              ['Almonds & Cashews', 'Raisins & Dates', 'Breakfast Cereals', 'Muesli & Oats'],
              image: AssetConstants.dryFruitsCereals),
          _category('cat_kitchenware', 'Kitchenware & Appliances', 'sec_grocery',
              Icons.blender, const Color(0xFF5B6B73),
              ['Cookware', 'Storage & Containers', 'Small Appliances', 'Water Bottles'],
              image: AssetConstants.kitchenwareAppliances),
          _category('cat_chicken_meat_fish', 'Chicken & Meat', 'sec_grocery',
              Icons.set_meal, const Color(0xFFD84315),
              ['Chicken', 'Mutton', 'Fish & Seafood', 'Eggs'],
              image: AssetConstants.chickenMeatFish),
        ],
      ),
      CategorySectionModel(
        id: 'sec_snacks',
        title: 'Snacks & Drinks',
        categories: [
          _category('cat_chips_namkeen', 'Namkeen', 'sec_snacks',
              Icons.fastfood, const Color(0xFFE0A72A),
              ['Traditional Namkeen', 'Bhujia & Sev', 'Popcorn', 'Namkeen Mixture'],
              image: AssetConstants.namkeen),
          _category('cat_chips', 'Chips', 'sec_snacks',
              Icons.local_pizza, const Color(0xFFD68A2B),
              ['Potato Chips', 'Corn Chips', 'Extruded Snacks', 'Multigrain Chips'],
              image: AssetConstants.wafers),
          _category('cat_sweets_choco', 'Sweets & Chocolates', 'sec_snacks',
              Icons.cake, const Color(0xFF8B4A2B),
              ['Indian Sweets', 'Chocolate Bars', 'Gift Packs', 'Candies'],
              image: AssetConstants.sweetsChocolates),
          _category('cat_drinks_juices', 'Drinks & Juices', 'sec_snacks',
              Icons.local_drink, const Color(0xFFE0472A),
              ['Soft Drinks', 'Fruit Juices', 'Energy Drinks', 'Health Drinks'],
              image: AssetConstants.drinksJuices),
          _category('cat_tea_coffee', 'Tea, Coffee & Milk Drinks', 'sec_snacks',
              Icons.emoji_food_beverage, const Color(0xFF6B4226),
              ['Tea', 'Coffee', 'Green Tea', 'Malt Drinks'],
              image: AssetConstants.teaCoffeeMilk),
          _category('cat_instant_food', 'Instant Food', 'sec_snacks',
              Icons.ramen_dining, const Color(0xFFD1562F),
              ['Noodles & Pasta', 'Ready to Eat', 'Frozen Snacks', 'Soup'],
              image: AssetConstants.instantFood),
          _category('cat_sauces_spreads', 'Sauces & Spreads', 'sec_snacks',
              Icons.blender_outlined, const Color(0xFFB6242C),
              ['Ketchup & Sauces', 'Jams & Spreads', 'Honey', 'Peanut Butter'],
              image: AssetConstants.saucesSpreads),
          _category('cat_paan_corner', 'Paan Corner', 'sec_snacks',
              Icons.spa, const Color(0xFF3E7D44),
              ['Mouth Fresheners', 'Supari', 'Digestives', 'Mints'],
              image: AssetConstants.paanCorner),
          _category('cat_ice_creams', 'Ice Creams & More', 'sec_snacks',
              Icons.icecream, const Color(0xFF2FA0C1),
              ['Tubs & Family Packs', 'Cups & Sticks', 'Kulfi', 'Frozen Desserts'],
              image: AssetConstants.iceCreamsMore),
        ],
      ),
      CategorySectionModel(
        id: 'sec_beauty',
        title: 'Beauty & Personal Care',
        categories: [
          _category('cat_bath_body', 'Bath & Body', 'sec_beauty',
              Icons.bathtub, const Color(0xFF2E9E8F),
              ['Soaps & Body Wash', 'Body Lotion', 'Talcum Powder', 'Deodorants'],
              image: AssetConstants.bathBody),
          _category('cat_hair', 'Hair', 'sec_beauty',
              Icons.content_cut, const Color(0xFF7A4A2B),
              ['Shampoo', 'Conditioner', 'Hair Oil', 'Hair Color'],
              image: AssetConstants.hairCare),
          _category('cat_skin_face', 'Skin & Face', 'sec_beauty',
              Icons.face_retouching_natural, const Color(0xFFDB8A7A),
              ['Face Wash', 'Moisturizers', 'Sunscreen', 'Face Masks'],
              image: AssetConstants.skinFace),
          _category('cat_feminine_hygiene', 'Feminine Hygiene', 'sec_beauty',
              Icons.favorite, const Color(0xFFD1477A),
              ['Sanitary Pads', 'Tampons', 'Intimate Wash', 'Menstrual Cups'],
              image: AssetConstants.feminineHygiene),
          _category('cat_baby_care', 'Baby Care', 'sec_beauty',
              Icons.child_care, const Color(0xFF4A90D9),
              ['Diapers', 'Baby Food', 'Baby Skin Care', 'Baby Wipes'],
              image: AssetConstants.babyCare),
          _category('cat_health_pharma', 'Health & Pharma', 'sec_beauty',
              Icons.medical_services, const Color(0xFF2E7D5B),
              ['OTC Medicines', 'Health Supplements', 'First Aid', 'Protein & Nutrition'],
              image: AssetConstants.healthPharma),
          
        ],
      ),
      CategorySectionModel(
        id: 'sec_household',
        title: 'Household Essentials',
        categories: [
          _category('cat_home_lifestyle', 'Home & Lifestyle', 'sec_household',
              Icons.chair, const Color(0xFF8A6A3E),
              ['Bed Linen', 'Home Decor', 'Storage Solutions', 'Plants & Pots'],
              image: AssetConstants.homeLifestyle),
          _category('cat_clothes', 'Clothes', 'sec_household',
              Icons.checkroom, const Color(0xFF6B4FA0),
              ['T-Shirts', 'Jeans', 'Dresses', 'Jackets'],
              image: AssetConstants.clothes),
          _category('cat_cleaners_repellents', 'Cleaners & Repellents', 'sec_household',
              Icons.cleaning_services, const Color(0xFF2F7FC1),
              ['Floor Cleaners', 'Detergents', 'Dishwash', 'Mosquito Repellents'],
              image: AssetConstants.cleanersRepellents),
          _category('cat_electronics', 'Electronics', 'sec_household',
              Icons.headphones, const Color(0xFF4A4A4A),
              ['Earphones & Audio', 'Chargers & Cables', 'Batteries', 'Bulbs & Lights'],
              image: AssetConstants.electronicsCategory),
          _category('cat_stationery_games', 'Stationery & Games', 'sec_household',
              Icons.extension, const Color(0xFFD1352F),
              ['Notebooks & Pens', 'Board Games & Cards', 'Art Supplies', 'Toys'],
              image: AssetConstants.stationeryGames),
        ],
      ),
    ];
  }

  static CategoryModel _category(String id, String title, String sectionId,
      IconData icon, Color color, List<String> subCategoryTitles, {String? image}) {
    final subs = <SubCategoryModel>[];
    for (var i = 0; i < subCategoryTitles.length; i++) {
      subs.add(SubCategoryModel(
        id: '${id}_sub$i',
        title: subCategoryTitles[i],
        categoryId: id,
        icon: icon,
      ));
    }
    return CategoryModel(
      id: id,
      title: title,
      sectionId: sectionId,
      icon: icon,
      color: color,
      subCategories: subs,
      image: image,
    );
  }

  static const _brands = [
    'GoFresh',
    'FreshPick',
    'DailyBasket',
    'PureHome',
    'ValueMart',
    "Nature's Best",
  ];

  static const _weights = [
    '250 g',
    '500 g',
    '1 kg',
    '1 L',
    '500 ml',
    'Pack of 6',
    '200 ml',
    '2 pcs',
  ];

  static const _nutrition = [
    'Energy: 120 kcal',
    'Protein: 3 g',
    'Fat: 2 g',
    'Carbohydrates: 18 g',
  ];

  static const String _p = 'assets/images/products';

  static const Map<String, List<String>> _categoryImagePool = {
    'cat_clothes': [
      'assets/categories/clothes.png',
      'assets/categories/clothes.png',
      'assets/categories/clothes.png',
    ],
    'cat_biscuits': [
      '$_p/biscuit1.png',
      '$_p/biscuit2.png',
      '$_p/biscuit3.png',
      '$_p/cookie1.png',
      '$_p/cookie2.png',
      '$_p/cookie3.png',
    ],
    'cat_chips': [
      '$_p/chips1.png',
      '$_p/chips2.png',
      '$_p/chips3.png',
    ],
    'cat_oil_ghee_masala': [
      '$_p/oil.png',
      '$_p/saffola.png',
      '$_p/fortune.png',
      '$_p/daldaghee.png',
      '$_p/goverdhanghee.png',
      '$_p/garammasala.png',
      '$_p/kalimirch.png',
      '$_p/mdhmasala.png',
      '$_p/masala1.png',
      '$_p/masala2.png',
    ],
    'cat_dairy_bread_eggs': [
      '$_p/milk1.png',
      '$_p/milk2.png',
      '$_p/milk3.png',
      '$_p/bread1.png',
      '$_p/bread2.png',
      '$_p/pav1.png',
      '$_p/egg1.png',
      '$_p/egg2.png',
      '$_p/egg3.png',
      '$_p/butter1.png',
      '$_p/butter2.png',
      '$_p/butter3.png',
    ],
    'cat_bakery_biscuits': [
      '$_p/biscuit1.png',
      '$_p/biscuit2.png',
      '$_p/biscuit3.png',
      '$_p/cake1.png',
      '$_p/cake2.png',
      '$_p/cake3.png',
      '$_p/cookie1.png',
      '$_p/cookie2.png',
      '$_p/cookie3.png',
    ],
    'cat_dryfruits_cereals': [
      '$_p/dryfruit1.png',
      '$_p/dryfruit2.png',
      '$_p/dryfruit3.png',
      '$_p/dryfruit4.png',
      '$_p/dryfruit5.png',
      '$_p/dryfruit6.png',
      '$_p/dryfruit7.png',
      '$_p/dryfruit8.png',
    ],
    'cat_kitchenware': [
      '$_p/cookware1.png',
      '$_p/cookware2.png',
      '$_p/cookware3.png',
      '$_p/appliance1.png',
      '$_p/appliance2.png',
      '$_p/appliance3.png',
      '$_p/container1.png',
      '$_p/container2.png',
      '$_p/container3.png',
      '$_p/bottle1.png',
      '$_p/bottle2.png',
      '$_p/bottle3.png',
    ],
    'cat_chicken_meat_fish': [
      '$_p/chicken1.png',
      '$_p/chicken2.png',
      '$_p/chicken3.png',
      '$_p/mutton1.png',
      '$_p/mutton2.png',
      '$_p/mutton3.png',
      '$_p/fish1.png',
      '$_p/seafood1.png',
      '$_p/egg1.png',
      '$_p/egg2.png',
      '$_p/egg3.png',
    ],
    'cat_chips_namkeen': [
      '$_p/chips1.png',
      '$_p/chips2.png',
      '$_p/chips3.png',
      '$_p/namkeen1.png',
      '$_p/namkeen2.png',
      '$_p/namkeen3.png',
      '$_p/sev1.png',
      '$_p/sev2.png',
      '$_p/sev3.png',
      '$_p/popcorn1.png',
      '$_p/popcorn2.png',
      '$_p/popcorn3.png',
    ],
    'cat_sweets_choco': [
      '$_p/indiansweets1.png',
      '$_p/indiansweets2.png',
      '$_p/indiansweets3.png',
      '$_p/chocolate1.png',
      '$_p/chocolate2.png',
      '$_p/chocolate3.png',
      '$_p/gift1.png',
      '$_p/gift2.png',
      '$_p/gift3.png',
      '$_p/candies1.png',
      '$_p/candies2.png',
      '$_p/candies3.png',
    ],
    'cat_sauces_spreads': [
      '$_p/pickle.png',
      '$_p/ketup1.png',
      '$_p/sauce2.png',
      '$_p/jam1.png',
      '$_p/jam2.png',
      '$_p/jam3.png',
      '$_p/honey1.png',
      '$_p/honey2.png',
      '$_p/honey3.png',
      '$_p/butter1.png',
      '$_p/butter2.png',
      '$_p/butter3.png',
    ],
    'cat_drinks_juices': [
      '$_p/softdrink1.png',
      '$_p/softdrink2.png',
      '$_p/softdrink3.png',
      '$_p/fruitjuice.png',
      '$_p/fruitjuice2.png',
      '$_p/fruitjuice3.png',
      '$_p/energydrink1.png',
      '$_p/energydrink2.png',
      '$_p/energydrink3.png',
      '$_p/healthdrinks1.png',
      '$_p/healthdrinks2.png',
      '$_p/healthdrinks3.png',
    ],
    'cat_tea_coffee': [
      '$_p/tea1.png',
      '$_p/tea2.png',
      '$_p/tea3.png',
      '$_p/coffee1.png',
      '$_p/coffee2.png',
      '$_p/coffee3.png',
      '$_p/greentea1.png',
      '$_p/greentea2.png',
      '$_p/greentea3.png',
      '$_p/malt1.png',
      '$_p/malt2.png',
      '$_p/malt3.png',
    ],
    'cat_instant_food': [
      '$_p/instant1.png',
      '$_p/instant2.png',
      '$_p/instant3.png',
      '$_p/instant4.png',
      '$_p/instant5.png',
      '$_p/instant6.png',
      '$_p/frozen1.png',
      '$_p/frozen2.png',
      '$_p/frozen3.png',
      '$_p/soup1.png',
      '$_p/soup2.png',
      '$_p/soup3.png',
    ],
    'cat_paan_corner': [
      '$_p/sauf1.png',
      '$_p/sauf2.png',
      '$_p/sauf3.png',
      '$_p/supari1.png',
      '$_p/supari2.png',
      '$_p/supari3.png',
      '$_p/mint1.png',
      '$_p/mint2.png',
      '$_p/mint3.png',
    ],
    'cat_ice_creams': [
      '$_p/family1.png',
      '$_p/family2.png',
      '$_p/family3.png',
      '$_p/icecream1.png',
      '$_p/icecream2.png',
      '$_p/icecream3.png',
      '$_p/kulfi1.png',
      '$_p/kulfi2.png',
      '$_p/kulfi3.png',
    ],
    'cat_veg_fruits': [
      '$_p/vegetable1.png',
      '$_p/vegetable2.png',
      '$_p/vegetable3.png',
      '$_p/fruits1.png',
      '$_p/fruits2.png',
      '$_p/fruits3.png',
      '$_p/exoticfruits1.png',
      '$_p/exoticfruits2.png',
      '$_p/exoticfruits3.png',
      '$_p/organic1.png',
      '$_p/organic2.png',
      '$_p/organic3.png',
    ],
    'cat_atta_rice_dal': [
      '$_p/aata1.png',
      '$_p/aata2.png',
      '$_p/aata3.png',
      '$_p/rice1.png',
      '$_p/rice2.png',
      '$_p/rice3.png',
      '$_p/daal1.png',
      '$_p/daal2.png',
      '$_p/daal3.png',
      '$_p/sugar1.png',
      '$_p/sugar2.png',
      '$_p/sugar3.png',
    ],
    'cat_health_pharma': [
      '$_p/firstaid1.png',
      '$_p/firstaid2.png',
      '$_p/firstaid3.png',
      '$_p/medi2.png',
      '$_p/medi3.png',
      '$_p/protein1.png',
      '$_p/protein2.png',
      '$_p/protein3.png',
    ],
    'cat_bath_body': [
      '$_p/soap1.png',
      '$_p/soap2.png',
      '$_p/soap3.png',
      '$_p/bodylotion1.png',
      '$_p/bodylotio21.png',
      '$_p/bodylotio3.png',
      '$_p/talcumpowder.png',
      '$_p/talcumpowder2.png',
      '$_p/talcumpowder3.png',
      '$_p/deodrant1.png',
      '$_p/deodran2.png',
      '$_p/deodrant3.png',
    ],
    'cat_hair': [
      '$_p/shampoo1.png',
      '$_p/shampoo2.png',
      '$_p/shampoo3.png',
      '$_p/conditioner1.png',
      '$_p/conditioner2.png',
      '$_p/conditioner3.png',
      '$_p/hairoil1.png',
      '$_p/hairoil2.png',
      '$_p/hairoil3.png',
      '$_p/haircolour1.png',
      '$_p/haircolour2.png',
      '$_p/haircolour3.png',
    ],
    'cat_skin_face': [
      '$_p/facewash1.png',
      '$_p/facewash2.png',
      '$_p/facewash3.png',
      '$_p/moisturizer1.png',
      '$_p/moisturizer2.png',
      '$_p/moisturizer3.png',
      '$_p/sunscreen1.png',
      '$_p/sunscreen2.png',
      '$_p/sunscreen3.png',
      '$_p/facemask1.png',
      '$_p/facemask2.png',
      '$_p/facemask3.png',
    ],
    'cat_feminine_hygiene': [
      '$_p/pad1.png',
      '$_p/pad2.png',
      '$_p/pad3.png',
      '$_p/tampons1.png',
      '$_p/tampons2.png',
      '$_p/tampons3.png',
      '$_p/intimate1.png',
      '$_p/intimate2.png',
      '$_p/intimate3.png',
      '$_p/menstrualcup1.png',
      '$_p/menstrualcup2.png',
      '$_p/menstrualcup3.png',
    ],
    'cat_baby_care': [
      '$_p/diaper1.png',
      '$_p/diaper2.png',
      '$_p/diaper3.png',
      '$_p/babyfood.png',
      '$_p/babyfood2.png',
      '$_p/babyfood3.png',
      '$_p/babyskincare1.png',
      '$_p/babyskincare2.png',
      '$_p/babyskincare3.png',
      '$_p/babywipes1.png',
      '$_p/babywipes2.png',
      '$_p/babywipes3.png',
    ],
    'cat_home_lifestyle': [
      '$_p/bedlinen.png',
      '$_p/bedlinen2.png',
      '$_p/bedlinen3.png',
      '$_p/homedecore1.png',
      '$_p/homedecore2.png',
      '$_p/homedecore3.png',
      '$_p/storagesolution1.png',
      '$_p/storagesolution2.png',
      '$_p/storagesolution3.png',
      '$_p/plant1.png',
      '$_p/plant2.png',
      '$_p/plant3.png',
    ],
    'cat_cleaners_repellents': [
      '$_p/floorcleanser1.png',
      '$_p/floorcleanser2.png',
      '$_p/floorcleanser3.png',
      '$_p/detergent1.png',
      '$_p/detergent2.png',
      '$_p/detergent3.png',
      '$_p/dishwash1.png',
      '$_p/dishwash2.png',
      '$_p/dishwash3.png',
      '$_p/Mosquitorepellents1.png',
      '$_p/Mosquitorepellents2.png',
      '$_p/Mosquitorepellents3.png',
    ],
    'cat_electronics': [
      '$_p/earphone1.png',
      '$_p/earphone2.png',
      '$_p/earphone3.png',
      '$_p/charger1.png',
      '$_p/charger2.png',
      '$_p/charger3.png',
      '$_p/batteries1.png',
      '$_p/batteries2.png',
      '$_p/batteries3.png',
      '$_p/bulb1.png',
      '$_p/bulb2.png',
      '$_p/bulb3.png',
    ],
    'cat_stationery_games': [
      '$_p/notebook1.png',
      '$_p/notebook2.png',
      '$_p/notebook3.png',
      '$_p/cards1.png',
      '$_p/cards2.png',
      '$_p/cards3.png',
      '$_p/art1.png',
      '$_p/art2.png',
      '$_p/art3.png',
      '$_p/toys1.png',
      '$_p/toys2.png',
      '$_p/toys3.png',
    ],
  };

  static const Map<String, List<String>> _categoryProductNames = {
    'cat_veg_fruits': [
      'Mixed Vegetables', 'Fresh Tomatoes', 'Fresh Onions',
      'Apples', 'Bananas', 'Oranges',
      'Kiwi', 'Dragon Fruit', 'Avocado',
      'Organic Spinach', 'Organic Carrots', 'Organic Tomatoes',
    ],
    'cat_atta_rice_dal': [
      'Aashirvaad Atta', 'Whole Wheat Atta', 'Multigrain Atta',
      'Basmati Rice', 'Sona Masoori Rice', 'Brown Rice',
      'Toor Dal', 'Moong Dal', 'Chana Dal',
      'Sugar', 'Brown Sugar', 'Jaggery',
    ],
    'cat_oil_ghee_masala': [
      'Sunflower Oil', 'Saffola Gold Oil', 'Fortune Oil',
      'Dalda Ghee', 'Goverdhan Ghee', 'Garam Masala',
      'Kali Mirch', 'MDH Masala', 'Chana Masala', 'Chicken Masala',
    ],
    'cat_dairy_bread_eggs': [
      'Farm Eggs (6 pcs)', 'Farm Eggs (12 pcs)',
    ],
    'cat_bakery_biscuits': [
      'Parle-G Biscuits', 'Marie Gold Biscuits', 'Good Day Biscuits',
      'Chocolate Cake', 'Vanilla Cake', 'Fruit Cake',
      'Chocolate Chip Cookies', 'Butter Cookies', 'Oatmeal Cookies',
    ],
    'cat_dryfruits_cereals': [
      'Almonds', 'Cashews', 'Raisins', 'Dates',
      'Pistachios', 'Walnuts', 'Corn Flakes', 'Muesli',
    ],
    'cat_kitchenware': [
      'Non-Stick Pan', 'Pressure Cooker', 'Kadai',
      'Mixer Grinder', 'Toaster', 'Electric Kettle',
      'Storage Container Set', 'Airtight Jar', 'Lunch Box',
      'Water Bottle', 'Steel Bottle', 'Sports Bottle',
    ],
    'cat_chicken_meat_fish': [
      'Chicken Curry Cut', 'Chicken Breast', 'Chicken Drumsticks',
      'Mutton Curry Cut', 'Mutton Boneless', 'Mutton Chops',
      'Fish Fillet', 'Prawns',
      'Farm Eggs', 'Brown Eggs', 'Boiled Eggs',
    ],
    'cat_chips_namkeen': [
      'Lays Chips', 'Bingo Chips', 'Kurkure',
      'Haldiram Namkeen', 'Bikaji Namkeen', 'Aloo Bhujia',
      'Sev', 'Moong Dal Sev', 'Ratlami Sev',
      'Butter Popcorn', 'Caramel Popcorn', 'Masala Popcorn',
    ],
    'cat_sweets_choco': [
      'Kaju Katli', 'Gulab Jamun', 'Rasgulla',
      'Dairy Milk Chocolate', 'KitKat', 'Ferrero Rocher',
      'Chocolate Gift Box', 'Sweets Gift Pack', 'Assorted Gift Box',
      'Eclairs Candy', 'Alpenliebe Candy', 'Mango Bite Candy',
    ],
    'cat_sauces_spreads': [
      'Mango Pickle', 'Tomato Ketchup', 'Chilli Sauce',
      'Mixed Fruit Jam', 'Strawberry Jam', 'Orange Marmalade',
      'Pure Honey', 'Dabur Honey', 'Organic Honey',
      'Crunchy Peanut Butter', 'Creamy Peanut Butter', 'Sundrop Peanut Butter',
    ],
    'cat_drinks_juices': [
      'Coca-Cola', 'Pepsi', 'Sprite',
      'Real Fruit Juice', 'Tropicana Juice', 'Mixed Fruit Juice',
      'Red Bull', 'Monster Energy', 'Sting Energy Drink',
      'Bournvita Health Drink', 'Horlicks', 'Complan',
    ],
    'cat_tea_coffee': [
      'Tata Tea', 'Red Label Tea', 'Taj Mahal Tea',
      'Nescafe Coffee', 'Bru Coffee', 'Filter Coffee',
      'Green Tea Lemon', 'Green Tea Tulsi', 'Green Tea Classic',
      'Bournvita Malt', 'Horlicks Malt', 'Boost Malt',
    ],
    'cat_instant_food': [
      'Maggi Noodles', 'Yippee Noodles', 'Top Ramen',
      'Pasta', 'Macaroni', 'Vermicelli',
      'Frozen Paratha', 'Frozen Samosa', 'Frozen Momos',
      'Tomato Soup', 'Sweet Corn Soup', 'Hot and Sour Soup',
    ],
    'cat_paan_corner': [
      'Sonf', 'Roasted Sonf', 'Sweet Sonf',
      'Supari', 'Meetha Supari', 'Kharaa Supari',
      'Mint Mouth Freshener', 'Polo Mints', 'Center Fresh Mints',
    ],
    'cat_ice_creams': [
      'Vanilla Family Pack', 'Chocolate Family Pack', 'Butterscotch Family Pack',
      'Cup Ice Cream', 'Cone Ice Cream', 'Stick Ice Cream',
      'Malai Kulfi', 'Pista Kulfi', 'Mango Kulfi',
    ],
  };

  /// Returns a real product image path for [categoryId] at position
  /// [index] (cycles through the pool), or null if no pool exists for
  /// that category. Used to give backend products (which may have an
  /// empty image_url) a real photo instead of a blank placeholder.
  static String? imageForCategory(String categoryId, int index) {
    final pool = _categoryImagePool[categoryId];
    if (pool == null || pool.isEmpty) return null;
    return pool[index % pool.length];
  }

  /// Finds a category by its display title (case-insensitive) and picks
  /// a fallback image whose subcategory best matches [productName], for
  /// backend products whose own image_url is empty. Returns null if no
  /// matching category is found. [fallbackIndex] (e.g. the product's own
  /// id) spreads products with no name match across different photos.
  static String? imageForProductByCategoryTitle(
      String categoryTitle, String productName, int fallbackIndex) {
    CategoryModel? category;
    for (final section in sections) {
      for (final c in section.categories) {
        if (c.title.toLowerCase() == categoryTitle.toLowerCase()) {
          category = c;
          break;
        }
      }
      if (category != null) break;
    }
    if (category == null) return null;

    final subs = category.subCategories;
    var subIndex = subs.isEmpty ? 0 : fallbackIndex % subs.length;
    final nameLower = productName.toLowerCase();
    for (var s = 0; s < subs.length; s++) {
      final words = subs[s]
          .title
          .toLowerCase()
          .split(RegExp(r'[ &,]+'))
          .where((w) => w.length > 2);
      for (final word in words) {
        if (nameLower.contains(word)) {
          subIndex = s;
          break;
        }
      }
    }
    final poolIndex = subIndex * 3 + (fallbackIndex % 3);
    return imageForCategory(category.id, poolIndex);
  }


  /// Generates a handful of realistic-looking products per subcategory
  /// so every category/subcategory has something to show in the grid.
  static List<ProductModel> _productsFor(CategoryModel category) {
    final products = <ProductModel>[];
    final pool = _categoryImagePool[category.id];
    final namePool = _categoryProductNames[category.id];
    for (var i = 0; i < category.subCategories.length; i++) {
      final sub = category.subCategories[i];
      for (var j = 0; j < 3; j++) {
        final index = i * 3 + j;
        final price = 39.0 + ((index * 17) % 260);
        final mrp = price + 10 + ((index % 5) * 8);
        products.add(ProductModel(
          id: '${sub.id}_p$j',
          name: (namePool != null && namePool.isNotEmpty) ? namePool[index % namePool.length] : '${sub.title} Pack ${j + 1}',
          brand: _brands[index % _brands.length],
          weight: _weights[index % _weights.length],
          price: price,
          mrp: mrp,
          rating: 3.4 + ((index % 15) / 10),
          ratingCount: 18 + index * 7,
          icon: category.icon,
          color: category.color,
          categoryId: category.id,
          subCategoryId: sub.id,
          description:
              'Quality-checked ${sub.title.toLowerCase()} sourced for your everyday needs. '
              'Carefully packed and delivered fresh to your doorstep.',
          nutrition: _nutrition,
          deliveryTime: index.isEven ? '8 mins' : '15 mins',
          inStock: index % 11 != 0,
          image: (pool != null && pool.isNotEmpty) ? pool[index % pool.length] : null,
        ));
      }
    }
    return products;
  }

  static List<ProductModel> productsForCategory(String categoryId) {
    final category = sections
        .expand((s) => s.categories)
        .firstWhere((c) => c.id == categoryId);
    return _productsFor(category);
  }
}


