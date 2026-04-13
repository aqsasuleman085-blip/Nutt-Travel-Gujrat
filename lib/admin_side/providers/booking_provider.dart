import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../services/storage_service.dart';

class BookingProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  late final StorageService _storageService;
  
  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  
  BookingProvider(this._prefs) {
    _storageService = StorageService(_prefs);
    _loadBookings();
    _addSampleBookings();
  }
  
  // Getters
  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  
  // Get bookings by status
  List<BookingModel> get pendingBookings => _bookings.where((booking) => booking.status == 'pending').toList();
  List<BookingModel> get approvedBookings => _bookings.where((booking) => booking.status == 'approved').toList();
  List<BookingModel> get rejectedBookings => _bookings.where((booking) => booking.status == 'rejected').toList();
  
  // Load bookings from storage
  void _loadBookings() {
    final bookingsData = _storageService.getBookings();
    _bookings = bookingsData.map((bookingData) => BookingModel.fromMap(bookingData)).toList();
    notifyListeners();
  }
  
  // Save bookings to storage
  Future<void> _saveBookings() async {
    final bookingsData = _bookings.map((booking) => booking.toMap()).toList();
    await _storageService.saveBookings(bookingsData);
  }
  
  // Add sample bookings (for demo purposes)
  void _addSampleBookings() {
    if (_bookings.isEmpty) {
      final now = DateTime.now();
      final sampleBookings = [
        BookingModel(
          id: '1',
          userName: 'John Doe',
          userEmail: 'john@example.com',
          busId: '1',
          busFrom: 'Gujrat',
          busTo: 'Islamabad',
          price: 1200.0,
          status: 'pending',
          bookingDate: now,
        ),
        BookingModel(
          id: '2',
          userName: 'Jane Smith',
          userEmail: 'jane@example.com',
          busId: '2',
          busFrom: 'Lahore',
          busTo: 'Karachi',
          price: 2500.0,
          status: 'approved',
          bookingDate: now.subtract(const Duration(days: 1)),
        ),
        BookingModel(
          id: '3',
          userName: 'Ahmed Khan',
          userEmail: 'ahmed@example.com',
          busId: '3',
          busFrom: 'Peshawar',
          busTo: 'Quetta',
          price: 1800.0,
          status: 'rejected',
          bookingDate: now.subtract(const Duration(days: 2)),
        ),
      ];
      
      _bookings = sampleBookings;
      _saveBookings();
      notifyListeners();
    }
  }
  
  // Add a new booking
  Future<void> addBooking({
    required String userName,
    required String userEmail,
    required String busId,
    required String busFrom,
    required String busTo,
    required double price,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final newBooking = BookingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userName: userName,
        userEmail: userEmail,
        busId: busId,
        busFrom: busFrom,
        busTo: busTo,
        price: price,
      );
      
      _bookings.add(newBooking);
      await _saveBookings();
    } catch (e) {
      debugPrint('Error adding booking: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Approve a booking
  Future<void> approveBooking(String bookingId) async {
    try {
      final bookingIndex = _bookings.indexWhere((booking) => booking.id == bookingId);
      if (bookingIndex != -1) {
        _bookings[bookingIndex] = BookingModel(
          id: _bookings[bookingIndex].id,
          userName: _bookings[bookingIndex].userName,
          userEmail: _bookings[bookingIndex].userEmail,
          busId: _bookings[bookingIndex].busId,
          busFrom: _bookings[bookingIndex].busFrom,
          busTo: _bookings[bookingIndex].busTo,
          price: _bookings[bookingIndex].price,
          status: 'approved',
          bookingDate: _bookings[bookingIndex].bookingDate,
          createdAt: _bookings[bookingIndex].createdAt,
        );
        
        await _saveBookings();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error approving booking: $e');
    }
  }
  
  // Reject a booking
  Future<void> rejectBooking(String bookingId) async {
    try {
      final bookingIndex = _bookings.indexWhere((booking) => booking.id == bookingId);
      if (bookingIndex != -1) {
        _bookings[bookingIndex] = BookingModel(
          id: _bookings[bookingIndex].id,
          userName: _bookings[bookingIndex].userName,
          userEmail: _bookings[bookingIndex].userEmail,
          busId: _bookings[bookingIndex].busId,
          busFrom: _bookings[bookingIndex].busFrom,
          busTo: _bookings[bookingIndex].busTo,
          price: _bookings[bookingIndex].price,
          status: 'rejected',
          bookingDate: _bookings[bookingIndex].bookingDate,
          createdAt: _bookings[bookingIndex].createdAt,
        );
        
        await _saveBookings();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error rejecting booking: $e');
    }
  }
  
  // Get total earnings from approved bookings
  double get totalEarnings {
    return approvedBookings.fold(0.0, (sum, booking) => sum + booking.price);
  }
  
  // Get total bookings count
  int get totalBookings {
    return _bookings.length;
  }
  
  // Get unique users count
  int get uniqueUsersCount {
    final uniqueEmails = _bookings.map((booking) => booking.userEmail).toSet();
    return uniqueEmails.length;
  }
}