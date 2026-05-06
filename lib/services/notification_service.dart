import 'package:firebase_database/firebase_database.dart';

class AdminNotificationService {
  final db = FirebaseDatabase.instance;

  Future<void> sendNotification({
    required String uid,
    required String title,
    required String message,
  }) async {
    await db.ref("user_notifications/$uid").push().set({
      "title": title,
      "message": message,
      "isRead": false,
      "createdAt": DateTime.now().millisecondsSinceEpoch,
    });
  }
}