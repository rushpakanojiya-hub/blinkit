import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://32-196-3-31.sslip.io/api/v1';

  static const Duration _timeout = Duration(seconds: 30);

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
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
  static Future<Map<String, dynamic>> verifyOTP(String phone, String otp) => verifyOtp(phone, otp);

  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: await getHeaders(auth: false),
      body: jsonEncode({'phone': phone}),
    ).timeout(_timeout);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: await getHeaders(auth: false),
      body: jsonEncode({'phone': phone, 'otp': otp}),
    ).timeout(_timeout);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['token'] != null) {
      await saveToken(data['token']);
    }
    return data;
  }

  static Future<List<dynamic>> getMyDeliveries({String? status}) async {
    var url = '$baseUrl/delivery/orders';
    if (status != null) url += '?status=$status';
    final res = await http.get(Uri.parse(url), headers: await getHeaders()).timeout(_timeout);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data['orders'] ?? [];
    throw Exception(data['error'] ?? 'Failed to load orders');
  }

  static Future<Map<String, dynamic>> markShipped(int orderId) async {
    final res = await http.put(
      Uri.parse('$baseUrl/delivery/orders/$orderId/status'),
      headers: await getHeaders(),
      body: jsonEncode({'status': 'shipped'}),
    ).timeout(_timeout);
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Failed to update status');
    return data;
  }

  static Future<Map<String, dynamic>> confirmDelivery(int orderId) async {
    final res = await http.put(
      Uri.parse('$baseUrl/delivery/orders/$orderId/deliver'),
      headers: await getHeaders(),
    ).timeout(_timeout);
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Failed to confirm delivery');
    return data;
  }

  static Future<bool> getOnlineStatus() async {
    final res = await http.get(Uri.parse('$baseUrl/delivery/status'), headers: await getHeaders()).timeout(_timeout);
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Failed to load status');
    return data['is_online'] == true;
  }

  static Future<bool> updateOnlineStatus(bool isOnline) async {
    final res = await http.put(
      Uri.parse('$baseUrl/delivery/status'),
      headers: await getHeaders(),
      body: jsonEncode({'is_online': isOnline}),
    ).timeout(_timeout);
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Failed to update status');
    return data['is_online'] == true;
  }

  static Future<void> updateLocation(double lat, double lng) async {
    await http.put(
      Uri.parse('$baseUrl/delivery/location'),
      headers: await getHeaders(),
      body: jsonEncode({'lat': lat, 'lng': lng}),
    ).timeout(_timeout);
  }

  static Future<Map<String, dynamic>> getEarnings() async {
    final res = await http.get(Uri.parse('$baseUrl/delivery/earnings'), headers: await getHeaders()).timeout(_timeout);
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Failed to load earnings');
    return data;
  }

  // ---- Products ----

  static Future<List<dynamic>> getProducts({String? category}) async {
    final headers = await getHeaders();
    List<dynamic> all = [];
    int page = 1;
    while (true) {
      String url = '$baseUrl/products?limit=100&page=$page';
      if (category != null) {
        url += '&category_id=${Uri.encodeQueryComponent(category)}';
      }
      final response = await http.get(Uri.parse(url), headers: headers).timeout(_timeout);
      final data = jsonDecode(response.body);
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
    final response = await http.get(
      Uri.parse('$baseUrl/products/search?q=${Uri.encodeQueryComponent(query)}'),
      headers: headers,
    ).timeout(_timeout);
    final data = jsonDecode(response.body);
    return data['products'] ?? [];
  }

  // ---- Cart ----

  static Future<Map<String, dynamic>> getCart() async {
    final res = await http.get(Uri.parse('$baseUrl/cart'), headers: await getHeaders()).timeout(_timeout);
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Failed to load cart');
    return data;
  }

  static Future<Map<String, dynamic>> addToCart(int productId, int quantity) async {
    final res = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: await getHeaders(),
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    ).timeout(_timeout);
    final data = jsonDecode(res.body);
    if (res.statusCode != 201) throw Exception(data['error'] ?? 'Failed to add item to cart');
    return data;
  }

  static Future<Map<String, dynamic>> updateCartItem(int itemId, int quantity) async {
    final res = await http.put(
      Uri.parse('$baseUrl/cart/$itemId'),
      headers: await getHeaders(),
      body: jsonEncode({'quantity': quantity}),
    ).timeout(_timeout);
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Failed to update cart item');
    return data;
  }

  static Future<Map<String, dynamic>> removeCartItem(int itemId) async {
    final res = await http.delete(Uri.parse('$baseUrl/cart/$itemId'), headers: await getHeaders()).timeout(_timeout);
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Failed to remove cart item');
    return data;
  }

  // ---- Addresses ----

  static Future<List<dynamic>> getAddresses() async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/addresses'), headers: headers).timeout(_timeout);
    final data = jsonDecode(response.body);
    return data['addresses'] ?? [];
  }

  static Future<Map<String, dynamic>> createAddress(Map<String, dynamic> address) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/addresses'),
      headers: headers,
      body: jsonEncode(address),
    ).timeout(_timeout);
    return jsonDecode(response.body);
  }

  static Future<void> deleteAddress(String id) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/addresses/$id'),
      headers: headers,
    ).timeout(_timeout);
    if (response.statusCode != 200 && response.statusCode != 204) {
      String errMsg = 'status ${response.statusCode}: ${response.body}';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['error'] != null) {
          errMsg = '${response.statusCode}: ${data['error']}';
        }
      } catch (_) {}
      throw Exception(errMsg);
    }
  }

  // ---- Orders / checkout / payment / returns ----

  static Future<List<dynamic>> getOrders({int page = 1, int limit = 100}) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders?page=$page&limit=$limit'),
      headers: headers,
    ).timeout(_timeout);
    final data = jsonDecode(response.body);
    return data['orders'] ?? [];
  }

  static Future<Map<String, dynamic>> checkout({
    required int addressId,
    String paymentMethod = 'online',
    String? couponCode,
    bool useWallet = false,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/checkout'),
      headers: headers,
      body: jsonEncode({
        'address_id': addressId,
        'payment_method': paymentMethod,
        if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
        'use_wallet': useWallet,
      }),
    ).timeout(_timeout);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createPaymentOrder(int orderId) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/payment'),
      headers: headers,
    ).timeout(_timeout);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/payment/verify'),
      headers: headers,
      body: jsonEncode({
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      }),
    ).timeout(_timeout);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getOrder(int orderId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: headers,
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load order');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getOrderTracking(int orderId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId/tracking'),
      headers: headers,
    ).timeout(_timeout);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/cancel'),
      headers: headers,
    ).timeout(_timeout);
    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception((data['error'] ?? 'Could not cancel order').toString());
    }
    return data;
  }

  static Future<Map<String, dynamic>> requestReturn({
    required int orderId,
    required String reason,
    required List<Map<String, dynamic>> items,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/return'),
      headers: headers,
      body: jsonEncode({'reason': reason, 'items': items}),
    ).timeout(_timeout);
    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception((data['error'] ?? 'Could not submit return request').toString());
    }
    return data;
  }

  static Future<List<dynamic>> getMyReturns() async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/returns'), headers: headers).timeout(_timeout);
    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception((data['error'] ?? 'Could not load return requests').toString());
    }
    return data['return_requests'] ?? [];
  }
}







