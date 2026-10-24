enum GiftCardStatus { active, redeemed, expired }

class GiftCardEntity {
  final String id;
  final String cardNumber;
  final double balance;
  final DateTime expiryDate;
  final GiftCardStatus status;

  const GiftCardEntity({
    required this.id,
    required this.cardNumber,
    required this.balance,
    required this.expiryDate,
    required this.status,
  });

  bool get isActive => status == GiftCardStatus.active && DateTime(expiryDate.year, expiryDate.month, expiryDate.day).add(const Duration(days: 1)).isAfter(DateTime.now());
}

