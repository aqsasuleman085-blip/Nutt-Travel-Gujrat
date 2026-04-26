import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  NotificationProvider() {
    _loadNotifications();
  }

  // Getters
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications => _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;

  void _loadNotifications() {
    _firestore.collection('notifications').orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      _notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationModel.fromMap(data);
      }).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error listening to notifications: $error');
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final unreadDocs = await _firestore.collection('notifications').where('isRead', isEqualTo: false).get();
      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final newNotificationData = {
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _firestore.collection('notifications').add(newNotificationData);
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
}