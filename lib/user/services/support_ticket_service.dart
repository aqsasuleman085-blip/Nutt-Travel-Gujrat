import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../admin_side/models/support_ticket_model.dart';

/// Shared Firestore/Realtime-DB logic for the support ticket feature.
/// Used by both the user side (ask a question, view own tickets, follow up)
/// and the admin side (view all tickets, reply).
///
/// Design mirrors the rest of the app: tickets live in the `support_tickets`
/// Firestore collection (so both sides can query/stream them), while the
/// "you have a new message" alerts piggyback on the two notification
/// systems that already exist and are already proven reliable:
///   - a new ticket -> `admin_notifications` (Realtime DB) - same path the
///     admin bell already listens to via NotificationProvider
///   - an admin reply -> `user_notifications/{uid}` (Realtime DB) - same
///     path the user bell already listens to via UserNotificationService
class SupportTicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('support_tickets');

  // ── User side ─────────────────────────────────────────────────────────

  /// Creates a new ticket with the user's first question and notifies the
  /// admin via the existing admin_notifications bell.
  Future<void> createTicket({
    required String question,
    String bookingId = '',
    String bookingSummary = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final docRef = _collection.doc();
    final message = SupportMessage(
      senderId: user.uid,
      senderName: user.displayName ?? user.email ?? 'User',
      isFromAdmin: false,
      text: question.trim(),
    );

    final ticket = SupportTicket(
      id: docRef.id,
      userId: user.uid,
      userName: user.displayName ?? user.email ?? 'User',
      userEmail: user.email ?? '',
      bookingId: bookingId,
      bookingSummary: bookingSummary,
      messages: [message],
    );

    await docRef.set(ticket.toMap());

    // Notify admin - lands directly in the existing admin notification
    // bell/screen, no changes needed on that side.
    await _database.ref('admin_notifications').push().set({
      'title': 'New Support Question',
      'message':
          '${ticket.userName}: ${question.length > 80 ? '${question.substring(0, 80)}...' : question}',
      'type': 'support_ticket',
      'isRead': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Adds a user follow-up message to an existing ticket and re-notifies
  /// the admin.
  Future<void> addUserFollowUp({
    required String ticketId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final message = SupportMessage(
      senderId: user.uid,
      senderName: user.displayName ?? user.email ?? 'User',
      isFromAdmin: false,
      text: text.trim(),
    );

    await _collection.doc(ticketId).update({
      'messages': FieldValue.arrayUnion([message.toMap()]),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    await _database.ref('admin_notifications').push().set({
      'title': 'New Reply on Support Ticket',
      'message':
          '${message.senderName}: ${text.length > 80 ? '${text.substring(0, 80)}...' : text}',
      'type': 'support_ticket',
      'isRead': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Streams the current user's own tickets, most recently updated first.
  Stream<List<SupportTicket>> streamMyTickets() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _collection
        .where('userId', isEqualTo: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicket.fromMap(doc.data()))
            .toList());
  }

  /// Fetches a single ticket by id - used to jump straight into a ticket's
  /// thread when the user taps a "Support Team Replied" notification in
  /// the main notification bell list. Returns null if the ticket no longer
  /// exists (e.g. deleted).
  Future<SupportTicket?> getTicketById(String ticketId) async {
    final doc = await _collection.doc(ticketId).get();
    if (!doc.exists || doc.data() == null) return null;
    return SupportTicket.fromMap(doc.data()!);
  }

  // ── Admin side ────────────────────────────────────────────────────────

  /// Streams every ticket in the system, most recently updated first - the
  /// admin's Support Inbox.
  Stream<List<SupportTicket>> streamAllTickets() {
    return _collection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicket.fromMap(doc.data()))
            .toList());
  }

  /// Admin reply to a ticket - appends the message and notifies the user
  /// via their existing notification bell.
  Future<void> addAdminReply({
    required SupportTicket ticket,
    required String text,
    required String adminName,
  }) async {
    final message = SupportMessage(
      senderId: 'admin',
      senderName: adminName,
      isFromAdmin: true,
      text: text.trim(),
    );

    await _collection.doc(ticket.id).update({
      'messages': FieldValue.arrayUnion([message.toMap()]),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    await _database.ref('user_notifications/${ticket.userId}').push().set({
      'title': 'Support Team Replied',
      'message':
          text.length > 100 ? '${text.substring(0, 100)}...' : text,
      'category': 'info',
      'isBroadcast': false,
      'isSupportReply': true,
      'ticketId': ticket.id,
      'isRead': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
