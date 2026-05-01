import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../admin_side/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔥 STREAM USER BOOKINGS (CLEAN + CONSISTENT)
  Stream<List<BookingModel>> streamUserBookings() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap({'id': doc.id, ...doc.data()});
          }).toList();
        });
  }

  /// 🔥 CREATE BOOKING (FIXED STRUCTURE + NO DUPLICATION + REALTIME LOCK)
  Future<String?> createBooking({
    required String name,
    required String phone,
    required String cnic,
    required String gender,
    required String busId,
    required String from,
    required String to,
    required String seat,
    required String date,
    required String time,
    required double totalAmount,
    required String paymentMethod,
    required String senderName,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final lockExpiresAt = now + const Duration(hours: 24).inMilliseconds;
    final dateKey = _dateKey(date);

    try {
      /// ❌ STEP 1: CHECK IF SEAT ALREADY BOOKED
      final bookedSnap = await _realtimeDb
          .ref('seat_data/$busId/$dateKey/booked/$seat')
          .get();

      if (bookedSnap.exists) {
        throw Exception('Seat already booked');
      }

      /// ❌ STEP 2: CHECK IF SEAT LOCKED BY SOMEONE ELSE
      final lockSnap = await _realtimeDb
          .ref('seat_data/$busId/$dateKey/locks/$seat')
          .get();

      if (lockSnap.exists && lockSnap.child('lockedBy').value != user.uid) {
        throw Exception('Seat temporarily locked by another user');
      }

      /// 🔥 STEP 3: LOCK SEAT
      await _realtimeDb.ref('seat_data/$busId/$dateKey/locks/$seat').set({
        'lockedBy': user.uid,
        'lockedAt': now,
        'expiresAt': lockExpiresAt,
      });

      /// 🔥 STEP 4: CREATE BOOKING (FIXED FIELD NAMES FOR ADMIN)
      final docRef = _firestore.collection('bookings').doc();

      await docRef.set({
        'bookingId': docRef.id,
        'userId': user.uid,
        'userName': name,
        'userEmail': user.email ?? '',

        /// 👤 Passenger
        'name': name,
        'phone': phone,
        'cnic': cnic,
        'gender': gender,

        /// 🚌 Trip
        'busId': busId,
        'busFrom': from,
        'busTo': to,
        'from': from,
        'to': to,
        'seatNumber': seat,
        'seat': seat,
        'travelDate': date,
        'bookingDate': date,
        'time': time,

        /// 💰 Payment
        'paymentMethod': paymentMethod,
        'senderName': senderName,
        'paidAmount': totalAmount,
        'totalAmount': totalAmount,
        'price': totalAmount,

        /// 📊 Status
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
      });

      /// 🔥 STEP 4B: MIRROR IN REALTIME DATABASE
      await _realtimeDb.ref('booking_requests/${docRef.id}').set({
        'bookingId': docRef.id,
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'passengerName': name,
        'contactNumber': phone,
        'cnic': cnic,
        'gender': gender,
        'busId': busId,
        'from': from,
        'to': to,
        'seatNumber': seat,
        'travelDate': date,
        'time': time,
        'paymentMethod': paymentMethod,
        'paymentSenderName': senderName,
        'paidAmount': totalAmount,
        'totalAmount': totalAmount,
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
      });

      /// 🔥 STEP 5: REALTIME STATUS
      await _realtimeDb.ref('booking_status/${docRef.id}').set({
        'status': 'pending',
        'updatedAt': now,
      });

      /// 🔥 STEP 6: ADMIN NOTIFICATION
      await _realtimeDb.ref('admin_notifications').push().set({
        'title': 'New Booking Request',
        'message': '$name booked seat $seat ($from → $to)',
        'type': 'booking',
        'isRead': false,
        'createdAt': now,
      });

      return docRef.id;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  String _dateKey(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date.replaceAll('/', '-');
    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }
}
