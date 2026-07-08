import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/bus_model.dart';
import '../../services/notification_service.dart';

class BusProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<BusModel> _buses = [];
  bool _isLoading = false;

  BusProvider() {
    _listenToBuses();
  }

  // Getters
  List<BusModel> get buses => _buses;
  bool get isLoading => _isLoading;

  void _listenToBuses() {
    _isLoading = true;
    notifyListeners();

    _subscription = _firestore
        .collection('buses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _buses = snapshot.docs.map((doc) {
              final data = doc.data();
              return BusModel.fromMap({'id': doc.id, ...data});
            }).toList();
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error loading buses: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Add a new bus
  Future<void> addBus({
    required String from,
    required String to,
    required DateTime departureAt,
    required double ticketPrice,
    required String driverName,
    required String numberPlate,
    required int totalSeats,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('buses').add({
        'from': from,
        'to': to,
        'departureAt': departureAt,
        'ticketPrice': ticketPrice,
        'driverName': driverName,
        'numberPlate': numberPlate,
        'totalSeats': totalSeats,
        'status': 'Active',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('Bus created: ${doc.id}');
    } catch (e) {
      debugPrint('Error adding bus: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a bus
  Future<void> deleteBus(String busId) async {
    try {
      await _firestore.collection('buses').doc(busId).delete();
    } catch (e) {
      debugPrint('Error deleting bus: $e');
    }
  }

  /// ✅ UPDATE an existing bus's details, then notify every user with an
  /// 'approved' booking on this bus that their trip details changed.
  ///
  /// Compares old vs new values to build a human-readable summary of what
  /// changed (e.g. "Departure time changed to ...", "Ticket price changed
  /// to Rs. ..."), then sends one notification per affected user via
  /// [AdminNotificationService], reusing the exact same
  /// `user_notifications/$uid` path the rest of the app already uses for
  /// booking-approval/refund notifications.
  Future<void> updateBus({
    required String busId,
    required String from,
    required String to,
    required DateTime departureAt,
    required double ticketPrice,
    required String driverName,
    required String numberPlate,
    required int totalSeats,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch the current bus data first, so we can tell what actually
      // changed and word the notification appropriately.
      final beforeSnap = await _firestore.collection('buses').doc(busId).get();
      final before = beforeSnap.data();
      final oldBus = before != null
          ? BusModel.fromMap({'id': busId, ...before})
          : null;

      await _firestore.collection('buses').doc(busId).update({
        'from': from,
        'to': to,
        'departureAt': departureAt,
        'ticketPrice': ticketPrice,
        'driverName': driverName,
        'numberPlate': numberPlate,
        'totalSeats': totalSeats,
      });

      if (oldBus != null) {
        await _notifyAffectedUsers(
          busId: busId,
          oldBus: oldBus,
          newFrom: from,
          newTo: to,
          newDepartureAt: departureAt,
          newTicketPrice: ticketPrice,
          newDriverName: driverName,
          newNumberPlate: numberPlate,
        );
      }

      debugPrint('Bus updated: $busId');
    } catch (e) {
      debugPrint('Error updating bus: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Builds a change summary and sends a notification to every user with
  /// an 'approved' booking on this bus.
  Future<void> _notifyAffectedUsers({
    required String busId,
    required BusModel oldBus,
    required String newFrom,
    required String newTo,
    required DateTime newDepartureAt,
    required double newTicketPrice,
    required String newDriverName,
    required String newNumberPlate,
  }) async {
    final changes = <String>[];

    if (oldBus.from != newFrom || oldBus.to != newTo) {
      changes.add('Route changed to $newFrom → $newTo');
    }
    if (!_isSameDateTime(oldBus.departureAt, newDepartureAt)) {
      final d = newDepartureAt;
      final formatted =
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
      changes.add('Departure time changed to $formatted');
    }
    if (oldBus.ticketPrice != newTicketPrice) {
      changes.add('Ticket price changed to Rs. ${newTicketPrice.toStringAsFixed(0)}');
    }
    if (oldBus.driverName != newDriverName) {
      changes.add('Driver changed to $newDriverName');
    }
    if (oldBus.numberPlate != newNumberPlate) {
      changes.add('Bus number plate changed to $newNumberPlate');
    }

    // Nothing actually changed - no need to notify anyone.
    if (changes.isEmpty) return;

    try {
      final bookingsSnap = await _firestore
          .collection('bookings')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'approved')
          .get();

      if (bookingsSnap.docs.isEmpty) return;

      final notificationService = AdminNotificationService();
      final message = 'Your booking for $newFrom → $newTo has been '
          'updated by the admin: ${changes.join('; ')}.';

      // Send one notification per affected user (a user could have more
      // than one approved booking on the same bus, but we only need to
      // notify them once, so de-duplicate by userId first).
      final notifiedUserIds = <String>{};
      for (final doc in bookingsSnap.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId == null || userId.isEmpty) continue;
        if (notifiedUserIds.contains(userId)) continue;
        notifiedUserIds.add(userId);

        await notificationService.sendNotification(
          uid: userId,
          title: 'Bus Details Updated',
          message: message,
        );
      }
    } catch (e) {
      debugPrint('Error notifying affected users: $e');
      // Don't rethrow - the bus update itself already succeeded, and a
      // notification failure shouldn't be reported to the admin as an
      // update failure.
    }
  }

  bool _isSameDateTime(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  // Get active buses count (buses whose departure hasn't passed yet)
  int get activeBusesCount {
    return _buses.where((bus) => bus.status == 'Active').length;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
