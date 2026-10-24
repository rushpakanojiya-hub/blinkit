import 'dart:convert';
import '../features/gift_cards/data/models/gift_card_model.dart';
import '../features/gift_cards/domain/entities/gift_card_entity.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://gofresh-evl7.onrender.com/api/v1';

  static const Duration _timeout = Duration(seconds: 30);

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setBool('skipped_login', false);
  }

  /// jsonDecode that survives HTML error pages (e.g. Render 502/503).
  static dynamic _safeDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return {'error': 'Server is unavailable. Please try again in a moment.'};
    }
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in const [
      'user_phone',
      'saved_addresses',
      'user_profile_json',
    ]) {
      await prefs.remove(k);
    }
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<void> setSkippedLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skipped_login', value);
  }

  static Future<bool> getSkippedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('skipped_login') ?? false;
  }

  static Future<Map<String, String>> getHeaders({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ---- Delivery-partner auth & tools ----

  static Future<Map<String, dynamic>> sendOTP(String phone) => sendOtp(phone);
  static Future<Map<String, dynamic>> verifyOTP(String phone, String otp) =>
      verifyOtp(phone, otp);

  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/send-otp'),
          headers: await getHeaders(auth: false),
          body: jsonEncode({'phone': phone}),
        )
        .timeout(_timeout);
    return _safeDecode(res.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String otp,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/verify-otp'),
          headers: await getHeaders(auth: false),
          body: jsonEncode({'phone': phone, 'otp': otp}),
        )
        .timeout(_timeout);
    final data = _safeDecode(res.body);
    if (res.statusCode == 200 && data['token'] != null) {
      await saveToken(data['token']);
    }
    return data;
  }

  static Future<List<dynamic>> getMyDeliveries({String? status}) async {
    var url = '$baseUrl/delivery/orders';
    if (status != null) url += '?status=$status';
    final res = await http
        .get(Uri.parse(url), headers: await getHeaders())
        .timeout(_timeout);
    final data = _safeDecode(res.body);
    if (res.statusCode == 200) return data['orders'] ?? [];
    throw Exception(data['error'] ?? 'Failed to load orders');
  }

  static Future<Map<String, dynamic>> markShipped(int orderId) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/delivery/orders/$orderId/status'),
          headers: await getHeaders(),
          body: jsonEncode({'status': 'shipped'}),
        )
        .timeout(_timeout);
    final data = _safeDecode(res.body);
    if (res.statusCode != 200)
      throw Exception(data['error'] ?? 'Failed to update status');
    return data;
  }

  static Future<Map<String, dynamic>> confirmDelivery(int orderId) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/delivery/orders/$orderId/deliver'),
          headers: await getHeaders(),
        )
        .timeout(_timeout);
    final data = _safeDecode(res.body);
    if (res.statusCode != 200)
      throw Exception(data['error'] ?? 'Failed to confirm delivery');
    return data;
  }

  static Future<bool> getOnlineStatus() async {
    final res = await http
        .get(Uri.parse('$baseUrl/delivery/status'), headers: await getHeaders())
        .timeout(_timeout);
    final data = _safeDecode(res.body);
    if (res.statusCode != 200)
      throw Exception(data['error'] ?? 'Failed to load status');
    return data['is_online'] == true;
  }

  static Future<bool> updateOnlineStatus(bool isOnline) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/delivery/status'),
          headers: await getHeaders(),
          body: jsonEncode({'is_online': isOnline}),
        )
        .timeout(_timeout);
    final data = _safeDecode(res.body);
    if (res.statusCode != 200)
      throw Exception(data['error'] ?? 'Failed to update status');
    return data['is_online'] == true;
  }

  static Future<void> updateLocation(double lat, double lng) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/delivery/location'),
          headers: await getHeaders(),
          body: jsonEncode({'lat': lat, 'lng': lng}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('updateLocation ${res.statusCode}: ${res.body}');
    }
  }

  static Future<Map<String, dynamic>> getEarnings() async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/delivery/earnings'),
          headers: await getHeaders(),
        )
        .timeout(_timeout);
    final data = _safeDecode(res.body);
    if (res.statusCode != 200)
      throw Exception(data['error'] ?? 'Failed to load earnings');
    return data;
  }

  // ---- Products ----

  static Future<List<dynamic>> getProducts({
    String? category,
    double? lat,
    double? lng,
  }) async {
    final headers = await getHeaders();
    List<dynamic> all = [];
    int page = 1;
    while (true) {
      String url = '$baseUrl/products?limit=100&page=$page';
      if (category != null) {
        url += '&category_id=${Uri.encodeQueryComponent(category)}';
      }
      if (lat != null && lng != null) {
        url += "&lat=$lat&lng=$lng";
      }
      debugPrint('PRODUCTS URL: $url');
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_timeout);
      final data = _safeDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
          (data['error'] ?? 'Failed to load products').toString(),
        );
      }
      final List<dynamic> items = data['products'] ?? [];
      all.addAll(items);
      final totalPages = (data['total_pages'] ?? 1) as int;
      if (page >= totalPages || items.isEmpty) break;
      page++;
    }
    return all;
  }

  static Future<List<dynamic>> searchProducts(String query) async {
    final headers = await getHeaders();
    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/products/search?q=${Uri.encodeQueryComponent(query)}',
          ),
          headers: headers,
        )
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception((data['error'] ?? 'Search failed').toString());
    }
    return data['products'] ?? [];
  }

  // ---- Cart ----

  static Future<Map<String, dynamic>> getCart() async {
    final res = await http
        .get(Uri.parse('$baseUrl/cart'), headers: await getHeaders())
        .timeout(_timeout);
    final data = _safeDecode(res.body);
    if (res.statusCode != 200)
      throw Exception(data['error'] ?? 'Failed to load cart');
    return data;
  }

  static Future<Map<String, dynamic>> addToCart(
    int productId,
    int quantity,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/cart'),
          headers: await getHeaders(),
          body: jsonEncode({'product_id': productId, 'quantity': quantity}),
        )
        .timeout(_timeout);
    final data = _safeDecode(res.body);
    if (res.statusCode != 201)
      throw Exception(data['error'] ?? 'Failed to add item to cart');
    return data;
  }

  static Future<Map<String, dynamic>> updateCartItem(
    int itemId,
    int quantity,
  ) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/cart/$itemId'),
          headers: await getHeaders(),
          body: jsonEncode({'quantity': quantity}),
        )
        .timeout(_timeout);
    final data = _safeDecode(res.body);
    if (res.statusCode != 200)
      throw Exception(data['error'] ?? 'Failed to update cart item');
    return data;
  }

  static Future<Map<String, dynamic>> removeCartItem(int itemId) async {
    final res = await http
        .delete(Uri.parse('$baseUrl/cart/$itemId'), headers: await getHeaders())
        .timeout(_timeout);
    final data = _safeDecode(res.body);
    if (res.statusCode != 200)
      throw Exception(data['error'] ?? 'Failed to remove cart item');
    return data;
  }

  // ---- Addresses ----

  static Future<List<dynamic>> getAddresses() async {
    final headers = await getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/addresses'), headers: headers)
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    return data['addresses'] ?? [];
  }

  static Future<Map<String, dynamic>> createAddress(
    Map<String, dynamic> address,
  ) async {
    final headers = await getHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/addresses'),
          headers: headers,
          body: jsonEncode(address),
        )
        .timeout(_timeout);
    return _safeDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateAddress(
    String id,
    Map<String, dynamic> address,
  ) async {
    final headers = await getHeaders();
    final response = await http
        .put(
          Uri.parse('$baseUrl/addresses/$id'),
          headers: headers,
          body: jsonEncode(address),
        )
        .timeout(_timeout);
    return _safeDecode(response.body);
  }

  static Future<void> deleteAddress(String id) async {
    final headers = await getHeaders();
    final response = await http
        .delete(Uri.parse('$baseUrl/addresses/$id'), headers: headers)
        .timeout(_timeout);
    if (response.statusCode != 200 && response.statusCode != 204) {
      String errMsg = 'status ${response.statusCode}: ${response.body}';
      try {
        final data = _safeDecode(response.body);
        if (data is Map && data['error'] != null) {
          errMsg = '${response.statusCode}: ${data['error']}';
        }
      } catch (_) {}
      throw Exception(errMsg);
    }
  }

  static Future<void> deleteAccount() async {
    final headers = await getHeaders();
    final response = await http
        .delete(Uri.parse('$baseUrl/auth/me'), headers: headers)
        .timeout(_timeout);
    if (response.statusCode != 200 && response.statusCode != 204) {
      String errMsg = 'status ${response.statusCode}: ${response.body}';
      try {
        final data = _safeDecode(response.body);
        if (data is Map && data['error'] != null) {
          errMsg = '${response.statusCode}: ${data['error']}';
        }
      } catch (_) {}
      throw Exception(errMsg);
    }
  }

  // ---- Orders / checkout / payment / returns ----

  static Future<List<dynamic>> getOrders({
    int page = 1,
    int limit = 100,
  }) async {
    final headers = await getHeaders();
    final response = await http
        .get(
          Uri.parse('$baseUrl/orders?page=$page&limit=$limit'),
          headers: headers,
        )
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception((data['error'] ?? 'Failed to load orders').toString());
    }
    return data['orders'] ?? [];
  }

  static Future<Map<String, dynamic>> getNotificationPrefs() async {
    final headers = await getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/notification-prefs'), headers: headers)
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        data['error'] ?? 'Failed to load notification preferences',
      );
    }
    return data;
  }

  static Future<Map<String, dynamic>> updateNotificationPrefs(
    Map<String, bool> prefs,
  ) async {
    final headers = await getHeaders();
    final response = await http
        .put(
          Uri.parse('$baseUrl/notification-prefs'),
          headers: headers,
          body: jsonEncode(prefs),
        )
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        data['error'] ?? 'Failed to save notification preferences',
      );
    }
    return data;
  }

  static Future<List<GiftCardModel>> getRedeemedGiftCards() async {
    final headers = await getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/gift-cards'), headers: headers)
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load gift cards');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return GiftCardModel(
        id: m['id'].toString(),
        cardNumber: m['card_number'].toString(),
        balance: (m['balance'] as num).toDouble(),
        expiryDate: DateTime.parse(m['expiry_date'].toString()),
        status: GiftCardStatus.redeemed,
      );
    }).toList();
  }

  static Future<GiftCardModel> redeemGiftCard(String code) async {
    final headers = await getHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/gift-cards/redeem'),
          headers: headers,
          body: jsonEncode({'code': code.trim()}),
        )
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Redemption failed');
    }
    return GiftCardModel(
      id: data['id'].toString(),
      cardNumber: data['card_number'].toString(),
      balance: (data['balance'] as num).toDouble(),
      expiryDate: DateTime.parse(data['expiry_date'].toString()),
      status: GiftCardStatus.redeemed,
    );
  }

  static Future<Map<String, dynamic>> getWallet() async {
    final headers = await getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/wallet'), headers: headers)
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to load wallet');
    }
    return data;
  }

  static Future<Map<String, dynamic>> createWalletTopupOrder(int amount) async {
    final headers = await getHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/wallet/topup'),
          headers: headers,
          body: jsonEncode({'amount': amount}),
        )
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to start wallet top-up');
    }
    return data;
  }

  static Future<Map<String, dynamic>> verifyWalletTopup({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final headers = await getHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/wallet/topup/verify'),
          headers: headers,
          body: jsonEncode({
            'razorpay_order_id': razorpayOrderId,
            'razorpay_payment_id': razorpayPaymentId,
            'razorpay_signature': razorpaySignature,
          }),
        )
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to verify wallet top-up');
    }
    return data;
  }

  static Future<Map<String, dynamic>> checkout({
    required int addressId,
    String paymentMethod = 'online',
    String? couponCode,
    bool useWallet = false,
  }) async {
    final headers = await getHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/orders/checkout'),
          headers: headers,
          body: jsonEncode({
            'address_id': addressId,
            'payment_method': paymentMethod,
            if (couponCode != null && couponCode.isNotEmpty)
              'coupon_code': couponCode,
            'use_wallet': useWallet,
          }),
        )
        .timeout(_timeout);
    return _safeDecode(response.body);
  }

  static Future<Map<String, dynamic>> validateCoupon(
    String code,
    double orderAmount,
  ) async {
    final headers = await getHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/coupons/validate'),
          headers: headers,
          body: jsonEncode({'code': code, 'order_amount': orderAmount}),
        )
        .timeout(_timeout);
    final data = _safeDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception((data['error'] ?? 'Invalid coupon code').toString());
    }
    return data;
  }

  static Future<Map<String, dynamic>> createPaymentOrder(int orderId) async {
    final headers = await getHeaders();
    final response = await http
        .post(Uri.parse('$baseUrl/orders/$orderId/payment'), headers: headers)
        .timeout(_timeout);
    return _safeDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final headers = await getHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/orders/$orderId/payment/verify'),
          headers: headers,
          body: jsonEncode({
            'razorpay_order_id': razorpayOrderId,
            'razorpay_payment_id': razorpayPaymentId,
            'razorpay_signature': razorpaySignature,
          }),
        )
        .timeout(_timeout);
    return _safeDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMe() async {
    final headers = await getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/auth/me'), headers: headers)
        .timeout(_timeout);
    final data = _safeDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception((data['error'] ?? 'Failed to load profile').toString());
    }
    return data;
  }

  static Future<Map<String, dynamic>> updateMe(
    Map<String, dynamic> body,
  ) async {
    final headers = await getHeaders();
    final response = await http
        .put(
          Uri.parse('$baseUrl/auth/me'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    final data = _safeDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception((data['error'] ?? 'Failed to update profile').toString());
    }
    return data;
  }

  static Future<Map<String, dynamic>> getOrder(int orderId) async {
    final headers = await getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/orders/$orderId'), headers: headers)
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load order');
    }
    return _safeDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getOrderTracking(int orderId) async {
    final headers = await getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/orders/$orderId/tracking'), headers: headers)
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception((data['error'] ?? 'Failed to load tracking').toString());
    }
    return data;
  }

  static Future<Map<String, dynamic>> getDeliveryRating(int orderId) async {
    final headers = await getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/orders/$orderId/rating'), headers: headers)
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load rating');
    }
    return _safeDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> submitDeliveryRating(
    int orderId,
    int rating,
    String review,
  ) async {
    final headers = await getHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/orders/$orderId/rating'),
          headers: headers,
          body: jsonEncode({'rating': rating, 'review': review}),
        )
        .timeout(_timeout);
    if (response.statusCode != 201) {
      String msg = 'Could not submit rating';
      try {
        msg = (_safeDecode(response.body)['error'] ?? msg).toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    final headers = await getHeaders();
    final response = await http
        .put(Uri.parse('$baseUrl/orders/$orderId/cancel'), headers: headers)
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception((data['error'] ?? 'Could not cancel order').toString());
    }
    return data;
  }

  /// Uploads a single image file (e.g. a return-request photo) and returns
  /// the hosted image_url that can be stored on a Product/return_request/etc.
  static Future<String> uploadReturnImage(File file) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', file.path));
    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);
    final data = _safeDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception((data['error'] ?? 'Could not upload image').toString());
    }
    return data['image_url'] as String;
  }

  static Future<Map<String, dynamic>> requestReturn({
    required int orderId,
    required String reason,
    required List<Map<String, dynamic>> items,
    String? imageUrl,
    List<String>? imageUrls,
  }) async {
    final headers = await getHeaders();
    final body = <String, dynamic>{'reason': reason, 'items': items};
    if (imageUrls != null && imageUrls.length > 1) {
      body['image_urls'] = imageUrls;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      body['image_url'] = imageUrl;
    }
    final response = await http
        .post(
          Uri.parse('$baseUrl/orders/$orderId/return'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(
        (data['error'] ?? 'Could not submit return request').toString(),
      );
    }
    return data;
  }

  static Future<List<dynamic>> getMyReturns() async {
    final headers = await getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/returns'), headers: headers)
        .timeout(_timeout);
    final data = _safeDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(
        (data['error'] ?? 'Could not load return requests').toString(),
      );
    }
    return data['return_requests'] ?? [];
  }
}
