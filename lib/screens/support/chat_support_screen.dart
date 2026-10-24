import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/support_chat_model.dart';
import '../../services/support_chat_service.dart';
import '../../widgets/state_views.dart';

const Color _kGreen = Color(0xFF0C831F);
const Duration _pollEvery = Duration(seconds: 4);

const Map<String, String> _issueTypes = {
  'delivery_issue': 'Delivery issue',
  'missing_item': 'Missing item',
  'wrong_item': 'Wrong item',
  'damaged_item': 'Damaged item',
  'expired_item': 'Expired item',
  'payment_issue': 'Payment issue',
  'refund_issue': 'Refund issue',
  'other': 'Something else',
};

class _PendingMessage {
  final String text;
  _PendingMessage(this.text);
}

/// Live chat backed by the support-ticket API. The thread you see here is the
/// same one admins reply to in the admin panel's "Customer Support" page.
class ChatSupportScreen extends StatefulWidget {
  /// Optional: link the ticket to an order (pass it from the order screen).
  final int? orderId;
  const ChatSupportScreen({super.key, this.orderId});

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _timer;

  bool _loading = true;
  bool _needsLogin = false;
  String? _error;

  ChatTicket? _ticket;
  List<ChatMessage> _messages = [];
  final List<_PendingMessage> _pending = [];
  String _issueType = 'other';

  bool _sending = false;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_loading && !_needsLogin) {
        _poll();
        _startPolling();
      }
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  // ---------------------------------------------------------------- loading

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!await SupportChatService.isLoggedIn()) {
        if (!mounted) return;
        setState(() {
          _needsLogin = true;
          _loading = false;
        });
        return;
      }
      // Reuse the newest open / in-progress ticket so the conversation continues.
      final tickets = await SupportChatService.getMyTickets();
      final active = tickets.where((t) => t.isActive && (widget.orderId == null ? t.orderId == null : t.orderId == widget.orderId)).toList();
      ChatTicket? ticket;
      List<ChatMessage> messages = [];
      if (active.isNotEmpty) {
        final res = await SupportChatService.getMessages(active.first.id);
        ticket = res.ticket;
        messages = res.messages;
      }
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom(jump: true);
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (e is SupportChatException && e.unauthorized) {
          _needsLogin = true;
        } else {
          _error = _friendly(e);
        }
      });
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollEvery, (_) => _poll());
  }

  Future<void> _poll() async {
    final t = _ticket;
    if (t == null || _polling || _sending) return;
    _polling = true;
    try {
      final res = await SupportChatService.getMessages(t.id);
      if (!mounted || _sending || _pending.isNotEmpty) return;
      final changed = res.messages.length != _messages.length ||
          (res.messages.isNotEmpty && _messages.isNotEmpty && res.messages.last.id != _messages.last.id) ||
          res.ticket.status != t.status;
      if (changed) {
        final wasNearBottom = _isNearBottom();
        setState(() {
          _ticket = res.ticket;
          _messages = res.messages;
        });
        if (wasNearBottom) _scrollToBottom();
      }
    } catch (_) {
      // Silent: the next tick retries.
    } finally {
      _polling = false;
    }
  }

  // ---------------------------------------------------------------- sending

  String _subjectFrom(String text) {
    final oneLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return oneLine.length > 50 ? '${oneLine.substring(0, 50)}\u2026' : oneLine;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final pending = _PendingMessage(text);
    _controller.clear();
    setState(() {
      _sending = true;
      _pending.add(pending);
    });
    _scrollToBottom();

    try {
      ChatTicket? ticket = _ticket;
      List<ChatMessage> messages = _messages;
      if (ticket == null) {
        final r = await SupportChatService.createTicket(
          subject: _subjectFrom(text),
          message: text,
          issueType: _issueType,
          orderId: widget.orderId,
        );
        ticket = r.ticket;
        messages = [r.message];
      } else {
        final msg = await SupportChatService.sendMessage(ticket.id, text);
        messages = [...messages, msg];
        // Backend reopens resolved/closed tickets on a customer reply.
        if (ticket.isClosed) ticket = ticket.copyWith(status: 'open');
      }
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _messages = messages;
        _pending.remove(pending);
        _sending = false;
      });
      _scrollToBottom();
      if (_timer == null || !_timer!.isActive) _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pending.remove(pending);
        _sending = false;
      });
      _controller.text = text; // give the text back so nothing is lost
      _controller.selection = TextSelection.collapsed(offset: text.length);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message not sent. ${_friendly(e)}')));
    }
  }

  // ---------------------------------------------------------------- helpers

  String _friendly(Object e) {
    if (e is SupportChatException) return e.message;
    if (e is SocketException) return 'No internet connection.';
    if (e is TimeoutException) return 'The server took too long to respond.';
    return e.toString().replaceAll('Exception: ', '');
  }

  bool _isNearBottom() {
    if (!_scroll.hasClients) return true;
    return _scroll.position.maxScrollExtent - _scroll.offset < 120;
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(target, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  String _time(DateTime d) {
    final l = d.toLocal();
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final m = l.minute.toString().padLeft(2, '0');
    return '$h:$m ${l.hour >= 12 ? 'PM' : 'AM'}';
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return 'Today';
    if (_sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Waiting for a reply';
      case 'in_progress':
        return 'Support is on it';
      default:
        return 'Resolved';
    }
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat Support',
                style: GoogleFonts.poppins(color: scheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
            if (_ticket != null)
              Text(_statusLabel(_ticket!.status),
                  style: GoogleFonts.poppins(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
      body: _buildBody(scheme),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    if (_loading) return const LoadingView();
    if (_needsLogin) return _loginPrompt(scheme);
    if (_error != null) return ErrorView(message: _error!, onRetry: () => _bootstrap());

    return Column(
      children: [
        Expanded(
          child: (_ticket == null && _pending.isEmpty) ? _emptyState(scheme) : _messageList(scheme),
        ),
        if (_ticket != null && _ticket!.isClosed) _closedBanner(scheme),
        _composer(scheme),
      ],
    );
  }

  Widget _loginPrompt(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 40, color: scheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('Log in to chat with support',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface)),
            const SizedBox(height: 6),
            Text('We need your account to link the chat to your orders.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kGreen),
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text('Back to help', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline, color: _kGreen, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text('How can we help?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface)),
        const SizedBox(height: 6),
        Text('Pick a topic, then describe the problem. Replies from our team show up right here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6))),
        if (widget.orderId != null) ...[
          const SizedBox(height: 8),
          Text('This chat will be linked to order #${widget.orderId}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: _kGreen)),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _issueTypes.entries.map((e) {
            final selected = _issueType == e.key;
            return ChoiceChip(
              label: Text(e.value,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : scheme.onSurface)),
              selected: selected,
              selectedColor: _kGreen,
              showCheckmark: false,
              onSelected: (_) => setState(() => _issueType = e.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _messageList(ColorScheme scheme) {
    final children = <Widget>[];
    DateTime? lastDay;
    for (final m in _messages) {
      final d = m.createdAt.toLocal();
      if (lastDay == null || !_sameDay(lastDay, d)) {
        children.add(_dayChip(scheme, d));
        lastDay = d;
      }
      children.add(_bubble(scheme, text: m.message, mine: m.isCustomer, time: _time(d)));
    }
    for (final p in _pending) {
      children.add(_bubble(scheme, text: p.text, mine: true, time: 'Sending\u2026', pending: true));
    }
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      children: children,
    );
  }

  Widget _dayChip(ColorScheme scheme, DateTime d) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
        child: Text(_dayLabel(d),
            style: GoogleFonts.poppins(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.6))),
      ),
    );
  }

  Widget _bubble(
    ColorScheme scheme, {
    required String text,
    required bool mine,
    required String time,
    bool pending = false,
  }) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: mine ? _kGreen.withValues(alpha: pending ? 0.6 : 1) : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text,
                style: GoogleFonts.poppins(fontSize: 13, color: mine ? Colors.white : scheme.onSurface)),
            const SizedBox(height: 2),
            Text(time,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: mine ? Colors.white70 : scheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _closedBanner(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: scheme.surfaceContainerHighest,
      child: Text('This ticket is marked resolved. Send a message to reopen it.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.7))),
    );
  }

  Widget _composer(ColorScheme scheme) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 13, color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Type your message',
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: _kGreen,
                  disabledBackgroundColor: _kGreen.withValues(alpha: 0.5),
                ),
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

