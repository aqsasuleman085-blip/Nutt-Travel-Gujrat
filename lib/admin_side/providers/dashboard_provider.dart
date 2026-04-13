import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';

class DashboardProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  late final StorageService _storageService;
  
  int _totalUsers = 0;
  double _totalEarnings = 0.0;
  int _totalBuses = 0;
  int _totalBookings = 0;
  bool _isLoading = false;
  
  DashboardProvider(this._prefs) {
    _storageService = StorageService(_prefs);
    _calculateMetrics();
  }
  
  // Getters
  int get totalUsers => _totalUsers;
  double get totalEarnings => _totalEarnings;
  int get totalBuses => _totalBuses;
  int get totalBookings => _totalBookings;
  bool get isLoading => _isLoading;
  
  // Calculate dashboard metrics
  void _calculateMetrics() {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get bookings data
      final bookingsData = _storageService.getBookings();
      final approvedBookings = bookingsData.where((booking) => booking['status'] == 'approved');
      
      // Calculate total earnings from approved bookings
      _totalEarnings = approvedBookings.fold(0.0, (sum, booking) => sum + (booking['price'] as num).toDouble());
      
      // Calculate total bookings
      _totalBookings = bookingsData.length;
      
      // Calculate unique users
      final uniqueEmails = bookingsData.map((booking) => booking['userEmail'] as String).toSet();
      _totalUsers = uniqueEmails.length;
      
      // Get total buses
      final busesData = _storageService.getBuses();
      _totalBuses = busesData.length;
    } catch (e) {
      debugPrint('Error calculating metrics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Refresh metrics
  void refreshMetrics() {
    _calculateMetrics();
  }
}