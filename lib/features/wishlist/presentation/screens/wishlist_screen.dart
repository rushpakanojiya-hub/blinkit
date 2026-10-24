import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/wishlist_product_card.dart';
import '../../../../screens/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistProvider>().loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WishlistProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, WishlistProvider provider) {
    switch (provider.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return SkeletonListView(
          itemBuilder: (_) => const _WishlistCardSkeleton(),
        );
      case ViewStatus.error:
        return ErrorStateWidget(
          message: provider.errorMessage ?? 'Please try again.',
          onRetry: provider.loadWishlist,
        );
      case ViewStatus.empty:
        return EmptyStateWidget(
          icon: Icons.favorite_border_rounded,
          title: 'Your wishlist is empty',
          message: 'Tap the heart on any product to save it here for later.',
        );
      case ViewStatus.loaded:
        return RefreshIndicator(
          onRefresh: provider.loadWishlist,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = provider.items[index];
              return WishlistProductCard(
                item: item,
                onOpenDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        product: {
                          'id': item.productId,
                          'name': item.name,
                          'price': item.price,
                          'image': item.imageUrl,
                          'inStock': item.inStock,
                          'unit': item.unit,
                          'category': item.category,
                          'mrp': item.mrp,
                          'description': item.description,
                        },
                      ),
                    ),
                  );
                },
                onRemove: () => provider.removeItem(item.id),
                onMoveToCart: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final cart = context.read<CartProvider>();
                  final ok = await provider.moveToCart(item.id, cart);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'Moved to cart' : 'Could not move to cart',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
    }
  }
}

class _WishlistCardSkeleton extends StatelessWidget {
  const _WishlistCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              width: 84,
              height: 84,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                    width: double.infinity,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  SkeletonBox(
                    width: 100,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  SkeletonBox(
                    width: 140,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
