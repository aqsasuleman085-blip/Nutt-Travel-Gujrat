import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {
  int unread = 0;

  void updateUnread(int count) {
    unread = count;
    notifyListeners();
  }
}