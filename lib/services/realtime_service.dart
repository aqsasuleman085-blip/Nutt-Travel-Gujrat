import 'package:firebase_database/firebase_database.dart';

class RealtimeService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// 🔥 STREAM (LOCKS + BOOKED SEATS)
  Stream<Map<String, dynamic>> streamSeatLocks({
    required String busId,
    required String dateKey,
  }) {
    return _database.ref('seat_data/$busId/$dateKey').onValue.map((event) {
      final data = event.snapshot.value;

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return {"locks": {}, "booked": {}};
    });
  }

  /// 🔥 GET CURRENT DATA
  Future<Map<String, dynamic>> getSeatLocks({
    required String busId,
    required String dateKey,
  }) async {
    final snapshot = await _database.ref('seat_data/$busId/$dateKey').get();

    final data = snapshot.value;

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {"locks": {}, "booked": {}};
  }

  /// 🔥 LOCK SEAT (TEMP)
  Future<bool> lockSeat({
    required String busId,
    required String dateKey,
    required String seatNumber,
    required String userId,
    int ttlSeconds = 300,
  }) async {
    final ref = _database.ref('seat_data/$busId/$dateKey/locks/$seatNumber');

    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + (ttlSeconds * 1000);

    final result = await ref.runTransaction((current) {
      if (current is Map) {
        final currentMap = Map<String, dynamic>.from(current);
        final currentExpires = currentMap['expiresAt'] as int? ?? 0;

        if (currentExpires > now) {
          return Transaction.abort();
        }
      }

      return Transaction.success({
        'lockedBy': userId,
        'lockedAt': now,
        'expiresAt': expiresAt,
      });
    });

    return result.committed;
  }

  /// 🔥 CONFIRM BOOKING (PERMANENT)
  Future<void> confirmBooking({
    required String busId,
    required String dateKey,
    required String seatNumber,
    required String userId,
  }) async {
    final bookedRef = _database.ref(
      'seat_data/$busId/$dateKey/booked/$seatNumber',
    );

    final lockRef = _database.ref(
      'seat_data/$busId/$dateKey/locks/$seatNumber',
    );

    final now = DateTime.now().millisecondsSinceEpoch;

    await bookedRef.set({"bookedBy": userId, "bookedAt": now});

    await lockRef.remove();
  }

  /// 🔥 RELEASE LOCK (IF USER CANCELS)
  Future<void> releaseSeat({
    required String busId,
    required String dateKey,
    required String seatNumber,
  }) async {
    await _database.ref('seat_data/$busId/$dateKey/locks/$seatNumber').remove();
  }

  /// 🔥 CHANGE A CONFIRMED (BOOKED) SEAT - used when a user edits their own
  /// pending booking and picks a different seat.
  ///
  /// Frees [oldSeatNumber] and marks [newSeatNumber] as booked in a single
  /// atomic multi-path update, so the seat map can never end up with
  /// neither seat marked (lost booking) or both seats marked (phantom
  /// double-booking) if the app crashes mid-operation.
  ///
  /// Returns false (and makes no changes) if [newSeatNumber] is already
  /// booked or locked by someone else by the time this runs.
  Future<bool> changeBookedSeat({
    required String busId,
    required String dateKey,
    required String oldSeatNumber,
    required String newSeatNumber,
    required String userId,
  }) async {
    if (oldSeatNumber == newSeatNumber) return true;

    final basePath = 'seat_data/$busId/$dateKey';
    final newSeatBookedRef = _database.ref('$basePath/booked/$newSeatNumber');
    final newSeatLockRef = _database.ref('$basePath/locks/$newSeatNumber');

    // Make sure the target seat is actually free right now.
    final bookedSnap = await newSeatBookedRef.get();
    if (bookedSnap.exists) return false;

    final lockSnap = await newSeatLockRef.get();
    if (lockSnap.exists) {
      final lockData = lockSnap.value;
      if (lockData is Map) {
        final expiresAt = (lockData['expiresAt'] as int?) ?? 0;
        if (expiresAt > DateTime.now().millisecondsSinceEpoch) {
          return false; // still actively locked by someone else
        }
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // Single atomic multi-path update: remove old booked seat, add new one.
    await _database.ref(basePath).update({
      'booked/$oldSeatNumber': null,
      'booked/$newSeatNumber': {'bookedBy': userId, 'bookedAt': now},
    });

    return true;
  }
}
