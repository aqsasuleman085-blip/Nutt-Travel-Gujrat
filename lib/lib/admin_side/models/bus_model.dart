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
  final String status;
  final DateTime createdAt;

  BusModel({
    required this.id,
    required this.from,
    required this.to,
    required this.departureAt,
    required this.ticketPrice,
    required this.driverName,
    required this.numberPlate,
    required this.totalSeats,
    this.status = 'Active',
    DateTime? createdAt,
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
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
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
      status: map['status'] ?? 'Active',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
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
