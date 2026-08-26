import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../features/category_nav/data/category_mock_data.dart';
import '../features/category_nav/models/category_models.dart';
import '../features/category_nav/providers/category_nav_provider.dart';
import '../features/category_nav/widgets/category_placeholder_image.dart';
import '../features/category_nav/widgets/product_card.dart';
import '../features/category_nav/widgets/skeleton_grid.dart';
import '../features/category_nav/screens/product_details_screen.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String? initialCategory;
  const CategoriesScreen({super.key, this.initialCategory});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final List<CategoryModel> _categories = CategoryMockData.sections
      .expand((s) => s.categories)
      .toList();

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      final index = _categories.indexWhere((c) => c.title == widget.initialCategory);
      if (index != -1) {
        _selectedIndex = index;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryNavProvider>().openCategory(_categories[_selectedIndex]);
    });
  }

  void _selectCategory(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    context.read<CategoryNavProvider>().openCategory(_categories[index]);
  }

  String _cartImageUrl(dynamic item) {
    final product = item['product'] ?? {};
    final raw = product['image_url']?.toString() ?? '';
    if (raw.isEmpty) return 'assets/images/placeholder.png';
    if (raw.startsWith('http') || raw.startsWith('assets/')) return raw;
    final host = ApiService.baseUrl.replaceAll('/api/v1', '');
    return '$host$raw';
  }

  Widget _buildThumbImage(String imagePath, {double height = 40}) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: height,
        width: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          width: height,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 16),
        ),
      );
    } else {
      return Image.network(
        imagePath,
        height: height,
        width: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          width: height,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 16),
        ),
      );
    }
  }

  Widget _buildCartThumbnails(CartProvider cart) {
    final images = [
      ...cart.items.map((item) => _cartImageUrl(item)),
      ...cart.localCartItems.map((item) => (item['image'] ?? '').toString()),
    ].take(2).toList();
    if (images.isEmpty) return const SizedBox(width: 0, height: 40);
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
                  child: _buildThumbImage(images[i], height: 40),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryNavProvider>();
    final products = provider.visibleProducts;
    final cart = context.watch<CartProvider>();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          title: Text('Categories',
              style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        ),
        body: Row(
          children: [
            Container(
              width: 90,
              color: Theme.of(context).colorScheme.surface,
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () => _selectCategory(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0C831F).withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border(
                          left: BorderSide(
                            color: isSelected ? const Color(0xFF0C831F) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: (cat.image != null && cat.image!.isNotEmpty)
                                  ? Image.asset(
                                      cat.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => CategoryPlaceholderImage(
                                        icon: cat.icon,
                                        color: cat.color,
                                        size: 64,
                                        borderRadius: 16,
                                      ),
                                    )
                                  : CategoryPlaceholderImage(
                                      icon: cat.icon,
                                      color: cat.color,
                                      size: 64,
                                      borderRadius: 16,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(cat.title,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF0C831F) : Colors.grey),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: _buildBody(context, provider, products),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                break;
              case 1:
                break;
              case 2:
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                break;
            }
          },
          selectedItemColor: const Color(0xFF0C831F),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
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
                          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
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
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('${cart.cartCount} item${cart.cartCount > 1 ? 's' : ''}',
                                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(width: 18),
                          const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, CategoryNavProvider provider, List<ProductModel> products) {
    if (provider.productStatus == LoadStatus.loading || provider.productStatus == LoadStatus.idle) {
      return const SkeletonGrid(itemCount: 6);
    }

    if (provider.productStatus == LoadStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('Something went wrong.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: provider.retry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Coming Soon!',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
          ),
        );
      },
    );
  }
}