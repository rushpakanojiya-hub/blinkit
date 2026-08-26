import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/state_views.dart';
import '../models/category_models.dart';
import '../providers/category_nav_provider.dart';
import '../routes/category_nav_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/category_placeholder_image.dart';
import '../widgets/product_card.dart';
import '../../../screens/cart_screen.dart';
import '../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../wishlist/domain/entities/wishlist_item_entity.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _pageController = PageController();
  int _page = 0;
  late Future<List<ProductModel>> _similarFuture;

  @override
  void initState() {
    super.initState();
    _similarFuture = context.read<CategoryNavProvider>().fetchSimilarProducts(widget.product);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  WishlistItemEntity _toWishlistItem(ProductModel product) {
    return WishlistItemEntity(
      id: product.id,
      productId: product.id,
      name: product.name,
      imageUrl: product.image ?? '',
      price: product.price,
      mrp: product.mrp,
      discountPercent: product.discountPercent,
      rating: product.rating,
      ratingCount: product.ratingCount,
      inStock: product.inStock,
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final qty = cart.getQuantityByProductId(product.id);
    final wishlist = context.watch<WishlistProvider>();
    final isWishlisted = wishlist.isWishlisted(product.id);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildImageCarousel(product),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 13, color: Colors.black54),
                                  const SizedBox(width: 4),
                                  Text('Delivery in ${product.deliveryTime}',
                                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (!product.inStock)
                              Text('Out of stock',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(product.name,
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${product.brand} \u2022 ${product.weight}',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            Text('${product.rating.toStringAsFixed(1)} (${product.ratingCount} ratings)',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\u20b9${product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            if (product.mrp > product.price) ...[
                              Text('\u20b9${product.mrp.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough)),
                              const SizedBox(width: 8),
                              Text('${product.discountPercent}% OFF',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, fontWeight: FontWeight.bold, color: kGreen)),
                            ],
                          ],
                        ),
                        const Divider(height: 32),
                        Text('Product description',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(product.description,
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700], height: 1.5)),
                        const Divider(height: 32),
                        Text('Nutritional information',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...product.nutrition.map((line) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('\u2022 $line',
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                            )),
                        const Divider(height: 32),
                        Text('Similar products',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildSimilarProducts(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomBar(context, product, qty),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text('Product details',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
        actions: [
          IconButton(
            onPressed: () =>
                context.read<WishlistProvider>().toggle(_toWishlistItem(product)),
            icon: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: isWishlisted ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(ProductModel product) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: 3,
            itemBuilder: (context, index) => Center(
              child: (product.image != null && product.image!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: product.image!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: product.image!,
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                              errorWidget: (_, __, ___) => CategoryPlaceholderImage(
                                icon: product.icon,
                                color: product.color,
                                size: 160,
                                borderRadius: 24,
                              ),
                            )
                          : Image.asset(
                              product.image!,
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => CategoryPlaceholderImage(
                                icon: product.icon,
                                color: product.color,
                                size: 160,
                                borderRadius: 24,
                              ),
                            ),
                    )
                  : CategoryPlaceholderImage(
                      icon: product.icon,
                      color: product.color,
                      size: 160,
                      borderRadius: 24,
                    ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? kGreen : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts() {
    return SizedBox(
      height: 240,
      child: FutureBuilder<List<ProductModel>>(
        future: _similarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyView(icon: Icons.inventory_2_outlined, message: 'No similar products.');
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: 150,
                child: ProductCard(
                  product: item,
                  onTap: () => CategoryNavRoutes.openProductDetails(context, item),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ProductModel product, int qty) {
    final cart = context.watch<CartProvider>();
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CartScreen())),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                    if (cart.cartCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                          child: Center(
                            child: Text('${cart.cartCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: qty == 0
                  ? ElevatedButton(
                      onPressed: (!product.inStock || int.tryParse(product.id) == null)
                          ? null
                          : () => cart.increment(product.id, productData: productCartData(product)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(int.tryParse(product.id) == null ? 'Coming Soon' : 'Add to Cart',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => cart.decrement(product.id),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Icon(Icons.remove, color: Colors.white, size: 20),
                            ),
                          ),
                          Text('$qty',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () => cart.increment(product.id, productData: productCartData(product)),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
