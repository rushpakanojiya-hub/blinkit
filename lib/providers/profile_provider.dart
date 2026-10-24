import 'package:flutter/material.dart';
import '../data/models/user_profile_model.dart';
import '../data/repositories/profile_repository.dart';

enum ProfileStatus { idle, loading, success, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repo = ProfileRepository();

  UserProfileModel? profile;
  ProfileStatus status = ProfileStatus.idle;
  String? errorMessage;
  String? pendingAvatarId;

  void clear() {
    profile = null;
    pendingAvatarId = null;
    errorMessage = null;
    status = ProfileStatus.idle;
    notifyListeners();
  }

  Future<void> load() async {
    status = ProfileStatus.loading;
    notifyListeners();
    profile = await _repo.fetchProfile();
    pendingAvatarId = profile?.avatarId;
    status = ProfileStatus.idle;
    notifyListeners();
  }

  void setPendingAvatar(String avatarId) {
    pendingAvatarId = avatarId;
    notifyListeners();
  }

  String? validateName(String value) {
    if (value.trim().isEmpty) return 'Name cannot be empty';
    if (value.trim().length < 2) return 'Name is too short';
    return null;
  }

  String? validateEmail(String value) {
    if (value.trim().isEmpty) return 'Email cannot be empty';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\-\.]+$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  Future<bool> save({
    required String name,
    required String phone,
    String? email,
    String? gender,
    DateTime? dob,
  }) async {
    status = ProfileStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = (profile ??
              UserProfileModel(
                  name: '', email: '', phone: '', gender: 'Not specified'))
          .copyWith(
        name: name.trim(),
        phone: phone.trim(),
        email: email?.trim(),
        gender: gender,
        dob: dob,
        avatarId: pendingAvatarId,
      );
      profile = await _repo.updateProfile(updated);
      status = ProfileStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      status = ProfileStatus.error;
      errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
