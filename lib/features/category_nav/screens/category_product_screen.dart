import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../widgets/state_views.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/api_service.dart';
import '../../../screens/cart_screen.dart';
import '../models/category_models.dart';
import '../providers/category_nav_provider.dart';
import '../routes/category_nav_routes.dart';
import '../widgets/category_placeholder_image.dart';
import '../widgets/category_search_filter_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton_grid.dart';
import '../widgets/subcategory_chips.dart';

class CategoryProductScreen extends StatefulWidget {
  final CategoryModel category;
  const CategoryProductScreen({super.key, required this.category});

  @override
  State<CategoryProductScreen> createState() => _CategoryProductScreenState();
}

class _CategoryProductScreenState extends State<CategoryProductScreen> {
  static const _pageSize = 8;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryNavProvider>().openCategory(widget.category);
    });
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
    final category = widget.category;
    final allVisible = provider.visibleProducts;
    final shown = allVisible.take(_visibleCount).toList();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildBanner(context, category),
            CategorySearchBar(categoryTitle: category.title),
            const FilterSortBar(),
            const SizedBox(height: 10),
            SubcategoryChips(
              subCategories: category.subCategories,
              selected: provider.activeSubCategory,
              onSelected: (sub) {
                provider.selectSubCategory(sub);
                setState(() => _visibleCount = _pageSize);
              },
            ),
            const SizedBox(height: 6),
            Expanded(child: _buildBody(context, provider, shown, allVisible.length)),
          ],
        ),
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
    );
  }

  Widget _buildBanner(BuildContext context, CategoryModel category) {
    return Container(
      color: category.color.withValues(alpha: 0.10),
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (category.image != null && category.image!.isNotEmpty)
                ? Image.asset(
                    category.image!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => CategoryPlaceholderImage(
                        icon: category.icon, color: category.color, size: 44, borderRadius: 12),
                  )
                : CategoryPlaceholderImage(
                    icon: category.icon, color: category.color, size: 44, borderRadius: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(category.title,
                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, CategoryNavProvider provider, List shownRaw, int totalCount) {
    final shown = shownRaw.cast<ProductModel>();

    if (provider.productStatus == LoadStatus.loading || provider.productStatus == LoadStatus.idle) {
      return const SkeletonGrid(itemCount: 6);
    }

    if (provider.productStatus == LoadStatus.error) {
      return ErrorView(
        message: 'Something went wrong while loading products.',
        onRetry: provider.retry,
      );
    }

    if (provider.productStatus == LoadStatus.empty || shown.isEmpty) {
      return const EmptyView(icon: Icons.shopping_basket_outlined, message: 'No products found here.');
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shown.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final product = shown[index];
            return ProductCard(
              product: product,
              onTap: () => CategoryNavRoutes.openProductDetails(context, product),
            );
          },
        ),
        if (_visibleCount < totalCount)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: OutlinedButton(
                onPressed: () => setState(() => _visibleCount += _pageSize),
                child: Text('Load more', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
      ],
    );
  }
}