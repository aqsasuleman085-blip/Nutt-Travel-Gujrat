/// A single message inside a support ticket's thread - either the user's
/// original question / follow-up, or the admin's reply.
class SupportMessage {
  final String senderId; // uid of user, or 'admin'
  final String senderName;
  final bool isFromAdmin;
  final String text;
  final DateTime sentAt;

  SupportMessage({
    required this.senderId,
    required this.senderName,
    required this.isFromAdmin,
    required this.text,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'isFromAdmin': isFromAdmin,
      'text': text,
      'sentAt': sentAt.millisecondsSinceEpoch,
    };
  }

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      isFromAdmin: map['isFromAdmin'] == true,
      text: map['text'] ?? '',
      sentAt: map['sentAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['sentAt'])
          : DateTime.now(),
    );
  }
}

/// A support ticket - one user question and its full reply thread.
/// Stored in Firestore under the `support_tickets` collection, one document
/// per ticket, with `messages` as an embedded array (tickets are low-volume
/// and short-lived, so an embedded list keeps reads/writes simple - no
/// subcollection needed).
///
/// This is intentionally separate from the existing per-booking
/// notifications (approved/rejected/refunded) and from the admin broadcast
/// feature - it's a two-way, per-user, per-question thread rather than a
/// one-way alert.
class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;

  /// Optional reference to one of the user's bookings for admin context.
  /// Empty string if the question isn't tied to a specific booking.
  final String bookingId;
  final String bookingSummary; // e.g. "Gujrat → Lahore, 20 Jul 2026, Seat 12"

  final List<SupportMessage> messages;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// True once at least one admin reply exists - used only to show a
  /// "Replied" badge; there is no closing/resolving step, the user can
  /// always send another follow-up.
  bool get hasReply => messages.any((m) => m.isFromAdmin);

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.bookingId = '',
    this.bookingSummary = '',
    required this.messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'bookingId': bookingId,
      'bookingSummary': bookingSummary,
      'messages': messages.map((m) => m.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    final rawMessages = map['messages'];
    final messages = <SupportMessage>[];
    if (rawMessages is List) {
      for (final m in rawMessages) {
        if (m is Map) {
          messages.add(SupportMessage.fromMap(Map<String, dynamic>.from(m)));
        }
      }
    }

    return SupportTicket(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      bookingId: map['bookingId'] ?? '',
      bookingSummary: map['bookingSummary'] ?? '',
      messages: messages,
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
