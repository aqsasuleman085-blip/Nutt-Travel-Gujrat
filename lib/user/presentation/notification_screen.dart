import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nutt/user/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Color themeColor = const Color(0xff10B981);
  final UserNotificationService _notificationService =
      UserNotificationService();

  late String uid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead(uid);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteNotification(String key) async {
    await _notificationService.deleteNotification(uid, key);
  }

  Future<void> _deleteAllNotifications() async {
    await _notificationService.deleteAllNotifications(uid);
  }

  String _formatTime(dynamic time) {
    if (time == null) return "";
    try {
      int timestamp = time is int ? time : int.parse(time.toString());
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return "";
    }
  }

  // Admin "Broadcast Notification" category -> icon/color. Broadcasts are
  // written with an explicit `category` field (info/warning/critical/
  // cancellation) and `isBroadcast: true`, so they're checked first and
  // fall through to the existing booking-notification logic below when
  // absent - existing booking/refund notifications are unaffected.
  IconData? _getBroadcastIcon(String category) {
    switch (category) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'critical':
        return Icons.report_problem_rounded;
      case 'cancellation':
        return Icons.cancel_rounded;
      case 'info':
        return Icons.campaign_rounded;
      default:
        return null;
    }
  }

  Color? _getBroadcastColor(String category) {
    switch (category) {
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      case 'cancellation':
        return Colors.red.shade900;
      case 'info':
        return Colors.blue;
      default:
        return null;
    }
  }

  IconData _getIconForType(
    String type,
    String title, {
    String category = '',
    bool isSupportReply = false,
  }) {
    if (isSupportReply) return Icons.forum_rounded;

    final broadcastIcon = _getBroadcastIcon(category);
    if (broadcastIcon != null) return broadcastIcon;

    if (title.contains('Refund') || type.contains('refund')) {
      return Icons.abc_rounded;
    } else if (title.contains('Approved') || type.contains('approved')) {
      return Icons.check_circle;
    } else if (title.contains('Rejected') || type.contains('rejected')) {
      return Icons.cancel;
    } else if (title.contains('Booking') || type.contains('booking')) {
      return Icons.airplane_ticket;
    } else {
      return Icons.notifications;
    }
  }

  Color _getIconColor(
    String type,
    String title, {
    String category = '',
    bool isSupportReply = false,
  }) {
    if (isSupportReply) return themeColor;

    final broadcastColor = _getBroadcastColor(category);
    if (broadcastColor != null) return broadcastColor;

    if (title.contains('Refund') &&
        (title.contains('Processed') || title.contains('Approved'))) {
      return Colors.green;
    } else if (title.contains('Refund') && title.contains('Pending')) {
      return Colors.orange;
    } else if (title.contains('Approved')) {
      return Colors.green;
    } else if (title.contains('Rejected')) {
      return Colors.red;
    } else if (title.contains('Booking')) {
      return themeColor;
    } else {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.streamUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.white),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete All?"),
                          content: const Text("Remove all notifications?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete All"),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _deleteAllNotifications();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All notifications deleted'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _notificationService.streamUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No Notifications",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "You're all caught up!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final event = snapshot.data!;
          final data = event.snapshot.value;

          if (data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No Notifications",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          final notifications = Map<dynamic, dynamic>.from(data as Map);
          final items = notifications.entries.toList();

          // Sort by createdAt - latest first
          items.sort((a, b) {
            final aTime = a.value["createdAt"] ?? 0;
            final bTime = b.value["createdAt"] ?? 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final key = items[index].key;
              final item = items[index].value;

              final title = item["title"] ?? "";
              final message = item["message"] ?? "";
              final isRead = item["isRead"] ?? false;
              final createdAt = item["createdAt"];
              final type = item["type"] ?? "";
              final bookingId = item["bookingId"] ?? "";
              final category = item["category"] ?? "";
              final isBroadcast = item["isBroadcast"] == true;
              final isSupportReply = item["isSupportReply"] == true;

              final icon = _getIconForType(type, title,
                  category: category, isSupportReply: isSupportReply);
              final iconColor = _getIconColor(type, title,
                  category: category, isSupportReply: isSupportReply);

              return Dismissible(
                key: Key(key.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await _deleteNotification(key.toString());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification deleted')),
                    );
                  }
                },
                child: GestureDetector(
                  onTap: () async {
                    if (!isRead) {
                      await _notificationService.markAsRead(
                        uid,
                        key.toString(),
                      );
                      if (mounted) {
                        setState(() {});
                      }
                    }
                    // Optional: Navigate based on notification type
                    if (bookingId.isNotEmpty) {
                      // Navigate to booking details if needed
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Colors.white
                          : themeColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isRead
                            ? Colors.grey.shade200
                            : themeColor.withOpacity(0.3),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: iconColor.withOpacity(0.1),
                          child: Icon(icon, color: iconColor, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: isRead
                                            ? FontWeight.w500
                                            : FontWeight.bold,
                                        fontSize: 15,
                                        color: isRead
                                            ? Colors.black87
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              if (isBroadcast) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ANNOUNCEMENT',
                                    style: TextStyle(
                                      color: iconColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                              if (isSupportReply) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.forum_rounded, size: 11, color: iconColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'SUPPORT REPLY',
                                        style: TextStyle(
                                          color: iconColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                message,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(createdAt),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
