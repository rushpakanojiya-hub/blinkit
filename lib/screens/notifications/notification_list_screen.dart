import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/notification_model.dart';
import '../settings/notification_preferences_screen.dart';

const Color kBrandGreen = Color(0xFF0C831F);
const Color kLightGreenBg = Color(0xFFEAF7EA);

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  late List<NotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _mockNotifications();
  }

  List<NotificationModel> _mockNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: '1',
        type: NotificationType.order,
        title: 'Order delivered!',
        message: 'Your order #BQ48213 has been delivered. Enjoy!',
        timestamp: now.subtract(const Duration(minutes: 20)),
        isRead: false,
      ),
      NotificationModel(
        id: '2',
        type: NotificationType.offer,
        title: 'Flat â‚¹100 OFF',
        message: 'Use code SAVE100 on orders above â‚¹500. Valid till midnight.',
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      NotificationModel(
        id: '3',
        type: NotificationType.order,
        title: 'Order out for delivery',
        message: 'Your order #BQ48199 is on the way and will arrive in 8 minutes.',
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: true,
      ),
      NotificationModel(
        id: '4',
        type: NotificationType.wallet,
        title: 'Cashback credited',
        message: 'â‚¹25 cashback has been added to your wallet.',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: '5',
        type: NotificationType.recommendation,
        title: 'Back in stock',
        message: 'Amul Milk 1L is back in stock near you.',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        isRead: true,
      ),
      NotificationModel(
        id: '6',
        type: NotificationType.update,
        title: 'App updated',
        message: 'We\'ve made the app faster and fixed a few bugs.',
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _markAsRead(NotificationModel n) {
    if (!n.isRead) {
      setState(() => n.isRead = true);
    }
  }

  void _dismiss(NotificationModel n) {
    setState(() => _notifications.removeWhere((e) => e.id == n.id));
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag_outlined;
      case NotificationType.offer:
        return Icons.local_offer_outlined;
      case NotificationType.wallet:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.recommendation:
        return Icons.thumb_up_alt_outlined;
      case NotificationType.update:
        return Icons.system_update_alt_outlined;
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: Text('Notifications',
            style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.onSurface),
            tooltip: 'Notification preferences',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                if (_unreadCount > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: kLightGreenBg,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600, color: kBrandGreen)),
                        InkWell(
                          onTap: _markAllRead,
                          child: Text('Mark all as read',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.bold, color: kBrandGreen)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _dismiss(n),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red.shade400,
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        child: InkWell(
                          onTap: () => _markAsRead(n),
                          child: Container(
                            color: n.isRead ? Colors.transparent : kLightGreenBg.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                      color: kLightGreenBg, shape: BoxShape.circle),
                                  child: Icon(_iconFor(n.type), color: kBrandGreen, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(n.title,
                                                style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.onSurface)),
                                          ),
                                          if (!n.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(left: 6, top: 3),
                                              decoration: const BoxDecoration(
                                                  color: kBrandGreen, shape: BoxShape.circle),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(n.message,
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                      const SizedBox(height: 4),
                                      Text(_timeAgo(n.timestamp),
                                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
