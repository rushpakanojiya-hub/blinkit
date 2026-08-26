import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_models.dart';
import 'category_placeholder_image.dart';

class CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryTile({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tileSize = constraints.maxWidth;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              category.image != null
                  ? Container(
                      width: tileSize,
                      height: tileSize,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(category.image!, fit: BoxFit.cover),
                      ),
                    )
                  : CategoryPlaceholderImage(
                      icon: category.icon,
                      color: category.color,
                      size: tileSize * 0.55,
                      borderRadius: 18,
                    ),
              const SizedBox(height: 4),
              Text(
                category.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, height: 1.1),
              ),
            ],
          );
        },
      ),
    );
  }
}
