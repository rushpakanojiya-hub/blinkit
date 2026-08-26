import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/wallet_model.dart';

const Color kGreen = Color(0xFF0C831F);

class TransactionCard extends StatelessWidget {
  final WalletTransaction transaction;
  const TransactionCard({super.key, required this.transaction});

  IconData get _icon {
    switch (transaction.type) {
      case TransactionType.cashback:
        return Icons.card_giftcard;
      case TransactionType.refund:
        return Icons.replay;
      case TransactionType.debit:
        return Icons.arrow_upward;
      case TransactionType.credit:
        return Icons.arrow_downward;
    }
  }

  bool get _isCredit => transaction.type != TransactionType.debit;

  Color _statusColor() {
    switch (transaction.status) {
      case TransactionStatus.success:
        return kGreen;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: kGreen.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(_icon, color: kGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface)),
                const SizedBox(height: 2),
                Text(DateFormat('d MMM yyyy').format(transaction.date),
                    style: GoogleFonts.poppins(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_isCredit ? '+' : '-'}${transaction.amount}',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.bold, color: _isCredit ? kGreen : Colors.red)),
              const SizedBox(height: 2),
              Text(transaction.status.name[0].toUpperCase() + transaction.status.name.substring(1),
                  style: GoogleFonts.poppins(fontSize: 10, color: _statusColor())),
            ],
          ),
        ],
      ),
    );
  }
}
