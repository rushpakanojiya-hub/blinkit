import '../../../utils/cart_safe.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/state_views.dart' show kGreen;
import '../models/category_models.dart';
import 'category_placeholder_image.dart';

Map<String, dynamic> productCartData(ProductModel p) => {
      'id': p.id,
      'name': p.name,
      'brand': p.brand,
      'weight': p.weight,
      'price': p.price,
      'image': p.image,
    };

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.getQuantityByProductId(product.id);
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: (product.image != null && product.image!.isNotEmpty)
                      ? (product.image!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: product.image!,
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.contain,
                              memCacheWidth: 240,
                              filterQuality: FilterQuality.low,
                              placeholder: (_, __) => const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                              errorWidget: (_, __, ___) => CategoryPlaceholderImage(
                                icon: product.icon,
                                color: product.color,
                                size: 100,
                                borderRadius: 0,
                              ),
                            )
                          : Image.asset(
                              product.image!,
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.contain,
                              cacheWidth: 240,
                              filterQuality: FilterQuality.low,
                              errorBuilder: (_, __, ___) => CategoryPlaceholderImage(
                                icon: product.icon,
                                color: product.color,
                                size: 100,
                                borderRadius: 0,
                              ),
                            ))
                      : CategoryPlaceholderImage(
                          icon: product.icon,
                          color: product.color,
                          size: 100,
                          borderRadius: 0,
                        ),
                ),
                if (!product.inStock)
                  Positioned(
                    top: 6,
                    left: 6,
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
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Icon(Icons.star, size: 12, color: Colors.amber[700]),
                const SizedBox(width: 2),
                Text('${product.rating.toStringAsFixed(1)} (${product.ratingCount})',
                    style: GoogleFonts.poppins(fontSize: 10, color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
            const SizedBox(height: 4),
            Text(product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text([product.brand, product.weight].where((s) => s.trim().isNotEmpty).join(' \u2022 '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 10.5, color: scheme.onSurface.withValues(alpha: 0.55))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('\u20b9${product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold)),
                      if (product.mrp > product.price)
                        Text('\u20b9${product.mrp.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: scheme.onSurface.withValues(alpha: 0.45),
                                decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                ),
                _AddButton(product: product, qty: qty),
              ],
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

class _AddButton extends StatelessWidget {
  final ProductModel product;
  final int qty;

  const _AddButton({required this.product, required this.qty});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    if (!product.inStock) {
      return OutlinedButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('We will notify you'))),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          side: const BorderSide(color: kGreen),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text('Notify',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: kGreen)),
      );
    }

    // Categories-tab filler items (shown when a category doesn't have
    // enough real backend products) have non-numeric string ids and can
    // never actually be purchased (CartProvider.addProduct blocks them).
    // Show a disabled "Coming Soon" state instead of a green ADD button
    // that looks tappable but always fails.
    final isPurchasable = int.tryParse(product.id) != null;
    if (!isPurchasable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Coming Soon',
            style: GoogleFonts.poppins(
                fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
      );
    }
    if (qty == 0) {
      return GestureDetector(
        onTap: () async {
          try {
            await cart.increment(product.id, productData: productCartData(product));
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: Color(0xFFF5C518), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF2D2D2D),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: kGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('ADD',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: () => cart.safeDecrement(context, product.id)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('$qty',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          _StepperButton(
              icon: Icons.add,
              onTap: () async {
                try {
                  await cart.increment(product.id, productData: productCartData(product));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag_outlined, color: Color(0xFFF5C518), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.toString().replaceFirst('Exception: ', ''),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF2D2D2D),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}
