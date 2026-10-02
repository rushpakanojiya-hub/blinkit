import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../screens/order_screen.dart';
import '../screens/orders/order_details_screen.dart';

/// Handles Firebase push notification setup: initializing Firebase,
/// requesting notification permission, registering the device's FCM
/// token with our backend, showing a local notification when a push
/// arrives while the app is in the foreground, and routing a tap
/// (foreground / background / killed) to the Orders screen.
class PushNotificationService {
  /// Passed to MaterialApp so a notification tap can navigate without
  /// needing a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'order_updates',
    'Order updates',
    description: 'Order status, delivery and refund updates',
    importance: Importance.high,
  );

  static void _openFromId(String? orderId) {
    if (orderId == null || orderId.isEmpty) {
      _openOrders();
      return;
    }
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: orderId)),
    );
  }

  static void _openOrders() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const OrderScreen()),
    );
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (r) => _openFromId(r.payload),
      );
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);
      await android?.requestNotificationsPermission();

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) {
        await _registerTokenWithBackend(token);
      }
      messaging.onTokenRefresh.listen(_registerTokenWithBackend);

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp
          .listen((m) => _openFromId(m.data['order_id']?.toString()));

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        final id = initial.data['order_id']?.toString();
        Future.delayed(const Duration(milliseconds: 800), () => _openFromId(id));
      }
    } catch (e) {
      debugPrint('Push init failed: $e');
    }
  }

  /// Call this right after login succeeds. Re-sends the current FCM token
  /// with a valid JWT, in case initialize() already ran before login (e.g.
  /// app reopened straight into a logged-in session from a previous run)
  /// or _initialized was already true so initialize() itself is a no-op.
  static Future<void> registerCurrentToken() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerTokenWithBackend(token);
    } catch (e) {
      debugPrint('registerCurrentToken failed: $e');
    }
  }

  static void _onForeground(RemoteMessage msg) {
    final n = msg.notification;
    if (n == null) return;
    _local.show(
      payload: msg.data['order_id']?.toString(),
      msg.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'order_updates',
          'Order updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> _registerTokenWithBackend(String token) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/device-token'),
            headers: headers,
            body: jsonEncode({
              'token': token,
              'platform': 'android',
            }),
          )
          .timeout(const Duration(seconds: 15));
      print('Device token register status: ${response.statusCode}');
    } catch (e) {
      print('Device token register failed: $e');
    }
  }
}