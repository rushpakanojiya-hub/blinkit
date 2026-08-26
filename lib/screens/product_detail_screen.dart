import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../features/wishlist/presentation/providers/wishlist_provider.dart';
import '../features/wishlist/domain/entities/wishlist_item_entity.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> allProducts;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.allProducts = const [],
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _highlightsExpanded = true;
  bool _infoExpanded = true;
  WishlistItemEntity _toWishlistItem() {
    final product = widget.product;
    final price = (product['price'] as num).toDouble();
    return WishlistItemEntity(
      id: product['name'] as String,
      productId: product['name'] as String,
      name: product['name'] as String,
      imageUrl: product['image'] as String,
      price: price,
      mrp: price,
      discountPercent: 0,
      rating: 0,
      ratingCount: 0,
      inStock: true,
    );
  }

  late final PageController _galleryController;
  int _galleryIndex = 0;

  late final List<String> _galleryImages;
  late final List<Map<String, dynamic>> _relatedProducts;

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();

    final baseImage = widget.product['image'] as String;
    // Product data only has a single hero image, so the gallery reuses it
    // across a few "angles" until real multi-image assets are added.
    _galleryImages = [baseImage, baseImage, baseImage];

    _relatedProducts = _computeRelatedProducts();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _computeRelatedProducts() {
    final category = widget.product['category'];
    final currentName = widget.product['name'];
    final related = widget.allProducts
        .where((p) => p['category'] == category && p['name'] != currentName)
        .toList();
    related.shuffle();
    return related.take(10).toList();
  }

  String _getGoodFor(String category) {
    switch (category) {
      case 'Fruits': return 'Health & Immunity';
      case 'Ice Creams': return 'Dessert & Treats';
      case 'Chocolate': return 'Snacking & Gifting';
      case 'Beverages':
      case 'Cold Drinks': return 'Refreshment & Hydration';
      case 'Bakery': return 'Breakfast & Snacking';
      case 'Biscuits': return 'Tea Time & Snacking';
      case 'Namkeen':
      case 'Wafers':
      case 'Snacks': return 'Evening Snacking';
      case 'Shampoo':
      case 'Soap':
      case 'Personal Care': return 'Personal Hygiene';
      case 'Clothes': return 'Fashion & Lifestyle';
      case 'Toys': return 'Kids & Entertainment';
      case 'Ketchup':
      case 'Pickle': return 'Cooking & Condiments';
      case 'Puja Items': return 'Spiritual & Religious';
      default: return 'Daily Essentials';
    }
  }

  String _getDietaryPref(String category) {
    switch (category) {
      case 'Clothes':
      case 'Toys':
      case 'Shampoo':
      case 'Soap':
      case 'Personal Care':
      case 'Puja Items': return 'N/A';
      case 'Ice Creams':
      case 'Chocolate':
      case 'Bakery': return 'Veg / Non-Veg';
      default: return 'Veg';
    }
  }

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imagePath,
      fit: BoxFit.contain,
      placeholder: (_, __) => Container(color: Colors.grey[200]),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final isWishlisted = wishlist.isWishlisted(product['name'] as String);
    final qty = cart.getQuantityByProductId(product['id']);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3), blurRadius: 8)],
                    ),
                    child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () =>
                        context.read<WishlistProvider>().toggle(_toWishlistItem()),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.3), blurRadius: 8)],
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted ? Colors.red : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _galleryController,
                          itemCount: _galleryImages.length,
                          onPageChanged: (i) =>
                              setState(() => _galleryIndex = i),
                          itemBuilder: (_, i) =>
                              _buildProductImage(_galleryImages[i]),
                        ),
                        if (_galleryImages.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _galleryImages.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  width: _galleryIndex == i ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _galleryIndex == i
                                        ? const Color(0xFF0C831F)
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.flash_on,
                                        color: Colors.white, size: 12),
                                    Text('10 mins',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(product['name'],
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Net quantity: ${product['unit']}',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0C831F),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('₹${product['price']}',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                  'MRP ₹${(product['price'] * 1.3).toInt()}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      decoration:
                                      TextDecoration.lineThrough)),
                              const SizedBox(width: 8),
                              Text(
                                  '₹${(product['price'] * 0.3).toInt()} OFF',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.replay,
                                      size: 30, color: Colors.grey),
                                  const SizedBox(height: 6),
                                  Text('Easy Refunds',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.delivery_dining,
                                      size: 30, color: Colors.grey),
                                  const SizedBox(height: 6),
                                  Text('Fast Delivery',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Highlights
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() =>
                            _highlightsExpanded = !_highlightsExpanded),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Highlights',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Icon(_highlightsExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down),
                                ],
                              ),
                            ),
                          ),
                          if (_highlightsExpanded)
                            Padding(
                              padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  _highlightRow('Product Type', product['category']),
                                  _highlightRow('Good For', _getGoodFor(product['category'])),
                                  _highlightRow('Dietary Preference', _getDietaryPref(product['category'])),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Information
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => setState(
                                    () => _infoExpanded = !_infoExpanded),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Information',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Icon(_infoExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down),
                                ],
                              ),
                            ),
                          ),
                          if (_infoExpanded)
                            Padding(
                              padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  _highlightRow('Disclaimer',
                                      'All images are for representational purposes only. It is advised that you read the batch and manufacturing details before consuming.'),
                                  _highlightRow('Manufacturer',
                                      'Fresh Farm Produce Pvt. Ltd., Mumbai, Maharashtra'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    
                    // Related Products
                    if (_relatedProducts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        color: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('You might also like',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        color: Theme.of(context).colorScheme.surface,
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _relatedProducts.length,
                          itemBuilder: (context, index) {
                            final related = _relatedProducts[index];
                            return GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    product: related,
                                    allProducts: widget.allProducts,
                                  ),
                                ),
                              ),
                              child: Container(
                                width: 130,
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 90,
                                      width: double.infinity,
                                      child:
                                          _buildProductImage(related['image']),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(related['name'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text('₹${related['price']}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // Bottom Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const CartScreen())),
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              color: Theme.of(context).colorScheme.onSurface),
                          if (cart.cartCount > 0)
                            Positioned(
                              top: 4, right: 4,
                              child: Container(
                                width: 16, height: 16,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF0C831F),
                                    shape: BoxShape.circle),
                                child: Center(
                                  child: Text('${cart.cartCount}',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10)),
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
                      onPressed: () =>
                          context.read<CartProvider>().increment(product['id'], productData: product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C831F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Add to Cart',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    )
                        : Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C831F),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => context
                                .read<CartProvider>()
                                .decrement(product['id']),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20),
                              child: Icon(Icons.remove,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          Text('$qty',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () =>
                                context.read<CartProvider>().increment(product['id'], productData: product),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20),
                              child: Icon(Icons.add,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style:
                GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

