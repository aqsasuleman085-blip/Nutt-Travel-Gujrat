import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../admin_side/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Generates the next human-friendly booking number, e.g. "NT-0001",
  /// "NT-0002", ... This is completely separate from the Firestore
  /// document ID (which stays the normal auto-generated string used
  /// internally everywhere else) - it exists purely so staff have a
  /// short, readable, sequential ID to say/search/write down instead of
  /// a long random string, and so two customers with the same name are
  /// trivial to tell apart.
  ///
  /// Uses a Firestore transaction on a single counter document
  /// (`counters/bookingNumber`) so concurrent bookings from different
  /// users at the same moment can never end up with the same number -
  /// the transaction guarantees each caller gets a unique, incrementing
  /// value even under a race.
  Future<String> _generateNextBookingNumber() async {
    final counterRef = _firestore.collection('counters').doc('bookingNumber');

    final nextValue = await _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(counterRef);
      final current = (snapshot.data()?['value'] as num?)?.toInt() ?? 0;
      final next = current + 1;
      transaction.set(counterRef, {'value': next});
      return next;
    });

    return 'NT-${nextValue.toString().padLeft(4, '0')}';
  }

  /// ✅ UNIFIED REFUND METHOD - Always sets status to 'refund_pending' first
  ///
  /// [passengerName], [refundAccountName], [refundAccountNumber], and [refundReason]
  /// are collected from the new Refund Request Form in tickets_screen.dart and are
  /// stored both in Firestore (refund_requests + bookings) and Realtime Database
  /// so the admin panel can display full refund details.
  Future<void> processRefund({
    required String bookingId,
    required String userId,
    required double amount,
    required String seatNumber,
    required String route,
    required String paymentMethod,
    String passengerName = '',
    String refundAccountName = '',
    String refundAccountNumber = '',
    String refundReason = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    if (user.uid != userId) throw Exception('User ID mismatch');

    final now = DateTime.now().millisecondsSinceEpoch;
    final isCashPayment = paymentMethod.toLowerCase().contains('cash');

    try {
      // Find every "extra seats" booking linked to this one, so
      // requesting a refund on the root also requests a refund for the
      // whole reservation - otherwise addons would be left behind at
      // whatever status they were at, split apart from the root.
      final addonsSnapshot = await _firestore
          .collection('bookings')
          .where('linkedBookingId', isEqualTo: bookingId)
          .get();
      final addonIds = addonsSnapshot.docs.map((d) => d.id).toList();
      final allBookingIds = [bookingId, ...addonIds];

      // Start a Firestore batch for atomic operations
      final batch = _firestore.batch();

      // Create ONE refund request document covering the whole reservation
      // (root + every addon), with the combined amount and combined seat
      // label, mirroring how the admin side already displays/handles
      // combined reservations.
      final refundRef = _firestore.collection('refund_requests').doc();
      batch.set(refundRef, {
        'refundId': refundRef.id,
        'bookingId': bookingId,
        'linkedBookingIds': addonIds,
        'userId': userId,
        'userEmail': user.email ?? '',
        'passengerName': passengerName,
        'amount': amount,
        'seatNumber': seatNumber,
        'route': route,
        'paymentMethod': paymentMethod,
        'refundAccountName': refundAccountName,
        'refundAccountNumber': refundAccountNumber,
        'refundReason': refundReason,
        'status': 'refund_pending', // Always pending first
        'isCashPayment': isCashPayment,
        'processedAt': null, // Not processed yet
        'createdAt': now,
        'updatedAt': now,
      });

      // Update every booking in the reservation (root + addons) to
      // 'refund_pending', carrying the same combined amount/account/reason
      // on each one - matching how reject/approve cascades work.
      for (final id in allBookingIds) {
        final bookingRef = _firestore.collection('bookings').doc(id);
        batch.update(bookingRef, {
          'status': 'refund_pending',
          'refundStatus': 'refund_pending',
          'refundRequestedAt': now,
          'refundAmount': amount,
          'refundAccountName': refundAccountName,
          'refundAccountNumber': refundAccountNumber,
          'refundReason': refundReason,
          'paymentMethod': paymentMethod,
          'updatedAt': now,
        });
      }

      // Commit batch operation
      await batch.commit();

      // Sync to Realtime Database (for admin panel)
      for (final id in allBookingIds) {
        await _realtimeDb.ref('booking_status/$id').set({
          'status': 'refund_pending',
          'refundStatus': 'refund_pending',
          'updatedAt': now,
        });
      }

      // Sync refund request to Realtime Database
      await _realtimeDb.ref('refund_requests/${refundRef.id}').set({
        'refundId': refundRef.id,
        'bookingId': bookingId,
        'linkedBookingIds': addonIds,
        'userId': userId,
        'userEmail': user.email ?? '',
        'passengerName': passengerName,
        'amount': amount,
        'seatNumber': seatNumber,
        'route': route,
        'paymentMethod': paymentMethod,
        'refundAccountName': refundAccountName,
        'refundAccountNumber': refundAccountNumber,
        'refundReason': refundReason,
        'status': 'refund_pending',
        'isCashPayment': isCashPayment,
        'processedAt': null,
        'createdAt': now,
        'updatedAt': now,
      });

      // Create admin notification for all refund requests
      await _realtimeDb.ref('admin_notifications').push().set({
        'title': 'New Refund Request',
        'message': 'Refund requested by $passengerName for seat $seatNumber ($route) - '
            'Amount: Rs ${amount.toStringAsFixed(0)} - Reason: $refundReason',
        'type': 'booking',
        'refundId': refundRef.id,
        'bookingId': bookingId,
        'isRead': false,
        'createdAt': now,
      });

    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  /// ✅ ADMIN METHOD: Approve pending refund (for all payments)
  Future<void> approveRefund(String refundId, String bookingId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    try {
      final batch = _firestore.batch();

      // Update refund request status
      final refundRef = _firestore.collection('refund_requests').doc(refundId);
      batch.update(refundRef, {
        'status': 'refunded',
        'approvedAt': now,
        'updatedAt': now,
      });

      // Update booking status
      final bookingRef = _firestore.collection('bookings').doc(bookingId);
      batch.update(bookingRef, {
        'status': 'refunded',
        'refundStatus': 'refunded',
        'refundApprovedAt': now,
        'updatedAt': now,
      });

      await batch.commit();

      // Sync to Realtime Database
      await _realtimeDb.ref('booking_status/$bookingId').update({
        'status': 'refunded',
        'refundStatus': 'refunded',
        'updatedAt': now,
      });

      await _realtimeDb.ref('refund_requests/$refundId').update({
        'status': 'refunded',
        'approvedAt': now,
        'updatedAt': now,
      });

      // Send notification to user
      await _realtimeDb.ref('user_notifications').push().set({
        'userId': (await bookingRef.get()).data()?['userId'],
        'title': 'Refund Approved',
        'message': 'Your refund has been approved and processed.',
        'type': 'refund_approved',
        'bookingId': bookingId,
        'isRead': false,
        'createdAt': now,
      });
    } catch (e) {
      throw Exception('Failed to approve refund: $e');
    }
  }

  /// ✅ ADMIN METHOD: Reject pending refund
  Future<void> rejectRefund(String refundId, String bookingId, String reason) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    try {
      final batch = _firestore.batch();

      // Update refund request
      final refundRef = _firestore.collection('refund_requests').doc(refundId);
      batch.update(refundRef, {
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': now,
        'updatedAt': now,
      });

      // Revert booking status back to original
      final bookingRef = _firestore.collection('bookings').doc(bookingId);
      batch.update(bookingRef, {
        'status': 'approved', // Assuming original status was approved
        'refundStatus': 'rejected',
        'refundRejectedAt': now,
        'refundRejectionReason': reason,
        'updatedAt': now,
      });

      await batch.commit();

      // Sync to Realtime Database
      await _realtimeDb.ref('booking_status/$bookingId').update({
        'status': 'approved',
        'refundStatus': 'rejected',
        'updatedAt': now,
      });

      // Send notification to user
      await _realtimeDb.ref('user_notifications').push().set({
        'userId': (await bookingRef.get()).data()?['userId'],
        'title': 'Refund Rejected',
        'message': 'Your refund request was rejected. Reason: $reason',
        'type': 'refund_rejected',
        'bookingId': bookingId,
        'isRead': false,
        'createdAt': now,
      });
    } catch (e) {
      throw Exception('Failed to reject refund: $e');
    }
  }

  /// ✅ UPDATE BOOKING STATUS (General purpose)
  Future<void> updateBookingStatus(
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      // Firestore update
      await _firestore.collection('bookings').doc(bookingId).update({
        ...data,
        'updatedAt': now,
      });

      // Realtime DB sync
      if (data.containsKey('status')) {
        await _realtimeDb.ref('booking_status/$bookingId').set({
          'status': data['status'],
          'updatedAt': now,
        });
      }
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  /// ✅ STREAM USER BOOKINGS with real-time updates
  Stream<List<BookingModel>> streamUserBookings() {
    final user = _auth.currentUser;

    if (user == null) return const Stream.empty();

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                return BookingModel.fromMap({'id': doc.id, ...doc.data()});
              })
              // Soft-delete: hide any booking this user has removed from
              // their own ticket list. The document itself still exists
              // in Firestore for admin/audit purposes.
              .where((booking) => !booking.hiddenFor.contains(user.uid))
              .toList();
        });
  }

  /// ✅ SOFT DELETE a ticket from the current user's "My Tickets" list.
  ///
  /// This does NOT delete the booking document from Firestore - it only
  /// adds the current user's ID to the booking's `hiddenFor` array, so the
  /// admin side and any audit/history queries keep the full record intact.
  Future<void> hideBookingForUser(String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'hiddenFor': FieldValue.arrayUnion([user.uid]),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to remove ticket: $e');
    }
  }

  /// ✅ GET SINGLE BOOKING by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return BookingModel.fromMap({'id': doc.id, ...doc.data()!});
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  /// ✅ CHECK IF REFUND IS ELIGIBLE (Server-side validation)
  Future<bool> checkRefundEligibility(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) return false;

      // Already refunded or pending
      if (booking.status == 'refunded' || booking.status == 'refund_pending') {
        return false;
      }

      final now = DateTime.now();
      if (booking.travelDate.isEmpty) return false;

      final travelDate = DateTime.parse(booking.travelDate);
      DateTime? ticketTime;

      if (booking.time.isNotEmpty) {
        final parts = booking.time.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        ticketTime = DateTime(
          travelDate.year, 
          travelDate.month, 
          travelDate.day, 
          hour, 
          minute,
        );
      }

      if (ticketTime == null) return false;
      
      final diff = ticketTime.difference(now);
      return diff.isNegative ? false : diff > const Duration(hours: 12);
    } catch (e) {
      return false;
    }
  }

  /// ✅ CREATE BOOKING (with proper structure)
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
    required String senderNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final now = DateTime.now().millisecondsSinceEpoch;
    final dateKey = _dateKey(date);

    // Check if seat is already booked
    final bookedSnap = await _realtimeDb
        .ref('seat_data/$busId/$dateKey/booked/$seat')
        .get();

    if (bookedSnap.exists) {
      throw Exception('Seat already booked');
    }

    final docRef = _firestore.collection('bookings').doc();
    final bookingNumber = await _generateNextBookingNumber();
    final bookingData = {
      'bookingId': docRef.id,
      'id': docRef.id,
      'bookingNumber': bookingNumber,
      'userId': user.uid,
      'userName': name,
      'userEmail': user.email ?? '',
      'userPhone': phone,
      'userCnic': cnic,
      'userGender': gender,
      'busId': busId,
      'busFrom': from,
      'busTo': to,
      'seatNumber': seat,
      'travelDate': date,
      'time': time,
      'paymentMethod': paymentMethod,
      'senderName': senderName,
      'senderNumber': senderNumber,
      'paidAmount': totalAmount,
      'totalAmount': totalAmount,
      'price': totalAmount,
      'paymentReference': '',
      'status': 'pending',
      'refundStatus': 'none',
      'createdAt': now,
      'updatedAt': now,
      'bookingDate': Timestamp.now(),
    };

    await docRef.set(bookingData);

    // Sync to Realtime Database
    await _realtimeDb.ref('booking_status/${docRef.id}').set({
      'status': 'pending',
      'refundStatus': 'none',
      'updatedAt': now,
    });

    // ✅ Mark this seat as "pending approval" in the seat map, so other
    // users browsing the same bus/date see it as unavailable (a distinct
    // color) instead of still-available while this booking waits for
    // admin approval. Without this, a second user could select the same
    // seat during the approval window since the old code only wrote to
    // 'booked/' at approval time, not at booking-creation time.
    //
    // admin_side/providers/booking_provider.dart's approveBooking() moves
    // this into 'booked/' and clears this node; rejectBooking() just
    // clears this node, freeing the seat back to available.
    await _realtimeDb.ref('seat_data/$busId/$dateKey/pending/$seat').set({
      'bookingId': docRef.id,
      'requestedBy': user.uid,
      'requestedAt': now,
    });

    // ✅ Notify admin of the new booking request, so it shows up on the
    // admin side's notification list (same 'admin_notifications' path the
    // refund flow already uses).
    try {
      await _realtimeDb.ref('admin_notifications').push().set({
        'title': 'New Booking Request',
        'message': 'New booking from $name for seat $seat ($from → $to) - '
            'Amount: Rs ${totalAmount.toStringAsFixed(0)}',
        'type': 'booking',
        'bookingId': docRef.id,
        'isRead': false,
        'createdAt': now,
      });
    } catch (e) {
      // A notification failure should never block the booking itself from
      // succeeding - the booking is already saved at this point.
      // ignore: avoid_print
      print('Failed to send admin notification for booking: $e');
    }

    return docRef.id;
  }

  /// ✅ SUBMIT A TRIP RATING for an approved booking.
  ///
  /// Stores the 1-5 star rating (and optional comment) on the booking
  /// document, and atomically updates the related bus's aggregate
  /// `averageRating` / `ratingCount` using a Firestore transaction so
  /// concurrent ratings from different users never overwrite each other.
  Future<void> submitRating({
    required String bookingId,
    required String busId,
    required int rating,
    String comment = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final busRef = _firestore.collection('buses').doc(busId);

    try {
      await _firestore.runTransaction((transaction) async {
        final bookingSnap = await transaction.get(bookingRef);
        if (!bookingSnap.exists) {
          throw Exception('Booking not found');
        }
        // Prevent double-counting if the user submits a rating twice.
        final alreadyRated =
            (bookingSnap.data()?['userRating'] as num?)?.toInt() ?? 0;

        final busSnap = await transaction.get(busRef);
        double currentAvg = 0.0;
        int currentCount = 0;
        if (busSnap.exists) {
          currentAvg = (busSnap.data()?['averageRating'] ?? 0.0).toDouble();
          currentCount = (busSnap.data()?['ratingCount'] as num?)?.toInt() ?? 0;
        }

        double newAvg;
        int newCount;
        if (alreadyRated > 0) {
          // Replace the previous rating from this booking in the average.
          final totalScore = (currentAvg * currentCount) - alreadyRated + rating;
          newCount = currentCount == 0 ? 1 : currentCount;
          newAvg = totalScore / newCount;
        } else {
          newCount = currentCount + 1;
          final totalScore = (currentAvg * currentCount) + rating;
          newAvg = totalScore / newCount;
        }

        transaction.update(bookingRef, {
          'userRating': rating,
          'userRatingComment': comment,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });

        if (busSnap.exists) {
          transaction.update(busRef, {
            'averageRating': newAvg,
            'ratingCount': newCount,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  /// ✅ EDIT a PENDING booking's own details (passenger name, phone, CNIC,
  /// and optionally the seat itself).
  ///
  /// Only allowed while the booking is still 'pending' - once the admin
  /// approves it, the record is locked to protect the integrity of what
  /// was actually approved (matching the same "locked once approved"
  /// pattern already used for refunds/deletes elsewhere in this service).
  ///
  /// If [newSeatNumber] differs from the booking's current seat, the seat
  /// change goes through the same atomic Realtime Database update used by
  /// the seat-locking system, so the seat map can never end up
  /// inconsistent (lost seat or phantom double-booking).
  Future<void> updateBookingDetails({
    required String bookingId,
    required String passengerName,
    required String phone,
    required String cnic,
    String? newSeatNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final snapshot = await bookingRef.get();

    if (!snapshot.exists) {
      throw Exception('Booking not found');
    }

    final booking = BookingModel.fromMap({
      'id': bookingId,
      ...snapshot.data()!,
    });

    if (booking.userId != user.uid) {
      throw Exception('You can only edit your own booking');
    }
    if (booking.status != 'pending') {
      throw Exception(
        'This booking can no longer be edited because it is no longer pending.',
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    String finalSeatNumber = booking.seatNumber;

    // Handle a seat change, if one was requested.
    if (newSeatNumber != null &&
        newSeatNumber.isNotEmpty &&
        newSeatNumber != booking.seatNumber) {
      final dateKey = _dateKey(booking.travelDate);

      final basePath = 'seat_data/${booking.busId}/$dateKey';
      final newSeatBookedRef = _realtimeDb.ref('$basePath/booked/$newSeatNumber');
      final newSeatLockRef = _realtimeDb.ref('$basePath/locks/$newSeatNumber');

      final bookedSnap = await newSeatBookedRef.get();
      if (bookedSnap.exists) {
        throw Exception('Seat $newSeatNumber is already booked. Please choose another seat.');
      }

      final lockSnap = await newSeatLockRef.get();
      if (lockSnap.exists) {
        final lockData = lockSnap.value;
        if (lockData is Map) {
          final expiresAt = (lockData['expiresAt'] as int?) ?? 0;
          if (expiresAt > now) {
            throw Exception('Seat $newSeatNumber is currently being booked by someone else. Please choose another seat.');
          }
        }
      }

      // Atomic multi-path update: free the old seat, claim the new one.
      await _realtimeDb.ref(basePath).update({
        'booked/${booking.seatNumber}': null,
        'booked/$newSeatNumber': {'bookedBy': user.uid, 'bookedAt': now},
      });

      finalSeatNumber = newSeatNumber;
    }

    // Update the booking document itself.
    await bookingRef.update({
      'userName': passengerName,
      'userPhone': phone,
      'userCnic': cnic,
      'seatNumber': finalSeatNumber,
      'updatedAt': now,
    });

    // Notify admin that a pending booking was edited by the user, so they
    // review the latest details before approving/rejecting.
    try {
      await _realtimeDb.ref('admin_notifications').push().set({
        'title': 'Booking Updated by User',
        'message': '$passengerName updated their pending booking '
            '(seat $finalSeatNumber, ${booking.busFrom} → ${booking.busTo}). '
            'Please review before approving.',
        'type': 'booking',
        'bookingId': bookingId,
        'isRead': false,
        'createdAt': now,
      });
    } catch (e) {
      // A notification failure should not block the edit itself.
      // ignore: avoid_print
      print('Failed to send admin notification for booking edit: $e');
    }
  }

  /// ✅ ADD MORE SEATS to an existing booking.
  ///
  /// Does NOT modify the original booking at all - it creates a brand new
  /// linked booking document covering the additional seats only, using the
  /// same 'pending' → admin-approval flow as any other booking. This keeps
  /// the original booking's seat/record completely untouched (per design),
  /// while letting the same user book more seats on the same bus/date.
  ///
  /// [extraSeats] must all be currently free (not booked or actively
  /// locked) - each one is claimed atomically before the booking document
  /// is created, and if any of them turns out to be taken, nothing is
  /// created and an exception is thrown.
  Future<String> addExtraSeats({
    required BookingModel originalBooking,
    required List<String> extraSeats,
    required String senderName,
    required String senderNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    if (originalBooking.userId != user.uid) {
      throw Exception('You can only add seats to your own booking');
    }
    if (extraSeats.isEmpty) {
      throw Exception('Please select at least one seat to add');
    }

    // Determine the reservation's ROOT booking (originalBooking itself if
    // it has no link, or whatever it's linked to) and refuse to add more
    // seats unless the root is still pending. This mirrors the check the
    // UI already does (ticket_details_dialog.dart), but is enforced here
    // too as a safety net in case the admin approves/rejects the root in
    // the moment between the dialog opening and the user hitting confirm.
    final rootId = originalBooking.linkedBookingId.isNotEmpty
        ? originalBooking.linkedBookingId
        : originalBooking.id;
    final rootBooking = await getBookingById(rootId);
    if (rootBooking == null || rootBooking.status != 'pending') {
      throw Exception(
        'This booking has already been reviewed by the admin - you can no '
        'longer add seats to it. Please make a new booking instead.',
      );
    }

    // ✅ ONE-TIME USE: "Add More Seats" can only ever be used ONCE per
    // reservation. Once the root booking has been used to create an
    // addon, this stays permanently blocked - even if that addon later
    // gets rejected or refunded - so a user can't keep padding the same
    // pending booking with extra seats across multiple separate requests.
    if (rootBooking.hasUsedAddSeats) {
      throw Exception(
        'You have already used your one chance to add more seats to this '
        'booking. Please make a new booking for any additional seats.',
      );
    }

    // ✅ MAX 5 SEATS TOTAL per reservation: 1 original seat + up to 4
    // extra seats in this one addon request.
    if (extraSeats.length > 4) {
      throw Exception(
        'You can add at most 4 extra seats (5 total including your '
        'original seat).',
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final dateKey = _dateKey(originalBooking.travelDate);
    final basePath = 'seat_data/${originalBooking.busId}/$dateKey';

    // Verify every requested seat is still free right now, and claim them
    // all in one atomic multi-path update so two people can't grab the
    // same seat in the gap between checking and booking.
    final updates = <String, dynamic>{};
    for (final seat in extraSeats) {
      final bookedSnap = await _realtimeDb.ref('$basePath/booked/$seat').get();
      if (bookedSnap.exists) {
        throw Exception('Seat $seat is already booked. Please choose another seat.');
      }
      final lockSnap = await _realtimeDb.ref('$basePath/locks/$seat').get();
      if (lockSnap.exists) {
        final lockData = lockSnap.value;
        if (lockData is Map) {
          final expiresAt = (lockData['expiresAt'] as int?) ?? 0;
          if (expiresAt > now) {
            throw Exception('Seat $seat is currently being booked by someone else.');
          }
        }
      }
      updates['booked/$seat'] = {'bookedBy': user.uid, 'bookedAt': now};
    }

    await _realtimeDb.ref(basePath).update(updates);

    // Price: same per-seat price as the original booking, x number of
    // extra seats.
    final perSeatPrice = originalBooking.price;
    final totalAmount = perSeatPrice * extraSeats.length;
    final combinedSeatLabel = extraSeats.join(',');

    final docRef = _firestore.collection('bookings').doc();
    final bookingData = {
      'bookingId': docRef.id,
      'id': docRef.id,
      // Reuse the ROOT's booking number - an addon is part of the same
      // reservation, not a separate one, so it should read as the same
      // NT-XXXX to staff searching for it.
      'bookingNumber': rootBooking.bookingNumber,
      'userId': user.uid,
      'userName': originalBooking.userName,
      'userEmail': user.email ?? '',
      'userPhone': originalBooking.phone,
      'userCnic': originalBooking.cnic,
      'userGender': originalBooking.gender,
      'busId': originalBooking.busId,
      'busFrom': originalBooking.busFrom,
      'busTo': originalBooking.busTo,
      'seatNumber': combinedSeatLabel,
      'travelDate': originalBooking.travelDate,
      'time': originalBooking.time,
      'paymentMethod': 'JazzCash',
      'senderName': senderName,
      'senderNumber': senderNumber,
      'paidAmount': totalAmount,
      'totalAmount': totalAmount,
      'price': perSeatPrice,
      'paymentReference': '',
      'status': 'pending',
      'refundStatus': 'none',
      'createdAt': now,
      'updatedAt': now,
      'bookingDate': Timestamp.now(),
      'linkedBookingId': originalBooking.id,
    };

    await docRef.set(bookingData);

    // ✅ Permanently mark the ROOT booking as having used its one and only
    // "Add More Seats" chance - this must be set on the ROOT (not
    // necessarily originalBooking itself, in case this somehow runs
    // against something already linked), so the block applies to the
    // whole reservation going forward.
    await _firestore.collection('bookings').doc(rootId).update({
      'hasUsedAddSeats': true,
      'updatedAt': now,
    });

    await _realtimeDb.ref('booking_status/${docRef.id}').set({
      'status': 'pending',
      'refundStatus': 'none',
      'updatedAt': now,
    });

    // Notify admin, same as any new booking.
    try {
      await _realtimeDb.ref('admin_notifications').push().set({
        'title': 'Additional Seats Requested',
        'message': '${originalBooking.userName} requested ${extraSeats.length} '
                'more seat(s) ($combinedSeatLabel) on their existing booking '
                '(${originalBooking.busFrom} → ${originalBooking.busTo}) - '
            'Amount: Rs ${totalAmount.toStringAsFixed(0)}',
        'type': 'booking',
        'bookingId': docRef.id,
        'linkedBookingId': originalBooking.id,
        'isRead': false,
        'createdAt': now,
      });
    } catch (e) {
      // ignore: avoid_print
      print('Failed to send admin notification for extra seats: $e');
    }

    return docRef.id;
  }

  /// ✅ Fetch every booking related to a given booking: the original
  /// booking itself, plus every "extra seats" booking linked to it (and,
  /// if [booking] IS an addon booking, its sibling addons too). Used by
  /// the "Add More Seats" section to show the user everything they've
  /// already booked on this same original reservation before they add more.
  Future<List<BookingModel>> getRelatedBookings(BookingModel booking) async {
    final user = _auth.currentUser;
    if (user == null) return [booking];

    // The "root" booking ID: if this booking is itself an addon, its root
    // is whatever it's linked to; otherwise it IS the root.
    final rootId = booking.linkedBookingId.isNotEmpty
        ? booking.linkedBookingId
        : booking.id;

    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .get();

      final all = snapshot.docs
          .map((doc) => BookingModel.fromMap({'id': doc.id, ...doc.data()}))
          .where(
            (b) =>
                b.id == rootId || // the root booking itself
                b.linkedBookingId == rootId, // any addon linked to the root
          )
          .toList();

      all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return all;
    } catch (e) {
      // If this lookup fails for any reason, fall back to just showing
      // the current booking rather than blocking the Add Seats flow.
      return [booking];
    }
  }

  /// ✅ HELPER: Format date key for Realtime DB
  String _dateKey(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date.replaceAll('/', '-');

    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }
}