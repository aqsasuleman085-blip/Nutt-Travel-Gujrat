import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/broadcast_model.dart';

/// Lightweight record used by the "Specific Users" picker screen -
/// deliberately separate from any existing user model so this feature
/// doesn't depend on (or risk breaking) other parts of the app.
class SelectableUser {
  final String uid;
  final String name;
  final String email;

  SelectableUser({required this.uid, required this.name, required this.email});
}

/// Drives the admin "Broadcast Notification" section:
///  - resolves WHO should receive a broadcast for each audience type
///  - fans the notification out to every recipient's existing
///    `user_notifications/{uid}` Realtime Database path (same path the app
///    already uses for booking alerts, so it lands in the same bell/screen)
///  - writes one audit-trail document per broadcast into the `broadcasts`
///    Firestore collection for the "Sent Broadcasts" history screen
class BroadcastProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  bool isSending = false;
  bool isLoadingHistory = false;
  bool isLoadingUsers = false;
  String? errorMessage;

  List<BroadcastModel> history = [];
  List<SelectableUser> allUsers = [];

  // ── Send history (audit trail) ──────────────────────────────────────

  Future<void> loadHistory() async {
    isLoadingHistory = true;
    errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('broadcasts')
          .orderBy('createdAt', descending: true)
          .get();

      history = snapshot.docs
          .map((doc) => BroadcastModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      errorMessage = 'Failed to load broadcast history: $e';
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  // ── User picker (for "Specific Users" audience) ─────────────────────

  Future<void> loadAllUsers() async {
    isLoadingUsers = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('users').get();
      allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return SelectableUser(
          uid: doc.id,
          name: data['name'] ?? data['fullName'] ?? 'Unknown',
          email: data['email'] ?? '',
        );
      }).toList();
    } catch (e) {
      errorMessage = 'Failed to load users: $e';
    } finally {
      isLoadingUsers = false;
      notifyListeners();
    }
  }

  // ── Audience resolution ──────────────────────────────────────────────

  /// All users who have ever logged in / registered - used for the
  /// "All Users" audience (e.g. general discount announcements).
  Future<List<String>> _resolveAllUserIds() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((d) => d.id).toList();
  }

  /// Users with an APPROVED booking matching the given from/to route AND
  /// travel date - used for route-level disruption notices (e.g. road
  /// blockage, weather, or cancellation affecting one specific day's
  /// departure). Only 'approved' bookings count, since those are the
  /// passengers actually confirmed to travel. Date is required so the
  /// admin always targets one specific day's travellers, not the whole
  /// route indefinitely.
  Future<List<String>> _resolveRouteUserIds(
    String from,
    String to,
    String date,
  ) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'approved')
        .where('busFrom', isEqualTo: from)
        .where('busTo', isEqualTo: to)
        .where('travelDate', isEqualTo: date)
        .get();

    final ids = <String>{};
    for (final doc in snapshot.docs) {
      final uid = doc.data()['userId'] as String?;
      if (uid != null && uid.isNotEmpty) ids.add(uid);
    }
    return ids.toList();
  }

  // ── Sending ───────────────────────────────────────────────────────────

  /// Sends a broadcast to the resolved audience and records it in history.
  /// Returns the number of users actually notified, or throws on failure.
  Future<int> sendBroadcast({
    required String title,
    required String message,
    required String category,
    required String audienceType,
    String routeFrom = '',
    String routeTo = '',
    String routeDate = '',
    List<SelectableUser> selectedUsers = const [],
    String sentByName = 'Admin',
  }) async {
    isSending = true;
    errorMessage = null;
    notifyListeners();

    try {
      List<String> recipientIds;
      String audienceLabel;

      switch (audienceType) {
        case kBroadcastAudienceRoute:
          recipientIds =
              await _resolveRouteUserIds(routeFrom, routeTo, routeDate);
          audienceLabel = '$routeFrom → $routeTo on $routeDate (approved bookings)';
          break;

        case kBroadcastAudienceUsers:
          recipientIds = selectedUsers.map((u) => u.uid).toList();
          audienceLabel = '${selectedUsers.length} selected user(s)';
          break;

        case kBroadcastAudienceAll:
        default:
          recipientIds = await _resolveAllUserIds();
          audienceLabel = 'All registered users';
          break;
      }

      if (recipientIds.isEmpty) {
        throw Exception(
          'No matching users found for this audience - nothing was sent.',
        );
      }

      // Fan out to each recipient's existing notification inbox path.
      // Using a multi-path update keeps this as a single atomic write
      // instead of N sequential round trips.
      final Map<String, dynamic> updates = {};
      final nowMillis = DateTime.now().millisecondsSinceEpoch;

      for (final uid in recipientIds) {
        final pushKey = _database.ref('user_notifications/$uid').push().key;
        updates['user_notifications/$uid/$pushKey'] = {
          'title': title,
          'message': message,
          'category': category,
          'isBroadcast': true,
          'isRead': false,
          'createdAt': nowMillis,
        };
      }
      await _database.ref().update(updates);

      // Record the send in the audit-trail collection.
      final docRef = _firestore.collection('broadcasts').doc();
      final broadcast = BroadcastModel(
        id: docRef.id,
        title: title,
        message: message,
        category: category,
        audienceType: audienceType,
        audienceLabel: audienceLabel,
        routeFrom: routeFrom,
        routeTo: routeTo,
        routeDate: routeDate,
        recipientIds: recipientIds,
        recipientCount: recipientIds.length,
        sentByName: sentByName,
        createdAt: DateTime.now(),
      );
      await docRef.set(broadcast.toMap());

      history.insert(0, broadcast);
      return recipientIds.length;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
