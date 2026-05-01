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

  BookingProvider() {
    _listenToBookings();
  }

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;

  List<BookingModel> get pendingBookings =>
      _bookings.where((b) => b.status == 'pending').toList();

  List<BookingModel> get approvedBookings =>
      _bookings.where((b) => b.status == 'approved').toList();

  List<BookingModel> get rejectedBookings =>
      _bookings.where((b) => b.status == 'rejected').toList();

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

  /// 🔥 APPROVE BOOKING (CRITICAL FIXES INCLUDED)
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

      /// ❌ prevent double approval
      if (booking.status == 'approved') {
        throw Exception('Already approved');
      }

      /// 🔥 1. Update Firestore
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'approved',
        'updatedAt': now,
      });

      /// 🔥 2. Save booked seat permanently
      await _realtimeDb
          .ref(
            'seat_data/${booking.busId}/$dateKey/booked/${booking.seatNumber}',
          )
          .set({"bookedBy": booking.userId, "bookedAt": now});

      /// 🔥 3. Remove lock if exists
      await _realtimeDb
          .ref(
            'seat_data/${booking.busId}/$dateKey/locks/${booking.seatNumber}',
          )
          .remove();

      /// 🔥 4. Booking status realtime
      await _realtimeDb.ref('booking_status/$bookingId').set({
        'status': 'approved',
        'updatedAt': now,
      });

      /// 🔥 5. Update booking_requests mirror
      await _realtimeDb.ref('booking_requests/$bookingId').update({
        'status': 'approved',
        'updatedAt': now,
      });

      /// 🔥 6. Notification
      await _realtimeDb.ref('notifications/${booking.userId}').push().set({
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

  /// 🔥 REJECT BOOKING (CRITICAL FIXES INCLUDED)
  Future<void> rejectBooking(String bookingId) async {
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

      /// ❌ prevent double reject
      if (booking.status == 'rejected') {
        throw Exception('Already rejected');
      }

      /// 🔥 1. Update Firestore
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'rejected',
        'updatedAt': now,
      });

      /// 🔥 2. Release locked/booked seat (IMPORTANT)
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

      /// 🔥 3. Booking status realtime
      await _realtimeDb.ref('booking_status/$bookingId').set({
        'status': 'rejected',
        'updatedAt': now,
      });

      /// 🔥 4. Update booking_requests mirror
      await _realtimeDb.ref('booking_requests/$bookingId').update({
        'status': 'rejected',
        'updatedAt': now,
      });

      /// 🔥 5. Notification
      await _realtimeDb.ref('notifications/${booking.userId}').push().set({
        'title': 'Booking Rejected',
        'message':
            'Seat ${booking.seatNumber} for ${booking.busFrom} → ${booking.busTo} was rejected',
        'type': 'booking',
        'isRead': false,
        'createdAt': now,
      });
    } catch (e) {
      debugPrint('❌ Reject error: $e');
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
