class NotificationModel {
  String id;
  String title;
  String message;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
  });
}