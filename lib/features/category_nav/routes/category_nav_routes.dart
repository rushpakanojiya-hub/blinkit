import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/category_models.dart';
import '../providers/category_nav_provider.dart';
import '../screens/category_product_screen.dart';
import '../screens/product_details_screen.dart';

/// Route definitions for the category-navigation flow.
///
/// Like the existing `profile` GoRoutes (see lib/routes/app_router.dart),
/// this list is NOT wired into the app's root router yet — the app still
/// navigates via Navigator/MaterialPageRoute end to end. Use
/// [CategoryNavRoutes.openCategory] / [openProductDetails] below for
/// actual navigation; wire `categoryNavRoutes` into a root GoRouter
/// later if/when the whole app migrates.
class CategoryNavRoutes {
  static const category = '/category/:categoryId';
  static const productDetails = '/category/product/:productId';

  static void openCategory(BuildContext context, CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryProductScreen(category: category)),
    );
  }

  static void openProductDetails(BuildContext context, ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
    );
  }
}

final List<GoRoute> categoryNavRoutes = [
  GoRoute(
    path: CategoryNavRoutes.category,
    builder: (context, state) {
      final categoryId = state.pathParameters['categoryId'];
      final provider = context.read<CategoryNavProvider>();
      final category = provider.sections
          .expand((s) => s.categories)
          .firstWhere((c) => c.id == categoryId, orElse: () => provider.sections.expand((s) => s.categories).first);
      return CategoryProductScreen(category: category);
    },
  ),
  GoRoute(
    path: CategoryNavRoutes.productDetails,
    builder: (context, state) {
      final productId = state.pathParameters['productId']!;
      return FutureBuilder<ProductModel>(
        future: context.read<CategoryNavProvider>().fetchProductById(productId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(appBar: AppBar(), body: const Center(child: Text('Could not load this product.')));
          }
          if (!snapshot.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return ProductDetailsScreen(product: snapshot.data!);
        },
      );
    },
  ),
];
