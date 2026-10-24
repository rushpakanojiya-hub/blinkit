// Models for the in-app support chat. Field names match the Go backend
// (SupportTicket / SupportMessage in internal/models/support.go).

class ChatTicket {
  final int id;
  final String subject;
  final String status; // open | in_progress | resolved | closed
  final String issueType;
  final int? orderId;
  final DateTime? createdAt;

  const ChatTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.issueType,
    this.orderId,
    this.createdAt,
  });

  factory ChatTicket.fromJson(Map<String, dynamic> j) {
    return ChatTicket(
      id: (j['id'] as num).toInt(),
      subject: (j['subject'] ?? '').toString(),
      status: (j['status'] ?? 'open').toString(),
      issueType: (j['issue_type'] ?? 'other').toString(),
      orderId: j['order_id'] == null ? null : (j['order_id'] as num).toInt(),
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
    );
  }

  ChatTicket copyWith({String? status}) => ChatTicket(
        id: id,
        subject: subject,
        status: status ?? this.status,
        issueType: issueType,
        orderId: orderId,
        createdAt: createdAt,
      );

  /// Ticket is still being worked on.
  bool get isActive => status == 'open' || status == 'in_progress';

  /// Ticket was resolved/closed. A customer reply reopens it (backend does this).
  bool get isClosed => status == 'resolved' || status == 'closed';
}

class ChatMessage {
  final int id;
  final int ticketId;
  final String senderType; // customer | admin
  final String message;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.ticketId,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    return ChatMessage(
      id: (j['id'] as num).toInt(),
      ticketId: (j['ticket_id'] as num).toInt(),
      senderType: (j['sender_type'] ?? 'customer').toString(),
      message: (j['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  bool get isCustomer => senderType == 'customer';
}
