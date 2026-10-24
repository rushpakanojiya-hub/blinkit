import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../models/user_profile_model.dart';

/// Profile is stored on the backend (GET/PUT /auth/me). SharedPreferences
/// keeps a per-phone cache so the screen still works offline / for guests.
class ProfileRepository {
  static const _prefsKeyBase = 'user_profile_json';
  static const _loginPhoneKey =
      'user_phone'; // set by OtpScreen on successful login

  // Cache is scoped per phone number so one account's data never leaks into
  // the next account that logs in on this device.
  String _keyFor(String? phone) => (phone != null && phone.isNotEmpty)
      ? '${_prefsKeyBase}_$phone'
      : _prefsKeyBase;

  Future<UserProfileModel> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final loginPhone = prefs.getString(_loginPhoneKey);
    final key = _keyFor(loginPhone);
    final saved = prefs.getString(key);

    UserProfileModel profile;
    if (saved != null) {
      profile = UserProfileModel.fromJson(jsonDecode(saved));
    } else {
      final raw = await rootBundle.loadString('assets/data/user_profile.json');
      profile = UserProfileModel.fromJson(jsonDecode(raw));
    }
    if (loginPhone != null &&
        loginPhone.isNotEmpty &&
        profile.phone != loginPhone) {
      profile = profile.copyWith(phone: loginPhone);
    }

    try {
      final me = await ApiService.getMe();
      final sName = (me['name'] ?? '').toString();
      final sEmail = (me['email'] ?? '').toString();
      final sGender = (me['gender'] ?? '').toString();
      final sDobRaw = (me['dob'] ?? '').toString();
      final sDob = sDobRaw.isEmpty ? null : DateTime.tryParse(sDobRaw);
      final sAvatar = (me['avatar_id'] ?? '').toString();

      // Server values win; anything the server lacks falls back to the cache.
      final localBefore = profile;
      profile = profile.copyWith(
        name: sName.isNotEmpty ? sName : null,
        email: sEmail.isNotEmpty ? sEmail : null,
        gender: sGender.isNotEmpty ? sGender : null,
        dob: sDob,
        avatarId: sAvatar.isNotEmpty ? sAvatar : null,
      );

      // One-time migration of edits that only exist locally.
      final serverMissing =
          (sName.isEmpty && localBefore.name.trim().isNotEmpty) ||
          (sEmail.isEmpty && localBefore.email.trim().isNotEmpty) ||
          (sDob == null && localBefore.dob != null) ||
          (sAvatar.isEmpty && (localBefore.avatarId ?? '').isNotEmpty);
      if (serverMissing && profile.name.trim().isNotEmpty) {
        try {
          await ApiService.updateMe(_body(profile));
        } catch (_) {}
      }
    } catch (_) {
      // Offline, guest or expired token: keep the cached profile.
    }

    await prefs.setString(key, jsonEncode(profile.toJson()));
    return profile;
  }

  Future<UserProfileModel> updateProfile(UserProfileModel profile) async {
    // Server first: if it fails the caller shows an error and nothing is
    // cached, so the next load can't be overwritten by a stale value.
    await ApiService.updateMe(_body(profile));
    final prefs = await SharedPreferences.getInstance();
    final loginPhone = prefs.getString(_loginPhoneKey);
    final key = _keyFor(
      (loginPhone != null && loginPhone.isNotEmpty)
          ? loginPhone
          : profile.phone,
    );
    await prefs.setString(key, jsonEncode(profile.toJson()));
    return profile;
  }

  Map<String, dynamic> _body(UserProfileModel p) => {
    'name': p.name.trim(),
    'email': p.email.trim(),
    'gender': p.gender,
    'dob': p.dob?.toIso8601String() ?? '',
    'avatar_id': p.avatarId ?? '',
  };
}
