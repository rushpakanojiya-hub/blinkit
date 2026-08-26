import 'package:flutter/material.dart';

/// Icon-based placeholder used wherever a product/category photo would
/// normally go. Mock data has no real image URLs â€” swap this out for
/// `CachedNetworkImage`/`Image.asset` per item once real assets exist.
class CategoryPlaceholderImage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double borderRadius;

  const CategoryPlaceholderImage({
    super.key,
    required this.icon,
    required this.color,
    this.size = 56,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}
