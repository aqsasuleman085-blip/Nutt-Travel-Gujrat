import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/notification_model.dart';
import '../services/storage_service.dart';

class NotificationProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  late final StorageService _storageService;
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  
  NotificationProvider(this._prefs) {
    _storageService = StorageService(_prefs);
    _loadNotifications();
    _addSampleNotifications();
  }
  
  // Getters
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications => _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  
  // Load notifications from storage
  void _loadNotifications() {
    final notificationsData = _storageService.getNotifications();
    _notifications = notificationsData.map((data) => NotificationModel.fromMap(data)).toList();
    notifyListeners();
  }
  
  // Save notifications to storage
  Future<void> _saveNotifications() async {
    final notificationsData = _notifications.map((n) => n.toMap()).toList();
    await _storageService.saveNotifications(notificationsData);
  }
  
  // Add sample notifications
  void _addSampleNotifications() {
    if (_notifications.isEmpty) {
      final now = DateTime.now();
      final sampleNotifications = [
        NotificationModel(
          id: '1',
          title: 'User Verification Request',
          message: 'John Doe has requested account verification',
          type: 'verification',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        NotificationModel(
          id: '2',
          title: 'New Booking',
          message: 'Ahmed Khan booked a seat on Gujrat to Islamabad route',
          type: 'booking',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        NotificationModel(
          id: '3',
          title: 'System Maintenance',
          message: 'Scheduled maintenance will occur tonight at 2:00 AM',
          type: 'system',
          isRead: true,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];
      
      _notifications = sampleNotifications;
      _saveNotifications();
      notifyListeners();
    }
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        
        await _saveNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id,
        title: n.title,
        message: n.message,
        type: n.type,
        isRead: true,
        createdAt: n.createdAt,
      )).toList();
      
      await _saveNotifications();
      notifyListeners();
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
      final newNotification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
      );
      
      _notifications.insert(0, newNotification);
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }
  
  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
}