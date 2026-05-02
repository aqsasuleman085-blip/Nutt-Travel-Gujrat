import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;
  StreamSubscription<DatabaseEvent>? _subscription;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  NotificationProvider() {
    _listenToNotifications();
  }

  // Getters
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;

  void _listenToNotifications() {
    _isLoading = true;
    notifyListeners();

    _subscription = _realtimeDb
        .ref('admin_notifications')
        .orderByChild('createdAt')
        .onValue
        .listen(
          (event) {
            final data = event.snapshot.value;
            if (data is Map) {
              final entries = data.entries.toList();
              entries.sort((a, b) {
                final aValue = (a.value as Map)['createdAt'] ?? 0;
                final bValue = (b.value as Map)['createdAt'] ?? 0;
                return bValue.compareTo(aValue);
              });
              _notifications = entries.map((entry) {
                final map = Map<String, dynamic>.from(entry.value as Map);
                return NotificationModel.fromMap({'id': entry.key, ...map});
              }).toList();
            } else {
              _notifications = [];
            }
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error loading notifications: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        await _realtimeDb
            .ref('admin_notifications/${_notifications[index].id}')
            .update({'isRead': true});
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      for (final notification in _notifications) {
        await _realtimeDb.ref('admin_notifications/${notification.id}').update({
          'isRead': true,
        });
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Add a new notification
  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await _realtimeDb.ref('admin_notifications').push().set({
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _realtimeDb.ref('admin_notifications/$notificationId').remove();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
