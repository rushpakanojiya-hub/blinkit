import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/category_models.dart';
import '../providers/category_nav_provider.dart';

class CategorySearchBar extends StatelessWidget {
  final String categoryTitle;
  const CategorySearchBar({super.key, required this.categoryTitle});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CategoryNavProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: provider.updateQuery,
                style: GoogleFonts.poppins(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search in $categoryTitle',
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterSortBar extends StatelessWidget {
  const FilterSortBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryNavProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _ActionChip(
              icon: Icons.tune,
              label: provider.inStockOnly ? 'Filters \u2022 1' : 'Filters',
              highlighted: provider.inStockOnly,
              onTap: () => _showFilterSheet(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionChip(
              icon: Icons.swap_vert,
              label: provider.sort == SortOption.relevance ? 'Sort' : provider.sort.label,
              highlighted: provider.sort != SortOption.relevance,
              onTap: () => _showSortSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Consumer<CategoryNavProvider>(
        builder: (context, p, __) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filters', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('In stock only', style: GoogleFonts.poppins(fontSize: 13.5)),
                value: p.inStockOnly,
                onChanged: (_) => p.toggleInStockOnly(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Consumer<CategoryNavProvider>(
        builder: (context, p, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Sort by', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              ...SortOption.values.map((option) => RadioListTile<SortOption>(
                    value: option,
                    groupValue: p.sort,
                    title: Text(option.label, style: GoogleFonts.poppins(fontSize: 13.5)),
                    onChanged: (value) {
                      p.updateSort(value!);
                      Navigator.pop(sheetContext);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: highlighted ? scheme.primary : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: highlighted ? scheme.primary.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: highlighted ? scheme.primary : Colors.black87),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: highlighted ? scheme.primary : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
