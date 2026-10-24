import 'package:flutter/foundation.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/address_repository.dart';
import '../../../category_nav/repositories/category_repository.dart';

class AddressProvider extends ChangeNotifier {
  final AddressRepository repository;

  AddressProvider({required this.repository});

  ViewStatus status = ViewStatus.initial;
  String? errorMessage;
  List<AddressEntity> addresses = [];

  /// Per-item submitting flag (used for delete/set-default row spinners).
  final Set<String> pendingIds = {};

  /// The user's default address, or null if none is set/loaded yet.
  /// Falls back to the first address when none is explicitly marked default,
  /// so a freshly-added single address still counts as "current".
  AddressEntity? get defaultAddress {
    if (addresses.isEmpty) return null;
    for (final a in addresses) {
      if (a.isDefault) return a;
    }
    return addresses.first;
  }
  bool isSaving = false;

  void _syncLocation() {
    final d = defaultAddress;
    CategoryRepository.updateLocation(d?.latitude, d?.longitude);
  }

  void clear() {
    addresses = [];
    pendingIds.clear();
    errorMessage = null;
    isSaving = false;
    status = ViewStatus.initial;
    notifyListeners();
  }

  Future<void> loadAddresses() async {
    status = ViewStatus.loading;
    notifyListeners();

    final result = await repository.getAddresses();
    if (result.isSuccess) {
      addresses = result.data ?? [];
      status = addresses.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
      final def = defaultAddress;
      CategoryRepository.updateLocation(def?.latitude, def?.longitude);
    } else {
      status = ViewStatus.error;
      errorMessage = result.failure?.message;
    }
    notifyListeners();
  }

  Future<bool> addAddress(AddressEntity address) async {
    isSaving = true;
    notifyListeners();

    final result = await repository.addAddress(address);
    isSaving = false;
    if (result.isSuccess && result.data != null) {
      final added = result.data!;
      addresses = [
        ...addresses.map((a) => added.isDefault ? a.copyWith(isDefault: false) : a),
        added,
      ];
      _syncLocation();
      status = ViewStatus.loaded;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateAddress(AddressEntity address) async {
    isSaving = true;
    notifyListeners();

    final result = await repository.updateAddress(address);
    isSaving = false;
    if (result.isSuccess && result.data != null) {
      addresses = addresses
          .map((a) => a.id == address.id ? result.data! : (result.data!.isDefault ? a.copyWith(isDefault: false) : a))
          .toList();
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<void> deleteAddress(String id) async {
    pendingIds.add(id);
    notifyListeners();

    final result = await repository.deleteAddress(id);
    pendingIds.remove(id);
    if (result.isSuccess) {
      final wasDefault = addresses.any((a) => a.id == id && a.isDefault);
      addresses = addresses.where((a) => a.id != id).toList();
      if (wasDefault && addresses.isNotEmpty) {
        final r = await repository.getAddresses();
        if (r.isSuccess && r.data != null) addresses = r.data!;
      }
      _syncLocation();
      status = addresses.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
    }
    notifyListeners();
  }

  Future<void> setDefaultAddress(String id) async {
    pendingIds.add(id);
    notifyListeners();

    final result = await repository.setDefaultAddress(id);
    pendingIds.remove(id);
    if (result.isSuccess) {
      addresses = addresses
          .map((a) => a.copyWith(isDefault: a.id == id))
          .toList();
    }
    notifyListeners();
  }
}

