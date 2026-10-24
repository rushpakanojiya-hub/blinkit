import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../screens/support/chat_support_screen.dart';
import '../services/api_service.dart';

const Color _kGreen = Color(0xFF0C831F);

class _WindowInfo {
  final bool delivered;
  final bool open;
  final DateTime? deadline;
  const _WindowInfo({required this.delivered, required this.open, this.deadline});
}

/// "Report a problem" card for the order details screen.
///
/// - Order not delivered yet: plain "chat with support" (delays etc.).
/// - Delivered and inside the window: report button with the deadline.
/// - Delivered and window over: says so, and offers general chat support
///   (an agent can still help; the server only blocks order-linked tickets).
///
/// The server enforces the window; this card only explains it. If the window
/// call fails, the card stays hidden.
class ComplaintWindowCard extends StatefulWidget {
  final String orderId;

  /// Called once the window is known; true = still open (or not delivered yet).
  final ValueChanged<bool>? onLoaded;

  const ComplaintWindowCard({super.key, required this.orderId, this.onLoaded});

  @override
  State<ComplaintWindowCard> createState() => _ComplaintWindowCardState();
}

class _ComplaintWindowCardState extends State<ComplaintWindowCard> {
  _WindowInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/support/orders/${widget.orderId}/window'),
            headers: await ApiService.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      final info = _WindowInfo(
        delivered: data['delivered'] == true,
        open: data['open'] == true,
        deadline: DateTime.tryParse((data['deadline'] ?? '').toString())?.toLocal(),
      );
      setState(() => _info = info);
      widget.onLoaded?.call(info.open);
    } catch (_) {
      // Card stays hidden; the server enforces the window anyway.
    }
  }

  String _remaining(DateTime d) {
    final diff = d.difference(DateTime.now());
    if (diff.isNegative) return 'ending now';
    if (diff.inHours >= 24) return '${diff.inDays}d ${diff.inHours % 24}h left';
    if (diff.inHours >= 1) return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    return '${diff.inMinutes < 1 ? 1 : diff.inMinutes}m left';
  }

  String _when(DateTime d) => DateFormat('EEE, d MMM, h:mm a').format(d);

  void _openChat({int? orderId}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatSupportScreen(orderId: orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (info == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final orderIdInt = int.tryParse(widget.orderId);
    final deadline = info.deadline;

    final String title;
    final String subtitle;
    final String button;
    final bool primary;
    final VoidCallback onTap;

    if (!info.delivered) {
      title = 'Problem with this order?';
      subtitle = 'Delayed or something not right? Chat with our team.';
      button = 'Chat with support';
      primary = false;
      onTap = () => _openChat(orderId: orderIdInt);
    } else if (info.open) {
      title = 'Something wrong with your items?';
      subtitle = deadline == null
          ? 'Report it from here.'
          : 'Return or report items by ${_when(deadline)} (${_remaining(deadline)}).';
      button = 'Report a problem';
      primary = true;
      onTap = () => _openChat(orderId: orderIdInt);
    } else {
      title = 'Reporting window closed';
      subtitle = deadline == null
          ? 'The time to return or report items from this order is over.'
          : 'Items from this order could be returned or reported until ${_when(deadline)}. '
              'For anything else, chat with support and mention order #${widget.orderId}.';
      button = 'Chat with support';
      primary = false;
      onTap = () => _openChat();
    }

    final buttonText = Text(button, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.poppins(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          primary
              ? FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _kGreen),
                  onPressed: onTap,
                  child: buttonText,
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kGreen,
                    side: const BorderSide(color: _kGreen),
                  ),
                  onPressed: onTap,
                  child: buttonText,
                ),
        ],
      ),
    );
  }
}
