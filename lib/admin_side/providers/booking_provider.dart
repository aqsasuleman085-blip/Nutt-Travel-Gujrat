import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BookingModel> _bookings = [];
  bool _isLoading = false;

  BookingProvider() {
    _loadBookings();
  }

  // Getters
  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;

  List<BookingModel> get pendingBookings => _bookings.where((booking) => booking.status == 'pending').toList();
  List<BookingModel> get approvedBookings => _bookings.where((booking) => booking.status == 'approved').toList();
  List<BookingModel> get rejectedBookings => _bookings.where((booking) => booking.status == 'rejected').toList();

  void _loadBookings() {
    _firestore.collection('bookings').snapshots().listen((snapshot) {
      _bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BookingModel.fromMap(data);
      }).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error listening to bookings: $error');
    });
  }

  Future<void> addBooking({
    required String userName,
    required String userEmail,
    required String busId,
    required String busFrom,
    required String busTo,
    required double price,
    String? screenshotUrl,
    String? paymentMethod,
    String? userUid,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newBookingData = {
        'userName': userName,
        'userEmail': userEmail,
        'busId': busId,
        'busFrom': busFrom,
        'busTo': busTo,
        'price': price,
        'screenshotUrl': screenshotUrl,
        'paymentMethod': paymentMethod,
        'userUid': userUid,
        'status': 'pending',
        'bookingDate': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('bookings').add(newBookingData);
    } catch (e) {
      debugPrint('Error adding booking: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({'status': 'approved'});
    } catch (e) {
      debugPrint('Error approving booking: $e');
    }
  }

  Future<void> rejectBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({'status': 'rejected'});
    } catch (e) {
      debugPrint('Error rejecting booking: $e');
    }
  }

  double get totalEarnings {
    return approvedBookings.fold(0.0, (sum, booking) => sum + booking.price);
  }

  int get totalBookings => _bookings.length;

  int get uniqueUsersCount {
    final uniqueEmails = _bookings.map((booking) => booking.userEmail).toSet();
    return uniqueEmails.length;
  }
}