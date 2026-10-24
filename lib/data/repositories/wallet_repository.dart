import '../../models/wallet_model.dart';
import '../../services/api_service.dart';

class WalletRepository {
  static const int pageSize = 6;

  Future<WalletSummary> fetchSummary() async {
    final data = await ApiService.getWallet();
    final balance = ((data['balance'] ?? 0) as num).toInt();
    final transactions = (data['transactions'] as List?) ?? [];
    final cashback = transactions
        .where((t) => t['reason'] == 'cashback')
        .fold<int>(0, (sum, t) => sum + ((t['amount'] ?? 0) as num).toInt());
    return WalletSummary(
      currentBalance: balance,
      cashbackEarned: cashback,
      totalSavings: cashback,
    );
  }

  Future<List<WalletTransaction>> fetchTransactions(TransactionType? filterType,
      {int page = 0}) async {
    final data = await ApiService.getWallet();
    final raw = (data['transactions'] as List?) ?? [];
    final all = raw.map((t) => _fromJson(t as Map<String, dynamic>)).toList();
    final filtered =
        filterType == null ? all : all.where((t) => t.type == filterType).toList();
    final start = page * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  WalletTransaction _fromJson(Map<String, dynamic> json) {
    final reason = json['reason']?.toString() ?? '';
    final txnType = json['type']?.toString() ?? 'credit';
    TransactionType type;
    if (reason == 'cashback') {
      type = TransactionType.cashback;
    } else if (reason.contains('refund')) {
      type = TransactionType.refund;
    } else {
      type = txnType == 'debit' ? TransactionType.debit : TransactionType.credit;
    }
    return WalletTransaction(
      id: json['id'].toString(),
      amount: ((json['amount'] ?? 0) as num).toInt(),
      date: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      status: TransactionStatus.success,
      type: type,
      description: json['note']?.toString().isNotEmpty == true
          ? json['note'].toString()
          : reason.replaceAll('_', ' '),
    );
  }
}