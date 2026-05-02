import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookingsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _busesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;

  int _totalUsers = 0;
  double _totalEarnings = 0.0;
  int _totalBuses = 0;
  int _totalBookings = 0;
  int _approvedBookingsCount = 0;
  int _pendingBookingsCount = 0;
  bool _isLoading = false;

  DashboardProvider() {
    _listenToMetrics();
  }

  // Getters
  int get totalUsers => _totalUsers;
  double get totalEarnings => _totalEarnings;
  int get totalBuses => _totalBuses;
  int get totalBookings => _totalBookings;
  int get approvedBookingsCount => _approvedBookingsCount;
  int get pendingBookingsCount => _pendingBookingsCount;
  bool get isLoading => _isLoading;

  // Real-time listeners for dashboard metrics
  void _listenToMetrics() {
    _isLoading = true;
    notifyListeners();

    // Listen to bookings collection
    _bookingsSub = _firestore
        .collection('bookings')
        .snapshots()
        .listen(
          (snapshot) {
            _totalBookings = snapshot.size;

            final approvedDocs = snapshot.docs.where(
              (doc) => doc.data()['status'] == 'approved',
            );
            _approvedBookingsCount = approvedDocs.length;

            _pendingBookingsCount = snapshot.docs
                .where((doc) => doc.data()['status'] == 'pending')
                .length;

            _totalEarnings = approvedDocs.fold(
              0.0,
              (sum, doc) =>
                  sum + (doc.data()['price'] as num? ?? 0).toDouble(),
            );

            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error listening to bookings: $e');
            _isLoading = false;
            notifyListeners();
          },
        );

    // Listen to buses collection
    _busesSub = _firestore.collection('buses').snapshots().listen(
      (snapshot) {
        _totalBuses = snapshot.size;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error listening to buses: $e');
      },
    );

    // Listen to users collection
    _usersSub = _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .snapshots()
        .listen(
          (snapshot) {
            _totalUsers = snapshot.size;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error listening to users: $e');
          },
        );
  }

  // Refresh metrics (re-subscribes listeners)
  void refreshMetrics() {
    _bookingsSub?.cancel();
    _busesSub?.cancel();
    _usersSub?.cancel();
    _listenToMetrics();
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _busesSub?.cancel();
    _usersSub?.cancel();
    super.dispose();
  }
}
