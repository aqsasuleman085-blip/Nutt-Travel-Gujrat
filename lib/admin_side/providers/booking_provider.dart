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

      final dateKey = _dateKey(
        booking.travelDate.isNotEmpty
            ? booking.travelDate
            : booking.bookingDate.toIso8601String(),
      );

      if (booking.status == 'approved') {
        throw Exception('Already approved');
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'approved',
        'updatedAt': now,
      });

      await _realtimeDb
          .ref(
            'seat_data/${booking.busId}/$dateKey/booked/${booking.seatNumber}',
          )
          .set({"bookedBy": booking.userId, "bookedAt": now});

      await _realtimeDb
          .ref(
            'seat_data/${booking.busId}/$dateKey/locks/${booking.seatNumber}',
          )
          .remove();

      // Clear the "pending approval" marker now that the seat is booked.
      await _realtimeDb
          .ref(
            'seat_data/${booking.busId}/$dateKey/pending/${booking.seatNumber}',
          )
          .remove();

      await _realtimeDb.ref('booking_status/$bookingId').set({
        'status': 'approved',
        'updatedAt': now,
      });

      await _realtimeDb.ref('booking_requests/$bookingId').update({
        'status': 'approved',
        'updatedAt': now,
      });

      await _realtimeDb.ref('user_notifications/${booking.userId}').push().set({
        'title': 'Booking Approved',
        'message':
            'Seat ${booking.seatNumber} for ${booking.busFrom} → ${booking.busTo} confirmed',
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

      final dateKey = _dateKey(
        booking.travelDate.isNotEmpty
            ? booking.travelDate
            : booking.bookingDate.toIso8601String(),
      );

      if (booking.status == 'rejected') {
        throw Exception('Already rejected');
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'rejected',
        'updatedAt': now,
        'rejectedAt': now,
        'refundAmount': refundAmount,
        'refundAccountName': refundAccountName,
        'refundAccountNumber': refundAccountNumber,
        'rejectionReason': rejectionReason,
      });

      await _realtimeDb
          .ref(
            'seat_data/${booking.busId}/$dateKey/locks/${booking.seatNumber}',
          )
          .remove();

      await _realtimeDb
          .ref(
            'seat_data/${booking.busId}/$dateKey/booked/${booking.seatNumber}',
          )
          .remove();

      // Clear the "pending approval" marker so the seat becomes available
      // again for other users.
      await _realtimeDb
          .ref(
            'seat_data/${booking.busId}/$dateKey/pending/${booking.seatNumber}',
          )
          .remove();

      await _realtimeDb.ref('booking_status/$bookingId').set({
        'status': 'rejected',
        'updatedAt': now,
        'refundAmount': refundAmount,
        'refundAccountName': refundAccountName,
        'refundAccountNumber': refundAccountNumber,
        'rejectionReason': rejectionReason,
      });

      await _realtimeDb.ref('booking_requests/$bookingId').update({
        'status': 'rejected',
        'updatedAt': now,
        'refundAmount': refundAmount,
        'refundAccountName': refundAccountName,
        'rejectionReason': rejectionReason,
      });

      await _realtimeDb.ref('user_notifications/${booking.userId}').push().set({
        'title': 'Booking Rejected',
        'message':
            'Your ticket for seat ${booking.seatNumber} from ${booking.busFrom} → ${booking.busTo} was rejected.\nRefund: Rs $refundAmount\nAccount: $refundAccountName\nReason: $rejectionReason',
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

      final dateKey = _dateKey(
        booking.travelDate.isNotEmpty
            ? booking.travelDate
            : booking.bookingDate.toIso8601String(),
      );

      // Update refund request status
      final refundQuery = await _firestore
          .collection('refund_requests')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (refundQuery.docs.isNotEmpty) {
        final refundDoc = refundQuery.docs.first;
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
      }

      // Update booking status to refunded
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'refunded',
        'refundStatus': 'refunded',
        'refundApprovedAt': now,
        'refundAmount': refundAmount,
        'refundAccountName': refundAccountName,
        'refundAccountNumber': refundAccountNumber,
        'refundReason': refundReason,
        'updatedAt': now,
      });

      // Sync to Realtime Database
      await _realtimeDb.ref('booking_status/$bookingId').set({
        'status': 'refunded',
        'refundStatus': 'refunded',
        'refundApprovedAt': now,
        'refundAmount': refundAmount,
        'refundAccountName': refundAccountName,
        'refundReason': refundReason,
        'updatedAt': now,
      });

      // ✅ Free the seat now that the refund is complete - previously this
      // was never done, so a refunded booking's seat stayed permanently
      // marked as booked (grey) in the seat map even though nobody could
      // actually use that ticket anymore.
      await _realtimeDb
          .ref(
            'seat_data/${booking.busId}/$dateKey/booked/${booking.seatNumber}',
          )
          .remove();

      // Send notification to user
      await _realtimeDb.ref('user_notifications/${booking.userId}').push().set({
        'title': 'Refund Processed',
        'message':
            'Your refund for seat ${booking.seatNumber} (${booking.busFrom} → ${booking.busTo}) has been processed.\nAmount: Rs $refundAmount\nAccount: $refundAccountName\nReason: ${refundReason.isNotEmpty ? refundReason : 'N/A'}',
        'type': 'refund',
        'isRead': false,
        'createdAt': now,
      });

      // Send admin notification for completion
      await _realtimeDb.ref('admin_notifications').push().set({
        'title': 'Refund Completed',
        'message':
            'Refund processed for ${booking.userName} - Seat ${booking.seatNumber}',
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
