import 'package:firebase_database/firebase_database.dart';

class UserNotificationService {
  final db = FirebaseDatabase.instance;

  DatabaseReference getUserNotifications(String uid) {
    return db.ref("user_notifications/$uid");
  }
}