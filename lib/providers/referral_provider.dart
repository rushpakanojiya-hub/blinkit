import 'package:flutter/material.dart';
import '../data/models/referral_model.dart';
import '../data/repositories/referral_repository.dart';

class ReferralProvider extends ChangeNotifier {
  final ReferralRepository _repo = ReferralRepository();
  ReferralModel? referral;
  bool loading = false;

  void clear() {
    referral = null;
    loading = false;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      referral = await _repo.fetchReferral();
    } catch (_) {
      referral = null;
    }
    loading = false;
    notifyListeners();
  }
}
