import 'package:flutter/foundation.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/entities/gift_card_entity.dart';
import '../../domain/repositories/gift_card_repository.dart';

/// Separate status enum for the redeem screen so it never gets mixed up
/// with the list-loading status of the tabs.
enum RedeemStatus { idle, submitting, success, error }

class GiftCardProvider extends ChangeNotifier {
  final GiftCardRepository repository;

  GiftCardProvider({required this.repository});

  // Active tab
  ViewStatus activeStatus = ViewStatus.initial;
  String? activeErrorMessage;
  List<GiftCardEntity> activeCards = [];

  // Redeemed tab
  ViewStatus redeemedStatus = ViewStatus.initial;
  String? redeemedErrorMessage;
  List<GiftCardEntity> redeemedCards = [];

  // Redeem screen
  RedeemStatus redeemStatus = RedeemStatus.idle;
  String? redeemErrorMessage;
  GiftCardEntity? lastRedeemedCard;

  void clear() {
    activeCards = [];
    redeemedCards = [];
    activeStatus = ViewStatus.initial;
    redeemedStatus = ViewStatus.initial;
    activeErrorMessage = null;
    redeemedErrorMessage = null;
    redeemStatus = RedeemStatus.idle;
    redeemErrorMessage = null;
    lastRedeemedCard = null;
    notifyListeners();
  }

  Future<void> loadActiveCards() async {
    activeStatus = ViewStatus.loading;
    notifyListeners();

    final result = await repository.getActiveCards();
    if (result.isSuccess) {
      activeCards = result.data ?? [];
      activeStatus = activeCards.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
    } else {
      activeStatus = ViewStatus.error;
      activeErrorMessage = result.failure?.message;
    }
    notifyListeners();
  }

  Future<void> loadRedeemedCards() async {
    redeemedStatus = ViewStatus.loading;
    notifyListeners();

    final result = await repository.getRedeemedCards();
    if (result.isSuccess) {
      redeemedCards = result.data ?? [];
      redeemedStatus =
          redeemedCards.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
    } else {
      redeemedStatus = ViewStatus.error;
      redeemedErrorMessage = result.failure?.message;
    }
    notifyListeners();
  }

  Future<void> redeemCard(String code) async {
    redeemStatus = RedeemStatus.submitting;
    redeemErrorMessage = null;
    notifyListeners();

    final result = await repository.redeemCard(code);
    if (result.isSuccess && result.data != null) {
      lastRedeemedCard = result.data;
      redeemStatus = RedeemStatus.success;
      redeemedCards = [result.data!, ...redeemedCards];
      redeemedStatus = ViewStatus.loaded;
    } else {
      redeemStatus = RedeemStatus.error;
      redeemErrorMessage = result.failure?.message;
    }
    notifyListeners();
  }

  void resetRedeemState() {
    redeemStatus = RedeemStatus.idle;
    redeemErrorMessage = null;
    lastRedeemedCard = null;
    notifyListeners();
  }
}

