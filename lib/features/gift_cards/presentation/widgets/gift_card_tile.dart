import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/gift_card_entity.dart';

class GiftCardTile extends StatelessWidget {
  final GiftCardEntity card;

  const GiftCardTile({super.key, required this.card});

  Color _statusColor(BuildContext context) {
    switch (card.status) {
      case GiftCardStatus.active:
        return Theme.of(context).colorScheme.primary;
      case GiftCardStatus.redeemed:
        return Colors.grey;
      case GiftCardStatus.expired:
        return Theme.of(context).colorScheme.error;
    }
  }

  String get _statusLabel {
    switch (card.status) {
      case GiftCardStatus.active:
        return 'ACTIVE';
      case GiftCardStatus.redeemed:
        return 'REDEEMED';
      case GiftCardStatus.expired:
        return 'EXPIRED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: card.isActive
                ? [
                    theme.colorScheme.primary.withValues(alpha: 0.10),
                    theme.colorScheme.primary.withValues(alpha: 0.02),
                  ]
                : [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.surfaceContainerHighest,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard_rounded,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    card.cardNumber,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _statusColor(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Balance', style: theme.textTheme.bodyMedium),
                    Text(
                      '\u20B9${card.balance.toStringAsFixed(0)}',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Expires on', style: theme.textTheme.bodyMedium),
                    Text(
                      dateFormat.format(card.expiryDate),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

