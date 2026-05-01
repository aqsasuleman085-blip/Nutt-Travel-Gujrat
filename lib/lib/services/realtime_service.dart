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
}
