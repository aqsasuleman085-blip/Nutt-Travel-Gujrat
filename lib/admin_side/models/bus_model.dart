import 'package:cloud_firestore/cloud_firestore.dart';

class BusModel {
  final String id;
  final String from;
  final String to;
  final DateTime departureAt;
  final double ticketPrice;
  final String driverName;
  final String numberPlate;
  final int totalSeats;
  final DateTime createdAt;

  // RATING AGGREGATES: updated whenever a user rates a completed trip on
  // this bus. averageRating is 0 when ratingCount is 0.
  final double averageRating;
  final int ratingCount;

  /// STATUS IS NOW FULLY AUTO-CALCULATED from [departureAt] - there is no
  /// manual Active/Inactive/Maintenance field anymore. A bus is 'Active'
  /// as long as its departure time is still in the future, and becomes
  /// 'Expired' automatically the moment that time passes - no admin action
  /// needed, and no way for it to get "stuck" on the wrong value.
  String get status => isExpired ? 'Expired' : 'Active';

  bool get isExpired => departureAt.isBefore(DateTime.now());

  BusModel({
    required this.id,
    required this.from,
    required this.to,
    required this.departureAt,
    required this.ticketPrice,
    required this.driverName,
    required this.numberPlate,
    required this.totalSeats,
    DateTime? createdAt,
    this.averageRating = 0.0,
    this.ratingCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'departureAt': departureAt,
      'ticketPrice': ticketPrice,
      'driverName': driverName,
      'numberPlate': numberPlate,
      'totalSeats': totalSeats,
      // 'status' is still written for readability when inspecting Firestore
      // directly, but it is NEVER read back - status is always recomputed
      // from departureAt on load, so this value cannot go stale.
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
    };
  }

  factory BusModel.fromMap(Map<String, dynamic> map) {
    return BusModel(
      id: map['id'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      departureAt: _parseDepartureAt(map['departureAt']),
      ticketPrice: (map['ticketPrice'] ?? 0.0).toDouble(),
      driverName: map['driverName'] ?? '',
      numberPlate: map['numberPlate'] ?? '',
      totalSeats: (map['totalSeats'] is num)
          ? (map['totalSeats'] as num).toInt()
          : 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      ratingCount: (map['ratingCount'] is num)
          ? (map['ratingCount'] as num).toInt()
          : 0,
    );
  }

  static DateTime _parseDepartureAt(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => toMap();

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel.fromMap(json);
  }
}
