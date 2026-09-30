import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../features/category_nav/repositories/category_repository.dart';
import 'select_location_screen.dart';
import '../constants/asset_constants.dart';
import 'cart_screen.dart';
import 'search_screen.dart';
import 'categories_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import '../widgets/wishlist_intro_sheet.dart';
import '../features/category_nav/screens/home_category_sections.dart';
import '../features/category_nav/data/category_mock_data.dart';
import '../features/category_nav/models/category_models.dart';
import '../features/category_nav/routes/category_nav_routes.dart';
import '../features/category_nav/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  final bool showWishlistIntro;
  const HomeScreen({super.key, this.showWishlistIntro = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _currentAddress = 'Mumbai, Maharashtra';
  bool _loadingLocation = false;

  Future<void> _openSelectLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SelectLocationScreen()),
    );
    if (result == null || !mounted) return;
    final address = result['address'] as String?;
    final lat = (result['lat'] as num?)?.toDouble();
    final lng = (result['lng'] as num?)?.toDouble();
    if (address != null) setState(() => _currentAddress = address);
    if (lat != null && lng != null) {
      CategoryRepository.updateLocation(lat, lng);
      context.read<ProductProvider>().loadProducts();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProductProvider>().loadProducts();
    });
    if (widget.showWishlistIntro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showWishlistIntro(context);
      });
    }
  }

  String _cartImageUrl(dynamic item) {
    final product = item['product'] ?? {};
    final raw = product['image_url']?.toString() ?? '';
    if (raw.isEmpty) return 'assets/images/placeholder.png';
    if (raw.startsWith('http') || raw.startsWith('assets/')) return raw;
    final host = ApiService.baseUrl.replaceAll('/api/v1', '');
    return '$host$raw';
  }

  Widget _buildImage(String imagePath, {double height = 110}) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          final pngPath = imagePath.replaceAll('.jpg', '.png');
          if (pngPath != imagePath) {
            return Image.asset(
              pngPath,
              height: height,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: height,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            );
          }
          return Container(
            height: height,
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imagePath,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          height: height,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1B5E20),
                    Color(0xFF1B5E20),
                    Color(0xFF7CB342),
                    Color(0xFFC5E1A5),
                    Color(0xFFFFFFFF),
                  ],
                  stops: [0.0, 0.22, 0.45, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.bolt, color: Colors.white, size: 14),
                                  Text('Delivery in 10 minutes',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              GestureDetector(
                                onTap: _loadingLocation ? null : _openSelectLocation,
                                child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white, size: 14),
                                  Flexible(child: Text(_loadingLocation ? 'Fetching...' : _currentAddress, overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                                ],
                              ),
                              ),
                            ],
                          ),
                          ),
                          Row(
                            children: [
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                                    onPressed: () => Navigator.push(
                                        context, MaterialPageRoute(builder: (_) => const CartScreen())),
                                  ),
                                  if (cart.cartCount > 0)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                            color: Color(0xFF0C831F), shape: BoxShape.circle),
                                        child: Text('${cart.cartCount}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Search groceries, snacks...',
                                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1672 / 941,
                  child: Image.asset(
                    'assets/images/banners/promo_banner.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const HomeCategorySections(),

            _buildPromoBanner(),

            _buildProductSection('Fresh Fruits', 'Fruits'),
            _buildProductSection('Ice Creams', 'Ice Creams'),
            _buildProductSection('Chocolate', 'Chocolate'),

            _buildOffersSection(),

            _buildEventsSection(),

            _buildProductSection('Snacks', 'Snacks'),
            _buildProductSection('Beverages', 'Beverages'),
            _buildProductSection('Biscuits', 'Biscuits'),
            _buildProductSection('Namkeen', 'Namkeen'),
            _buildProductSection('Wafers', 'Wafers'),
            _buildProductSection('Cold Drinks', 'Cold Drinks'),
            _buildProductSection('Ketchup', 'Ketchup'),

            _buildSlidingPromoSection(),
              ],
            ),
          ),
          _buildFeaturedProductsHeaderSliver(),
          _buildFeaturedProductsSliverGrid(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

            _buildProductSection('Shampoo', 'Shampoo'),
            _buildProductSection('Soap', 'Soap'),
            _buildProductSection('Personal Care', 'Personal Care'),
            _buildProductSection('Pickle', 'Pickle'),
            _buildProductSection('Puja Items', 'Puja Items'),
            _buildProductSection('Toys', 'Toys'),
            _buildProductSection('Clothes', 'Clothes'),
            const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          switch (index) {
            case 0:
              setState(() => _currentIndex = 0);
              break;
            case 1:
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()));
              if (mounted) setState(() => _currentIndex = 0);
              break;
            case 2:
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
              if (mounted) setState(() => _currentIndex = 0);
              break;
          }
        },
        selectedItemColor: const Color(0xFF0C831F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
        GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: cart.cartCount > 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C831F),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCartThumbnails(cart),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('View cart',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            Text(
                                '${cart.cartCount} item${cart.cartCount > 1 ? 's' : ''}',
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(width: 18),
                        const Icon(Icons.chevron_right,
                            color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCartThumbnails(CartProvider cart) {
    final images = [
      ...cart.items.map((item) => _cartImageUrl(item)),
      ...cart.localCartItems.map((item) => (item['image'] ?? '').toString()),
    ].take(2).toList();
    return SizedBox(
      width: images.length > 1 ? 54 : 40,
      height: 40,
      child: Stack(
        children: [
          for (int i = 0; i < images.length; i++)
            Positioned(
              left: i * 22.0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: _buildImage(images[i], height: 40),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOffersSection() {
    final List<Map<String, dynamic>> offers = [
      {
        'icon': Icons.local_shipping_rounded,
        'badge': 'HOT',
        'badgeColor': const Color(0xFFE53935),
        'bgColor': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF43A047),
        'title': 'FREE DELIVERY',
        'subtitle': 'Above Rs.199',
      },
      {
        'icon': Icons.account_balance_wallet_rounded,
        'badge': 'NEW',
        'badgeColor': const Color(0xFF1E88E5),
        'bgColor': const Color(0xFFE3F2FD),
        'iconColor': const Color(0xFF1E88E5),
        'title': '10% CASHBACK',
        'subtitle': 'UPI Payment',
      },
      {
        'icon': Icons.card_giftcard_rounded,
        'badge': 'BEST',
        'badgeColor': const Color(0xFFFB8C00),
        'bgColor': const Color(0xFFFFF3E0),
        'iconColor': const Color(0xFFFB8C00),
        'title': 'Rs.100 OFF',
        'subtitle': 'Above Rs.999',
      },
      {
        'icon': Icons.local_offer_rounded,
        'badge': 'SALE',
        'badgeColor': const Color(0xFF8E24AA),
        'bgColor': const Color(0xFFF3E5F5),
        'iconColor': const Color(0xFF8E24AA),
        'title': 'Rs.200 OFF',
        'subtitle': 'Above Rs.1999',
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Text('Coupons & Offers',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: offers.length,
            itemBuilder: (context, i) {
              final offer = offers[i];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: offer['bgColor'],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: offer['badgeColor'],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(offer['badge'],
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(offer['icon'], color: offer['iconColor'], size: 26),
                        const Spacer(),
                        Text(offer['title'],
                            style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 2),
                        Text(offer['subtitle'],
                            style: GoogleFonts.poppins(
                                fontSize: 10.5, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEventsSection() {
    final List<Map<String, dynamic>> events = [
      {
        'title': 'Mango Festival',
        'subtitle': 'Most awaited festival is on!',
        'badge': null,
        'image': 'assets/events/mango_festival.png',
      },
      {
        'title': 'Monsoon Bites',
        'subtitle': 'Hot pakoda, chai & more',
        'badge': null,
        'image': 'assets/events/monsoon_bites.png',
      },
      {
        'title': 'Healthy Breakfast',
        'subtitle': 'Start your day right',
        'badge': null,
        'image': 'assets/events/healthy_breakfast.png',
      },
      {
        'title': 'Summer Drinks',
        'subtitle': '50% OFF, order now',
        'badge': 'SALE',
        'image': 'assets/events/summer_drinks.png',
      },
    ];

    Widget eventCard(Map<String, dynamic> event,
        {double height = 96, double titleSize = 13, double subtitleSize = 10.5}) {
      return Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              event['image'],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            if (event['badge'] != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(event['badge'],
                      style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(event['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  if (event['subtitle'] != null)
                    Text(event['subtitle'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Events this week',
              style:
                  GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          eventCard(events[0], height: 140, titleSize: 16, subtitleSize: 11.5),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: eventCard(events[1], height: 120)),
              const SizedBox(width: 8),
              Expanded(child: eventCard(events[2], height: 120)),
              const SizedBox(width: 8),
              Expanded(child: eventCard(events[3], height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  CategoryModel? _findCategoryById(String id) {
    for (final section in CategoryMockData.sections) {
      for (final cat in section.categories) {
        if (cat.id == id) return cat;
      }
    }
    return null;
  }

  Widget _promoTile(String categoryId, String label, String imagePath, Color color) {
    return GestureDetector(
      onTap: () {
        const categoryScreenMap = {
          'cat_veg_fruits': 'Fruits',
          'cat_dairy_bread_eggs': 'Dairy, Bread & Eggs',
          'cat_chips_namkeen': 'Namkeen',
          'cat_cleaners_repellents': 'Cleaners & Repellents',
        };
        final target = categoryScreenMap[categoryId];
        if (target != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CategoriesScreen(initialCategory: target)),
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.image_not_supported, color: color, size: 30),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF3DC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock up your kitchen!',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Fresh groceries, snacks & essentials, delivered fast',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              SizedBox(
                width: 64,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.shopping_basket, size: 48, color: const Color(0xFF0C831F)),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(Icons.local_grocery_store, size: 26, color: const Color(0xFFE0592A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _promoTile('cat_veg_fruits', 'Fruits & Vegetables', AssetConstants.vegetablesFruits, const Color(0xFF3AA655)),
              _promoTile('cat_dairy_bread_eggs', 'Dairy, Bread & Eggs', AssetConstants.dairyBreadEggs, const Color(0xFF2F8FD1)),
              _promoTile('cat_chips_namkeen', 'Namkeen', AssetConstants.namkeen, const Color(0xFFE0A72A)),
              _promoTile('cat_cleaners_repellents', 'Cleaners & Repellents', AssetConstants.cleanersRepellents, const Color(0xFF2F7FC1)),
            ],
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _slidingPromos = [
    {
      'title': 'Herbal Living',
      'subtitle': 'Support your everyday wellness with herbs',
      'image': 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800',
      'bgColor': Color(0xFFF3ECE0),
      'textColor': Colors.black,
    },
    {
      'title': 'Dark Cocoa Affair',
      'subtitle': 'Enjoy a bite of your favourite dark chocolate',
      'image': 'https://images.unsplash.com/photo-1511381939415-e44015466834?w=800',
      'bgColor': Color(0xFF241208),
      'textColor': Colors.white,
    },
    {
      'title': '1 year of CeraVe on Blinkit!',
      'subtitle': 'Dermat recommended skincare routine',
      'image': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800',
      'bgColor': Color(0xFF9DA3A6),
      'textColor': Colors.white,
    },
    {
      'title': 'Up to 70% OFF on bags',
      'subtitle': 'Get laptop bags, tote bags & more',
      'image': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800',
      'bgColor': Color(0xFFEDE3C8),
      'textColor': Colors.black,
    },
  ];

  Widget _buildSlidingPromoSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 180,
          // autoPlay disabled: carousel_slider has a known bug where its
          // internal auto-play Timer fires after the widget is disposed
          // (e.g. during a fast navigation transition right after login),
          // throwing "Null check operator used on a null value" and
          // corrupting the whole render tree. Manual swipe still works.
          autoPlay: false,
          enlargeCenterPage: true,
          autoPlayInterval: const Duration(seconds: 3),
          viewportFraction: 0.88,
        ),
        items: _slidingPromos.map((promo) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: promo['bgColor'],
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 220,
                    child: CachedNetworkImage(
                      imageUrl: promo['image'],
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const SizedBox(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(promo['title'],
                                style: GoogleFonts.poppins(
                                    color: promo['textColor'],
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 170,
                              child: Text(promo['subtitle'],
                                  style: GoogleFonts.poppins(
                                      color: promo['textColor'].withOpacity(0.75),
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CategoriesScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: promo['textColor'] == Colors.white
                                  ? Colors.white
                                  : Colors.black,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text('Shop now',
                                style: GoogleFonts.poppins(
                                    color: promo['textColor'] == Colors.white
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedProductsHeaderSliver() {
    final products = context.watch<ProductProvider>().products;
    if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Text('Recommended for you',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFeaturedProductsSliverGrid() {
    final products = context.watch<ProductProvider>().products;
    if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.46,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
              final product = products[index];
              final cart = context.watch<CartProvider>();
              final qty = cart.getQuantityByProductId(product['id']);
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product, allProducts: products))),

                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: _buildImage(product['image'], height: 90),
                          ),
                          if (product['inStock'] == false)
                            Positioned(
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Out of stock',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 38, child: Text(product['name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
                            const SizedBox(height: 4),
                            Text('\u20b9${product['price']}',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            (product['inStock'] == false)
                                ? GestureDetector(
                                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('We will notify you'))),
                                    child: Container(
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFF0C831F)),
                                          borderRadius: BorderRadius.circular(6)),
                                      child: Text('Notify',
                                          style: GoogleFonts.poppins(color: const Color(0xFF0C831F), fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                : qty == 0
                                ? GestureDetector(
                                    onTap: () => context.read<CartProvider>().increment(product['id'], productData: product),
                                    child: Container(
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF0C831F),
                                          borderRadius: BorderRadius.circular(6)),
                                      child: Text('ADD',
                                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF0C831F),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () => context.read<CartProvider>().decrement(product['id']),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.remove, color: Colors.white, size: 14),
                                          ),
                                        ),
                                        Text('$qty',
                                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                        GestureDetector(
                                          onTap: () => context.read<CartProvider>().increment(product['id'], productData: product),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.add, color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
          },
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildProductSection(String title, String category) {
    final allProducts = context.watch<ProductProvider>().products;
    final items = allProducts.where((p) => p['category'] == category).toList();
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CategoriesScreen(initialCategory: category),
                    ),
                  );
                },
                child: Text('See all',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: const Color(0xFF0C831F))),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final product = items[index];
              final qty =
              context.watch<CartProvider>().getQuantityByProductId(product['id']);
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      product: product,
                      allProducts: items,
                    ),
                  ),
                ),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 36) / 3,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.1), blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: _buildImage(product['image']),
                          ),
                          if (product['inStock'] == false)
                            Positioned(
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Out of stock',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product['name'],
                                style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(product['unit'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rs.${product['price']}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0C831F))),
                                qty == 0
                                    ? GestureDetector(
                                  onTap: () {
                                  context.read<CartProvider>().increment(product['id'], productData: product);
                                },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF0C831F),
                                        borderRadius:
                                        BorderRadius.circular(8)),
                                    child: Text('ADD',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight:
                                            FontWeight.bold)),
                                  ),
                                )
                                    : Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => context
                                          .read<CartProvider>()
                                          .decrement(product['id']),
                                      child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                              color: const Color(
                                                  0xFF0C831F),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  6)),
                                          child: const Icon(Icons.remove,
                                              color: Colors.white,
                                              size: 16)),
                                    ),
                                    Padding(
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6),
                                        child: Text('$qty',
                                            style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight.bold))),
                                    GestureDetector(
                                      onTap: () => context
                                          .read<CartProvider>()
                                          .increment(product['id'], productData: product),
                                      child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                              color: const Color(
                                                  0xFF0C831F),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  6)),
                                          child: const Icon(Icons.add,
                                              color: Colors.white,
                                              size: 16)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}


