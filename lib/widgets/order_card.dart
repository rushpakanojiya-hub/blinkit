import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';

const Color kGreen = Color(0xFF0C831F);

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const OrderCard({super.key, required this.order, required this.onTap});

  Color _statusColor() {
    switch (order.status) {
      case OrderStatus.active:
        return kGreen;
      case OrderStatus.delivered:
        return Colors.blue;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 14, color: scheme.onSurface)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(order.statusLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor())),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(DateFormat('d MMM yyyy, hh:mm a').format(order.date),
                style: GoogleFonts.poppins(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order.itemCount} item${order.itemCount > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.7))),
                Text('${order.grandTotal}',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.bold, color: scheme.onSurface)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
