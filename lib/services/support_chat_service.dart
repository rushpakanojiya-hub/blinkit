import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/support_chat_model.dart';
import 'api_service.dart';

class SupportChatException implements Exception {
  final String message;
  final bool unauthorized;
  const SupportChatException(this.message, {this.unauthorized = false});

  @override
  String toString() => message;
}

/// Talks to the customer-facing support endpoints:
///   POST /support/tickets
///   GET  /support/tickets
///   GET  /support/tickets/:id/messages
///   POST /support/tickets/:id/messages
class SupportChatService {
  static const Duration _timeout = Duration(seconds: 20);

  static Future<bool> isLoggedIn() async => (await ApiService.getToken()) != null;

  static dynamic _parse(http.Response res) {
    dynamic body;
    try {
      body = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      body = null;
    }
    if (res.statusCode == 401) {
      throw const SupportChatException('Please log in again to chat with support.', unauthorized: true);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = (body is Map && body['error'] is String)
          ? body['error'] as String
          : 'Something went wrong (${res.statusCode})';
      throw SupportChatException(msg);
    }
    return body;
  }

  /// Own tickets, newest first (backend orders by created_at desc).
  static Future<List<ChatTicket>> getMyTickets() async {
    final res = await http
        .get(Uri.parse('${ApiService.baseUrl}/support/tickets'), headers: await ApiService.getHeaders())
        .timeout(_timeout);
    final body = _parse(res);
    if (body is! List) return [];
    return body.map((e) => ChatTicket.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Creates a ticket; the first message is saved together with it.
  static Future<({ChatTicket ticket, ChatMessage message})> createTicket({
    required String subject,
    required String message,
    String issueType = 'other',
    int? orderId,
  }) async {
    final res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/support/tickets'),
          headers: await ApiService.getHeaders(),
          body: jsonEncode({
            'subject': subject,
            'message': message,
            'issue_type': issueType,
            'order_id': ?orderId,
          }),
        )
        .timeout(_timeout);
    final body = _parse(res) as Map;
    return (
      ticket: ChatTicket.fromJson(Map<String, dynamic>.from(body['ticket'] as Map)),
      message: ChatMessage.fromJson(Map<String, dynamic>.from(body['message'] as Map)),
    );
  }

  /// Ticket + full message thread (oldest first).
  static Future<({ChatTicket ticket, List<ChatMessage> messages})> getMessages(int ticketId) async {
    final res = await http
        .get(Uri.parse('${ApiService.baseUrl}/support/tickets/$ticketId/messages'),
            headers: await ApiService.getHeaders())
        .timeout(_timeout);
    final body = _parse(res) as Map;
    final list = (body['messages'] as List?) ?? const [];
    return (
      ticket: ChatTicket.fromJson(Map<String, dynamic>.from(body['ticket'] as Map)),
      messages: list.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  /// Customer reply. Backend reopens the ticket if it was resolved/closed.
  static Future<ChatMessage> sendMessage(int ticketId, String message) async {
    final res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/support/tickets/$ticketId/messages'),
          headers: await ApiService.getHeaders(),
          body: jsonEncode({'message': message}),
        )
        .timeout(_timeout);
    final body = _parse(res) as Map;
    return ChatMessage.fromJson(Map<String, dynamic>.from(body));
  }
}

