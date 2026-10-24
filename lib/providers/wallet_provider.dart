import 'package:flutter/material.dart';
import '../data/repositories/wallet_repository.dart';
import '../services/api_service.dart';
import '../models/wallet_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
enum LoadStatus { initial, loading, loaded, error, loadingMore }
enum WalletTab { transactions, cashback, refunds }
class _TabState {
  List<WalletTransaction> items = [];
  LoadStatus status = LoadStatus.initial;
  int page = 0;
  bool hasMore = true;
  int gen = 0;
  bool refreshing = false;
  String? error;
}
class WalletProvider extends ChangeNotifier {
  final WalletRepository _repo = WalletRepository();
  late final Razorpay _razorpay;
  bool isProcessingTopup = false;
  String? topupError;

  WalletProvider() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleTopupSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleTopupError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
  WalletSummary? summary;
  LoadStatus summaryStatus = LoadStatus.initial;
  String? summaryError;
  final Map<WalletTab, _TabState> _tabs = {
    WalletTab.transactions: _TabState(),
    WalletTab.cashback: _TabState(),
    WalletTab.refunds: _TabState(),
  };
  TransactionType? _typeFor(WalletTab tab) {
    switch (tab) {
      case WalletTab.transactions:
        return null;
      case WalletTab.cashback:
        return TransactionType.cashback;
      case WalletTab.refunds:
        return TransactionType.refund;
    }
  }
  List<WalletTransaction> itemsFor(WalletTab tab) => _tabs[tab]!.items;
  LoadStatus statusFor(WalletTab tab) => _tabs[tab]!.status;
  bool hasMoreFor(WalletTab tab) => _tabs[tab]!.hasMore;
  String? errorFor(WalletTab tab) => _tabs[tab]!.error;
  Future<void> loadSummary({bool refresh = false}) async {
    if (summaryStatus == LoadStatus.loading && !refresh) return;
    summaryStatus = LoadStatus.loading;
    notifyListeners();
    try {
      summary = await _repo.fetchSummary();
      summaryStatus = LoadStatus.loaded;
    } catch (e) {
      summaryStatus = LoadStatus.error;
      summaryError = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }
  Future<void> loadTransactions(WalletTab tab, {bool refresh = false}) async {
    final t = _tabs[tab]!;
    if (refresh) {
      t.gen++;
      t.refreshing = true;
      // keep the current list on screen until fresh data arrives
    }
    if (!refresh && (t.refreshing || t.status == LoadStatus.loading || t.status == LoadStatus.loadingMore)) return;
    final myGen = t.gen;
    t.status = t.items.isEmpty
        ? LoadStatus.loading
        : (refresh ? LoadStatus.loaded : LoadStatus.loadingMore);
    notifyListeners();
    try {
      final result = await _repo.fetchTransactions(_typeFor(tab), page: refresh ? 0 : t.page);
      if (myGen != t.gen) return;
      if (refresh) {
        t.items = List.of(result);
        t.page = 0;
      } else {
        t.items.addAll(result);
      }
      t.hasMore = result.length == WalletRepository.pageSize;
      t.page++;
      t.status = LoadStatus.loaded;
      t.refreshing = false;
    } catch (e) {
      if (myGen != t.gen) return;
      t.status = (refresh && t.items.isNotEmpty) ? LoadStatus.loaded : LoadStatus.error;
      t.refreshing = false;
      t.error = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }
  Future<void> loadMore(WalletTab tab) async {
    if (!_tabs[tab]!.hasMore) return;
    await loadTransactions(tab);
  }

  // Adds money to the wallet via the backend, then refreshes summary and
  // Starts a wallet top-up: creates a Razorpay order on the backend, then
  // opens Razorpay Checkout. The wallet is only credited after
  // _handleTopupSuccess verifies the payment signature - this method never
  // credits the wallet directly.
  /// Adds money to the wallet by initiating a topup checkout.
  Future<void> addMoney(int amount) => startTopup(amount);

  Future<void> startTopup(int amount) async {
    topupError = null;
    isProcessingTopup = true;
    notifyListeners();
    try {
      final orderData = await ApiService.createWalletTopupOrder(amount);
      final options = {
        'key': orderData['key_id'],
        'amount': orderData['amount'],
        'currency': orderData['currency'],
        'name': 'GoFresh',
        'order_id': orderData['razorpay_order_id'],
      };
      _razorpay.open(options);
    } catch (e) {
      isProcessingTopup = false;
      topupError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> _handleTopupSuccess(PaymentSuccessResponse response) async {
    try {
      await ApiService.verifyWalletTopup(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      await loadSummary(refresh: true);
      await loadTransactions(WalletTab.transactions, refresh: true);
      topupError = null;
    } catch (e) {
      topupError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isProcessingTopup = false;
      notifyListeners();
    }
  }

  void _handleTopupError(PaymentFailureResponse response) {
    isProcessingTopup = false;
    topupError = response.message ?? 'Payment failed';
    notifyListeners();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    isProcessingTopup = false;
    notifyListeners();
  }


  /// Clears in-memory wallet state on logout so the next user doesn't
  /// see the previous user's balance/transactions before refreshing.
  void clear() {
    summary = null;
    summaryStatus = LoadStatus.initial;
    summaryError = null;
    for (final tab in _tabs.values) {
      tab.items = [];
      tab.gen++;
      tab.refreshing = false;
      tab.status = LoadStatus.initial;
      tab.page = 0;
      tab.hasMore = true;
      tab.error = null;
    }
    notifyListeners();
  }
}
