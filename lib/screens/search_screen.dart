import '../utils/cart_safe.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'product_detail_screen.dart';

enum SortOption { relevance, priceLowHigh, priceHighLow, nameAZ }

extension SortOptionLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.priceLowHigh:
        return 'Price: Low to High';
      case SortOption.priceHighLow:
        return 'Price: High to Low';
      case SortOption.nameAZ:
        return 'Name: A to Z';
    }
  }
}

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _query = widget.initialQuery!;
      _controller.text = widget.initialQuery!;
    }
  }

  List<Map<String, dynamic>> get _allProducts => context.watch<ProductProvider>().products;

  String? _selectedCategory;
  SortOption _sortOption = SortOption.relevance;

  List<Map<String, dynamic>> get _searchMatches {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase().trim();

    // Exact category match (e.g. "Chips") shows only that category.
    final categoryMatches = _allProducts
        .where((p) => p['category'].toString().toLowerCase() == q)
        .toList();
    if (categoryMatches.isNotEmpty) return categoryMatches;

    return _allProducts.where((p) =>
        p['name'].toString().toLowerCase().contains(q) ||
        p['category'].toString().toLowerCase().contains(q)
    ).toList();
  }

  List<String> get _matchingCategories {
    final cats = _searchMatches
        .map((p) => p['category']?.toString())
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  List<Map<String, dynamic>> get _filtered {
    var results = _searchMatches;

    if (_selectedCategory != null) {
      results = results.where((p) => p['category']?.toString() == _selectedCategory).toList();
    }

    results = List<Map<String, dynamic>>.from(results);
    switch (_sortOption) {
      case SortOption.priceLowHigh:
        results.sort((a, b) => ((a['price'] as num?) ?? 0).compareTo((b['price'] as num?) ?? 0));
        break;
      case SortOption.priceHighLow:
        results.sort((a, b) => ((b['price'] as num?) ?? 0).compareTo((a['price'] as num?) ?? 0));
        break;
      case SortOption.nameAZ:
        results.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
        break;
      case SortOption.relevance:
        break;
    }
    return results;
  }

  final List<String> _popular = [
    'Biscuits', 'Chips', 'Shampoo', 'Soap', 'Cold Drinks', 'Namkeen', 'Pickle', 'Puja Items'
  ];

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: 120, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 120, color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imagePath,
      height: 120, width: double.infinity, fit: BoxFit.cover,
      placeholder: (_, __) => Container(height: 120, color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
      errorWidget: (_, __, ___) => Container(height: 120, color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (val) => setState(() {
            _query = val;
            _selectedCategory = null;
          }),
          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search groceries...',
            hintStyle: GoogleFonts.poppins(color: Colors.grey),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                _controller.clear();
                setState(() {
                  _query = '';
                  _selectedCategory = null;
                });
              },
            )
                : null,
          ),
        ),
      ),
      body: _query.isEmpty
          ? _buildPopularSearches()
          : _filtered.isEmpty
          ? _buildNoResults()
          : _buildResults(),
    );
  }

  Widget _buildPopularSearches() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popular Searches',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _popular.map((item) {
              return GestureDetector(
                onTap: () {
                  _controller.text = item;
                  setState(() {
                    _query = item;
                    _selectedCategory = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(item, style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No results for "$_query"',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Try searching something else',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text('Sort By', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              ...SortOption.values.map((opt) => ListTile(
                title: Text(opt.label, style: GoogleFonts.poppins(fontSize: 13)),
                trailing: _sortOption == opt
                    ? const Icon(Icons.check, color: Color(0xFF0C831F))
                    : null,
                onTap: () {
                  setState(() => _sortOption = opt);
                  Navigator.pop(ctx);
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSortBar() {
    final categories = _matchingCategories;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All', style: GoogleFonts.poppins(fontSize: 12)),
                    selected: _selectedCategory == null,
                    selectedColor: const Color(0xFFEAF7EA),
                    labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _selectedCategory == null ? const Color(0xFF0C831F) : Theme.of(context).colorScheme.onSurface,
                        fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal),
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                  ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(cat, style: GoogleFonts.poppins(fontSize: 12)),
                      selected: _selectedCategory == cat,
                      selectedColor: const Color(0xFFEAF7EA),
                      labelStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _selectedCategory == cat ? const Color(0xFF0C831F) : Theme.of(context).colorScheme.onSurface,
                          fontWeight: _selectedCategory == cat ? FontWeight.bold : FontWeight.normal),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _showSortSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort, size: 16, color: Theme.of(context).colorScheme.onSurface),
                  const SizedBox(width: 4),
                  Text('Sort', style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final cart = context.watch<CartProvider>();
    return Column(
      children: [
        _buildFilterSortBar(),
        Expanded(child: _buildResultsGrid(cart)),
      ],
    );
  }

  Widget _buildResultsGrid(CartProvider cart) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final product = _filtered[index];
        final qty = cart.getQuantityByProductId(product['id']);
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: product,
                allProducts: _allProducts,
              ),
            ),
          ),
          child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildImage(product['image']),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'],
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(product['unit'],
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\u20B9${product['price']}',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.bold,
                                color: const Color(0xFF0C831F))),
                        qty == 0
                            ? GestureDetector(
                          onTap: () => context.read<CartProvider>().safeIncrement(context, product['id'], productData: product),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF0C831F),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('ADD',
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        )
                            : Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.read<CartProvider>().safeDecrement(context, product['id']),
                              child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF0C831F),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.remove, color: Colors.white, size: 14)),
                            ),
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text('$qty',
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
                            GestureDetector(
                              onTap: () => context.read<CartProvider>().safeIncrement(context, product['id'], productData: product),
                              child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF0C831F),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.add, color: Colors.white, size: 14)),
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
    );
  }
}
