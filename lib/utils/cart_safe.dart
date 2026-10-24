import 'package:flutter/material.dart';
import '../providers/cart_provider.dart';

/// Cart add/remove ke errors ko snackbar mein dikhata hai
/// (pehle bina try/catch wale callers mein error chup jaata tha).
extension CartSafe on CartProvider {
  Future<void> safeIncrement(BuildContext context, dynamic productId,
      {Map<String, dynamic>? productData}) async {
    try {
      await increment(productId, productData: productData);
    } catch (e) {
      if (context.mounted) _showCartError(context, e);
    }
  }

  Future<void> safeDecrement(BuildContext context, dynamic productId) async {
    try {
      await decrement(productId);
    } catch (e) {
      if (context.mounted) _showCartError(context, e);
    }
  }
}

void _showCartError(BuildContext context, Object e) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
  );
}