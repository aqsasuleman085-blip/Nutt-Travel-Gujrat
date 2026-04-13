class BusModel {
  final String id;
  final String from;
  final String to;
  final String departureTime;
  final double ticketPrice;
  final String driverName;
  final String numberPlate;
  final String status;
  final DateTime createdAt;

  BusModel({
    required this.id,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.ticketPrice,
    required this.driverName,
    required this.numberPlate,
    this.status = 'Active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'departureTime': departureTime,
      'ticketPrice': ticketPrice,
      'driverName': driverName,
      'numberPlate': numberPlate,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BusModel.fromMap(Map<String, dynamic> map) {
    return BusModel(
      id: map['id'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      departureTime: map['departureTime'] ?? '',
      ticketPrice: (map['ticketPrice'] ?? 0.0).toDouble(),
      driverName: map['driverName'] ?? '',
      numberPlate: map['numberPlate'] ?? '',
      status: map['status'] ?? 'Active',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel.fromMap(json);
  }
}
