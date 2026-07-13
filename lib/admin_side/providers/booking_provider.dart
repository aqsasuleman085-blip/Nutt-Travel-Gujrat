import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<BookingModel> _bookings = [];
  bool _isLoading = false;

  // Add this getter to your BookingProvider class
  List<BookingModel> get refundedBookings =>
      _bookings.where((b) => b.status == 'refunded').toList();

  BookingProvider() {
    _listenToBookings();
  }

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;

  List<BookingModel> get pendingBookings =>
      _bookings.where((b) => b.status == 'pending').toList();

  List<BookingModel> get approvedBookings =>
      _bookings.where((b) => b.status == 'approved').toList();

  List<BookingModel> get refundPendingBookings =>
      _bookings.where((b) => b.status == 'refund_pending').toList();

  List<BookingModel> get rejectedBookings =>
      _bookings.where((b) => b.status == 'rejected').toList();

  /// Bookings that are safe to clean up: their travel date has passed AND
  /// they're either 'approved' (trip already happened) or
  /// 'rejected'/'refunded' (never actually used the seat). 'pending' and
  /// 'refund_pending' bookings are deliberately excluded even if their
  /// date has passed, since those still need an admin decision first.
  List<BookingModel> get expiredBookings {
    final now = DateTime.now();
    return _bookings.where((b) {
      final eligibleStatus = b.status == 'approved' ||
          b.status == 'rejected' ||
          b.status == 'refunded';
      if (!eligibleStatus) return false;

      final travelDate = _parseTravelDate(b.travelDate) ?? b.bookingDate;
      return travelDate.isBefore(now);
    }).toList();
  }

  DateTime? _parseTravelDate(String date) {
    if (date.isEmpty) return null;
    return DateTime.tryParse(date);
  }

  void _listenToBookings() {
    _isLoading = true;
    notifyListeners();

    _subscription = _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _bookings = snapshot.docs.map((doc) {
              return BookingModel.fromMap({'id': doc.id, ...doc.data()});
            }).toList();

            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('🔥 Firestore error: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// APPROVE BOOKING
  Future<void> approveBooking(String bookingId) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (!doc.exists) {
        throw Exception('Booking not found');
      }

      final booking = BookingModel.fromMap({'id': doc.id, ...doc.data()!});

      if (booking.status == 'approved') {
        throw Exception('Already approved');
      }

      // Find every "extra seats" booking linked to this one, so approving
      // the root also approves the whole reservation in one action -
      // otherwise addons would be stuck at 'pending' forever and the
      // admin UI would show the reservation as split across two tabs.
      final addonsSnapshot = await _firestore
          .collection('bookings')
          .where('linkedBookingId', isEqualTo: bookingId)
          .get();
      final addons = addonsSnapshot.docs
          .map((d) => BookingModel.fromMap({'id': d.id, ...d.data()}))
          .toList();

      final allBookings = [booking, ...addons];

      // Update Firestore for the root + every addon in one atomic batch.
      final batch = _firestore.batch();
      for (final b in allBookings) {
        batch.update(_firestore.collection('bookings').doc(b.id), {
          'status': 'approved',
          'updatedAt': now,
        });
      }
      await batch.commit();

      // Update Realtime Database seat maps / status mirrors for each one.
      for (final b in allBookings) {
        final dateKey = _dateKey(
          b.travelDate.isNotEmpty
              ? b.travelDate
              : b.bookingDate.toIso8601String(),
        );

        for (final seat in b.seatNumber.split(',')) {
          final trimmedSeat = seat.trim();
          await _realtimeDb
              .ref('seat_data/${b.busId}/$dateKey/booked/$trimmedSeat')
              .set({"bookedBy": b.userId, "bookedAt": now});

          await _realtimeDb
              .ref('seat_data/${b.busId}/$dateKey/locks/$trimmedSeat')
              .remove();

          // Clear the "pending approval" marker now that the seat is booked.
          await _realtimeDb
              .ref('seat_data/${b.busId}/$dateKey/pending/$trimmedSeat')
              .remove();
        }

        await _realtimeDb.ref('booking_status/${b.id}').set({
          'status': 'approved',
          'updatedAt': now,
        });

        await _realtimeDb.ref('booking_requests/${b.id}').update({
          'status': 'approved',
          'updatedAt': now,
        });
      }

      // One combined notification to the user, mentioning every seat
      // across the root + all addons, instead of a separate notification
      // per booking document.
      final allSeats = allBookings
          .expand((b) => b.seatNumber.split(','))
          .map((s) => s.trim())
          .join(', ');

      await _realtimeDb.ref('user_notifications/${booking.userId}').push().set({
        'title': 'Booking Approved',
        'message':
            'Seat(s) $allSeats for ${booking.busFrom} → ${booking.busTo} confirmed',
        'type': 'booking',
        'isRead': false,
        'createdAt': now,
      });
    } catch (e) {
      debugPrint('❌ Approve error: $e');
      rethrow;
    }
  }

  /// REJECT BOOKING
  Future<void> rejectBooking({
    required String bookingId,
    required String refundAmount,
    required String refundAccountName,
    required String refundAccountNumber,
    required String rejectionReason,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (!doc.exists) {
        throw Exception('Booking not found');
      }

      final booking = BookingModel.fromMap({'id': doc.id, ...doc.data()!});

      if (booking.status == 'rejected') {
        throw Exception('Already rejected');
      }

      // Find every "extra seats" booking linked to this one, so rejecting
      // the root also rejects the whole reservation - otherwise addons
      // would be stuck at 'pending' forever, and the seats they hold
      // would never be freed.
      final addonsSnapshot = await _firestore
          .collection('bookings')
          .where('linkedBookingId', isEqualTo: bookingId)
          .get();
      final addons = addonsSnapshot.docs
          .map((d) => BookingModel.fromMap({'id': d.id, ...d.data()}))
          .toList();

      final allBookings = [booking, ...addons];

      // Update Firestore for the root + every addon in one atomic batch.
      // The same combined refund amount/account is recorded on every
      // booking in the reservation, per how refunds are tracked here.
      final batch = _firestore.batch();
      for (final b in allBookings) {
        batch.update(_firestore.collection('bookings').doc(b.id), {
          'status': 'rejected',
          'updatedAt': now,
          'rejectedAt': now,
          'refundAmount': refundAmount,
          'refundAccountName': refundAccountName,
          'refundAccountNumber': refundAccountNumber,
          'rejectionReason': rejectionReason,
        });
      }
      await batch.commit();

      for (final b in allBookings) {
        final dateKey = _dateKey(
          b.travelDate.isNotEmpty
              ? b.travelDate
              : b.bookingDate.toIso8601String(),
        );

        for (final seat in b.seatNumber.split(',')) {
          final trimmedSeat = seat.trim();
          await _realtimeDb
              .ref('seat_data/${b.busId}/$dateKey/locks/$trimmedSeat')
              .remove();

          await _realtimeDb
              .ref('seat_data/${b.busId}/$dateKey/booked/$trimmedSeat')
              .remove();

          // Clear the "pending approval" marker so the seat becomes
          // available again for other users.
          await _realtimeDb
              .ref('seat_data/${b.busId}/$dateKey/pending/$trimmedSeat')
              .remove();
        }

        await _realtimeDb.ref('booking_status/${b.id}').set({
          'status': 'rejected',
          'updatedAt': now,
          'refundAmount': refundAmount,
          'refundAccountName': refundAccountName,
          'refundAccountNumber': refundAccountNumber,
          'rejectionReason': rejectionReason,
        });

        await _realtimeDb.ref('booking_requests/${b.id}').update({
          'status': 'rejected',
          'updatedAt': now,
          'refundAmount': refundAmount,
          'refundAccountName': refundAccountName,
          'rejectionReason': rejectionReason,
        });
      }

      final allSeats = allBookings
          .expand((b) => b.seatNumber.split(','))
          .map((s) => s.trim())
          .join(', ');

      await _realtimeDb.ref('user_notifications/${booking.userId}').push().set({
        'title': 'Booking Rejected',
        'message':
            'Your ticket for seat(s) $allSeats from ${booking.busFrom} → ${booking.busTo} was rejected.\nRefund: Rs $refundAmount\nAccount: $refundAccountName ($refundAccountNumber)\nReason: $rejectionReason',
        'type': 'booking',
        'isRead': false,
        'createdAt': now,
      });
    } catch (e) {
      debugPrint('❌ Reject error: $e');
      rethrow;
    }
  }

  /// PROCESS REFUND (UPDATED with reason field)
  Future<void> processRefund({
    required String bookingId,
    required String refundAmount,
    required String refundAccountName,
    required String refundAccountNumber,
    required String refundReason,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (!doc.exists) {
        throw Exception('Booking not found');
      }

      final booking = BookingModel.fromMap({'id': doc.id, ...doc.data()!});

      if (booking.status != 'refund_pending') {
        throw Exception('Booking is not in refund pending state');
      }

      // Update refund request status, and read back linkedBookingIds so
      // every addon covered by this same refund request also gets marked
      // refunded - the request was submitted once for the whole
      // reservation (see BookingService.processRefund on the user side).
      final refundQuery = await _firestore
          .collection('refund_requests')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      List<String> addonIds = [];

      if (refundQuery.docs.isNotEmpty) {
        final refundDoc = refundQuery.docs.first;
        addonIds = List<String>.from(
          refundDoc.data()['linkedBookingIds'] ?? [],
        );

        await _firestore
            .collection('refund_requests')
            .doc(refundDoc.id)
            .update({
              'status': 'refunded',
              'approvedAt': now,
              'refundAmount': refundAmount,
              'refundAccountName': refundAccountName,
              'refundAccountNumber': refundAccountNumber,
              'refundReason': refundReason,
              'updatedAt': now,
            });

        await _realtimeDb.ref('refund_requests/${refundDoc.id}').update({
          'status': 'refunded',
          'approvedAt': now,
          'refundAmount': refundAmount,
          'refundAccountName': refundAccountName,
          'refundAccountNumber': refundAccountNumber,
          'refundReason': refundReason,
          'updatedAt': now,
        });
      } else {
        // Fallback: no refund_requests doc found with linkedBookingIds
        // (e.g. an older refund created before this field existed) - fall
        // back to looking up addons directly via linkedBookingId, same as
        // approve/reject already do, so this booking's addons still get
        // refunded together with it.
        final addonsSnapshot = await _firestore
            .collection('bookings')
            .where('linkedBookingId', isEqualTo: bookingId)
            .get();
        addonIds = addonsSnapshot.docs.map((d) => d.id).toList();
      }

      final allBookingIds = [bookingId, ...addonIds];

      // Fetch full booking models for every id so we know each one's own
      // seat/bus/date for the Realtime Database seat-freeing step below.
      final allBookings = <BookingModel>[booking];
      for (final id in addonIds) {
        final addonDoc = await _firestore.collection('bookings').doc(id).get();
        if (addonDoc.exists) {
          allBookings.add(
            BookingModel.fromMap({'id': addonDoc.id, ...addonDoc.data()!}),
          );
        }
      }

      // Update booking status to refunded for the root + every addon.
      final batch = _firestore.batch();
      for (final id in allBookingIds) {
        batch.update(_firestore.collection('bookings').doc(id), {
          'status': 'refunded',
          'refundStatus': 'refunded',
          'refundApprovedAt': now,
          'refundAmount': refundAmount,
          'refundAccountName': refundAccountName,
          'refundAccountNumber': refundAccountNumber,
          'refundReason': refundReason,
          'updatedAt': now,
        });
      }
      await batch.commit();

      for (final b in allBookings) {
        final dateKey = _dateKey(
          b.travelDate.isNotEmpty
              ? b.travelDate
              : b.bookingDate.toIso8601String(),
        );

        // Sync to Realtime Database
        await _realtimeDb.ref('booking_status/${b.id}').set({
          'status': 'refunded',
          'refundStatus': 'refunded',
          'refundApprovedAt': now,
          'refundAmount': refundAmount,
          'refundAccountName': refundAccountName,
          'refundReason': refundReason,
          'updatedAt': now,
        });

        // ✅ Free the seat(s) now that the refund is complete.
        for (final seat in b.seatNumber.split(',')) {
          await _realtimeDb
              .ref('seat_data/${b.busId}/$dateKey/booked/${seat.trim()}')
              .remove();
        }
      }

      final allSeats = allBookings
          .expand((b) => b.seatNumber.split(','))
          .map((s) => s.trim())
          .join(', ');

      // Send notification to user
      await _realtimeDb.ref('user_notifications/${booking.userId}').push().set({
        'title': 'Refund Processed',
        'message':
            'Your refund for seat(s) $allSeats (${booking.busFrom} → ${booking.busTo}) has been processed.\nAmount: Rs $refundAmount\nAccount: $refundAccountName ($refundAccountNumber)\nReason: ${refundReason.isNotEmpty ? refundReason : 'N/A'}',
        'type': 'refund',
        'isRead': false,
        'createdAt': now,
      });

      // Send admin notification for completion
      await _realtimeDb.ref('admin_notifications').push().set({
        'title': 'Refund Completed',
        'message':
            'Refund processed for ${booking.userName} - Seat(s) $allSeats',
        'type': 'refund_completed',
        'bookingId': bookingId,
        'isRead': false,
        'createdAt': now,
      });
    } catch (e) {
      debugPrint('❌ Refund error: $e');
      rethrow;
    }
  }

  /// ✅ DELETE a single booking record permanently from Firestore.
  ///
  /// Intended for the cleanup workflow (expired bookings whose trip has
  /// already happened or was never used), NOT for cancelling an active
  /// booking - that flow already exists via reject/refund, which correctly
  /// frees the seat and notifies the user first. This delete is a pure
  /// housekeeping operation on records that no longer need to exist.
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      debugPrint('❌ Delete booking error: $e');
      rethrow;
    }
  }

  /// ✅ BULK DELETE multiple bookings at once (used by "Clean Up Expired"),
  /// using a single Firestore batch so it's one atomic operation instead of
  /// N separate network calls.
  Future<void> deleteBookings(List<String> bookingIds) async {
    if (bookingIds.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final id in bookingIds) {
        batch.delete(_firestore.collection('bookings').doc(id));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ Bulk delete error: $e');
      rethrow;
    }
  }

  double get totalEarnings {
    return approvedBookings.fold(0.0, (sum, b) => sum + b.price);
  }

  String _dateKey(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date.replaceAll('/', '-');
    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }

  int get totalBookings => _bookings.length;

  int get uniqueUsersCount {
    return _bookings.map((b) => b.userId).toSet().length;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
