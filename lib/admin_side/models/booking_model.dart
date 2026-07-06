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
  final double price;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final String paymentMethod;
  final String paymentReference;
  final String senderName;
  final String senderNumber;
  final String paymentScreenshotUrl;
  final String gender;
  final String travelDate;
  final DateTime bookingDate;
  final DateTime createdAt;

  // REFUND FIELDS
  final String refundAmount;
  final String refundAccountName;
  final String refundStatus;
  final String refundReason;
  final int? refundRequestedAt;
  final int? refundApprovedAt;
  
  // REJECTION FIELDS
  final String rejectionReason;
  final DateTime? rejectedAt;

  // SOFT-DELETE: list of userIds who have hidden this booking from their
  // own "My Tickets" list. The booking document itself is never removed
  // from Firestore, so admin records are always preserved.
  final List<String> hiddenFor;

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
    this.senderNumber = '',
    this.paymentScreenshotUrl = '',
    this.gender = '',
    this.travelDate = '',
    this.refundAmount = '',
    this.refundAccountName = '',
    this.refundStatus = 'none',
    this.refundReason = '',
    this.refundRequestedAt,
    this.refundApprovedAt,
    this.rejectionReason = '',
    this.rejectedAt,
    this.hiddenFor = const [],
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
      'price': price,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'senderName': senderName,
      'senderNumber': senderNumber,
      'paymentScreenshotUrl': paymentScreenshotUrl,
      'gender': gender,
      'travelDate': travelDate,
      'bookingDate': bookingDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      // Refund fields
      'refundAmount': refundAmount,
      'refundAccountName': refundAccountName,
      'refundStatus': refundStatus,
      'refundReason': refundReason,
      'refundRequestedAt': refundRequestedAt,
      'refundApprovedAt': refundApprovedAt,
      // Rejection fields
      'rejectionReason': rejectionReason,
      'rejectedAt': rejectedAt?.millisecondsSinceEpoch,
      // Soft-delete tracking
      'hiddenFor': hiddenFor,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? map['name'] ?? '',
      userEmail: map['userEmail'] ?? '',
      phone: map['phone'] ?? map['userPhone'] ?? '',
      cnic: map['cnic'] ?? map['userCnic'] ?? '',
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
      senderNumber: map['senderNumber'] ?? '',
      paymentScreenshotUrl: map['paymentScreenshotUrl'] ?? '',
      gender: map['gender'] ?? map['userGender'] ?? '',
      travelDate: map['travelDate'] ?? map['bookingDate'] ?? '',
      // Refund fields
      refundAmount: map['refundAmount']?.toString() ?? '',
      refundAccountName: map['refundAccountName'] ?? '',
      refundStatus: map['refundStatus'] ?? 'none',
      refundReason: map['refundReason'] ?? '',
      refundRequestedAt: map['refundRequestedAt'],
      refundApprovedAt: map['refundApprovedAt'],
      // Rejection fields
      rejectionReason: map['rejectionReason'] ?? '',
      rejectedAt: map['rejectedAt'] != null
          ? _toDateTime(map['rejectedAt'])
          : null,
      hiddenFor: map['hiddenFor'] != null
          ? List<String>.from(map['hiddenFor'])
          : const [],
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