class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? mobileNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(trimmed)) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }

  static String? gstNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'GST number is required';
    }
    final trimmed = value.trim().toUpperCase();
    // Standard GSTIN format: 22AAAAA0000A1Z5
    final pattern = RegExp(
      r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
    );
    if (!pattern.hasMatch(trimmed) || !_gstinOk(trimmed)) {
      return 'Enter a valid 15-character GSTIN';
    }
    return null;
  }

  static bool _gstinOk(String g) {
    if (g.length != 15) return false;
    final st = int.tryParse(g.substring(0, 2)) ?? 0;
    if (!((st >= 1 && st <= 38) || st == 97 || st == 99)) return false;
    if (!'CPHFATBLJG'.contains(g[5])) return false;
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    var sum = 0;
    for (var i = 0; i < 14; i++) {
      final v = chars.indexOf(g[i]);
      if (v < 0) return false;
      final p = v * (i.isEven ? 1 : 2);
      sum += p ~/ 36 + p % 36;
    }
    final check = (36 - sum % 36) % 36;
    return chars[check] == g[14];
  }

  static String? giftCardCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Gift card code is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 8) {
      return 'Gift card code looks too short';
    }
    return null;
  }
}

