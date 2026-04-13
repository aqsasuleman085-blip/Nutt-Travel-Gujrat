class BookingModel {
  final String id;
  final String userName;
  final String userEmail;
  final String busId;
  final String busFrom;
  final String busTo;
  final double price;
  final String status; // pending, approved, rejected
  final DateTime bookingDate;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.busId,
    required this.busFrom,
    required this.busTo,
    required this.price,
    this.status = 'pending',
    DateTime? bookingDate,
    DateTime? createdAt,
  }) : bookingDate = bookingDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userName': userName,
      'userEmail': userEmail,
      'busId': busId,
      'busFrom': busFrom,
      'busTo': busTo,
      'price': price,
      'status': status,
      'bookingDate': bookingDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      busId: map['busId'] ?? '',
      busFrom: map['busFrom'] ?? '',
      busTo: map['busTo'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      bookingDate: DateTime.fromMillisecondsSinceEpoch(
        map['bookingDate'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}