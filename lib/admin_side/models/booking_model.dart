class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String phone;
  final String cnic;
  final String busId;
  final String busFrom;
  final String busTo;
  final String seatNumber;
  final String time;
  final double price; // Firestore stores as int, we convert to double
  final double totalAmount;
  final double paidAmount;
  final String status; // pending, approved, rejected
  final String paymentMethod;
  final String paymentReference;
  final String senderName;
  final String paymentScreenshotUrl;
  final String gender;
  final String travelDate; // string like "2026-04-28"
  final DateTime bookingDate; // from millisecondsSinceEpoch
  final DateTime createdAt; // from millisecondsSinceEpoch

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.phone = '',
    this.cnic = '',
    required this.busId,
    required this.busFrom,
    required this.busTo,
    required this.seatNumber,
    this.time = '',
    required this.price,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.status = 'pending',
    this.paymentMethod = 'Unknown',
    this.paymentReference = '',
    this.senderName = '',
    this.paymentScreenshotUrl = '',
    this.gender = '',
    this.travelDate = '',
    DateTime? bookingDate,
    DateTime? createdAt,
  }) : bookingDate = bookingDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'phone': phone,
      'cnic': cnic,
      'busId': busId,
      'busFrom': busFrom,
      'busTo': busTo,
      'seatNumber': seatNumber,
      'time': time,
      'price': price, // Firestore will store as double/int
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'senderName': senderName,
      'paymentScreenshotUrl': paymentScreenshotUrl,
      'gender': gender,
      'travelDate': travelDate,
      'bookingDate': bookingDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? map['name'] ?? '',
      userEmail: map['userEmail'] ?? '',
      phone: map['phone'] ?? '',
      cnic: map['cnic'] ?? '',
      busId: map['busId'] ?? '',
      busFrom: map['busFrom'] ?? map['from'] ?? '',
      busTo: map['busTo'] ?? map['to'] ?? '',
      seatNumber: map['seatNumber'] ?? map['seat'] ?? '',
      time: map['time'] ?? '',
      price: (map['price'] ?? map['totalAmount'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? map['price'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? 'Unknown',
      paymentReference: map['paymentReference'] ?? '',
      senderName: map['senderName'] ?? '',
      paymentScreenshotUrl: map['paymentScreenshotUrl'] ?? '',
      gender: map['gender'] ?? '',
      travelDate: map['travelDate'] ?? map['bookingDate'] ?? '',
      bookingDate: _toDateTime(map['createdAt'] ?? map['bookingDate']),
      createdAt: _toDateTime(map['createdAt'], fallbackToNow: true),
    );
  }

  static DateTime _toDateTime(dynamic value, {bool fallbackToNow = false}) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (fallbackToNow) return DateTime.now();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
