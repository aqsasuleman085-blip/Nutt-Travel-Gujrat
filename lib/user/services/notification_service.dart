import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserNotificationService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get notifications reference for current user
  DatabaseReference getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return _db.child("user_notifications/${user.uid}");
  }

  /// Get notifications reference for specific user
  DatabaseReference getUserNotificationsById(String uid) {
    return _db.child("user_notifications/$uid");
  }

  /// Send notification to user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? bookingId,
    String? refundId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final notificationRef = _db.child("user_notifications/$userId").push();

    await notificationRef.set({
      'notificationId': notificationRef.key,
      'title': title,
      'message': message,
      'type': type,
      'bookingId': bookingId ?? '',
      'refundId': refundId ?? '',
      'isRead': false,
      'createdAt': now,
      'timestamp': now,
    });
  }

  /// Mark single notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _db
        .child("user_notifications/$userId/$notificationId")
        .update({'isRead': true});
  }

  /// Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _db.child("user_notifications/$userId").get();
    if (snapshot.exists) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      for (var entry in data.entries) {
        await _db
            .child("user_notifications/$userId/${entry.key}")
            .update({'isRead': true});
      }
    }
  }

  /// Delete single notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _db.child("user_notifications/$userId/$notificationId").remove();
  }

  /// Delete all notifications for user
  Future<void> deleteAllNotifications(String userId) async {
    await _db.child("user_notifications/$userId").remove();
  }

  /// Stream notifications for current user
  Stream<DatabaseEvent> streamUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return _db.child("user_notifications/${user.uid}").onValue;
  }

  /// Get unread count for user
  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _db.child("user_notifications/$userId").get();
    if (!snapshot.exists) return 0;
    
    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    int unreadCount = 0;
    
    for (var entry in data.entries) {
      final isRead = entry.value['isRead'] ?? false;
      if (!isRead) unreadCount++;
    }
    
    return unreadCount;
  }

  /// Stream unread count
  Stream<int> streamUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);
    
    return _db.child("user_notifications/${user.uid}").onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return 0;
      
      final notifications = Map<dynamic, dynamic>.from(data as Map);
      int unreadCount = 0;
      
      for (var entry in notifications.entries) {
        final isRead = entry.value['isRead'] ?? false;
        if (!isRead) unreadCount++;
      }
      
      return unreadCount;
    });
  }
}