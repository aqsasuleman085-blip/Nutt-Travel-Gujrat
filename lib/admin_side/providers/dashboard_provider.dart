import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _totalUsers = 0;
  double _totalEarnings = 0.0;
  int _totalBuses = 0;
  int _totalBookings = 0;
  bool _isLoading = false;

  DashboardProvider() {
    _calculateMetrics();
  }

  // Getters
  int get totalUsers => _totalUsers;
  double get totalEarnings => _totalEarnings;
  int get totalBuses => _totalBuses;
  int get totalBookings => _totalBookings;
  bool get isLoading => _isLoading;

  void _calculateMetrics() {
    _isLoading = true;
    notifyListeners();

    try {
      _firestore.collection('bookings').snapshots().listen((bookingsSnapshot) {
        final docs = bookingsSnapshot.docs;
        _totalBookings = docs.length;

        final approved = docs.where((doc) => doc.data()['status'] == 'approved');
        _totalEarnings = approved.fold(0.0, (sum, doc) {
          final price = doc.data()['price'];
          return sum + (price as num).toDouble();
        });

        final uniqueEmails = docs.map((doc) => doc.data()['userEmail'] as String?).where((e) => e != null).toSet();
        _totalUsers = uniqueEmails.length;
        
        _isLoading = false;
        notifyListeners();
      });

      _firestore.collection('buses').snapshots().listen((busesSnapshot) {
        _totalBuses = busesSnapshot.docs.length;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error calculating metrics: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void refreshMetrics() {
    // With streams, refreshing is automatic, but we can keep it for signature match
  }
}