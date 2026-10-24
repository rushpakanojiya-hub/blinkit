class WishlistItemEntity {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final double mrp;
  final int discountPercent;
  final double rating;
  final int ratingCount;
  final bool inStock;
  final String unit;
  final String category;
  final String description;

  const WishlistItemEntity({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.mrp,
    required this.discountPercent,
    required this.rating,
    required this.ratingCount,
    this.inStock = true,
    this.unit = '1 pc',
    this.category = 'Grocery',
    this.description = '',
  });
}
