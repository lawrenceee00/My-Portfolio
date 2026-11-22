import 'package:flutter/material.dart';
import 'package:t2c/services/api_services.dart';
import './notification_manager.dart';

class NotificationsScreen extends StatefulWidget {
  final int userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _primary = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F8F5);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF0E2018);
  static const Color _textMid = Color(0xFF4A6557);
  static const Color _textLight = Color(0xFF8FAE9C);
  static const Color _border = Color(0xFFDDEDE4);

  bool _loading = true;
  List<AppNotification> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    final response = await ApiService.getNotifications(widget.userId);

    if (!mounted) return;

    if (response.success) {
      final data = response.data as Map<String, dynamic>;

      setState(() {
        _items = data['notifications'] as List<AppNotification>;
        _loading = false;
      });

      // Mark everything as read now that the user is viewing the list, and
      // clear the badge immediately rather than waiting for the next poll.
      final unreadIds = _items
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toList();

      if (unreadIds.isNotEmpty) {
        await ApiService.markNotificationsRead(
          widget.userId,
          notificationIds: unreadIds,
        );
        NotificationManager.unreadCount.value = 0;
      }
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${d.month}/${d.day}/${d.year}';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'redemption_status':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _surface,
        foregroundColor: _textDark,
        elevation: 0,
      ),

      body: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: _border,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textMid,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = _items[i];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _iconFor(n.type),
                            color: _primary,
                            size: 19,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                n.message,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _textMid,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _timeAgo(n.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
