import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A single day's worth of aggregated counts, used to draw the small
/// bar/line mini-charts on each dashboard card and the bigger trend chart
/// on the Earnings detail screen.
class DailyMetric {
  final DateTime day;
  final int bookingsCreated;
  final int approvedCreated;
  final int usersCreated;
  final double earnings;

  const DailyMetric({
    required this.day,
    this.bookingsCreated = 0,
    this.approvedCreated = 0,
    this.usersCreated = 0,
    this.earnings = 0,
  });
}

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
  int _rejectedBookingsCount = 0;
  int _refundBookingsCount = 0;
  int _activeBusesCount = 0;
  int _inactiveBusesCount = 0;
  bool _isLoading = false;

  /// Last 7 days of aggregated metrics, oldest first. Index 6 is today.
  List<DailyMetric> _last7Days = List.generate(
    7,
    (i) => DailyMetric(
      day: DateTime.now().subtract(Duration(days: 6 - i)),
    ),
  );

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
  int get rejectedBookingsCount => _rejectedBookingsCount;
  int get refundBookingsCount => _refundBookingsCount;
  int get activeBusesCount => _activeBusesCount;
  int get inactiveBusesCount => _inactiveBusesCount;
  bool get isLoading => _isLoading;
  List<DailyMetric> get last7Days => _last7Days;

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

            _rejectedBookingsCount = snapshot.docs
                .where((doc) => doc.data()['status'] == 'rejected')
                .length;

            _refundBookingsCount = snapshot.docs
                .where(
                  (doc) => (doc.data()['status'] ?? '').toString().contains(
                    'refund',
                  ),
                )
                .length;

            _totalEarnings = approvedDocs.fold(
              0.0,
              (sum, doc) =>
                  sum + (doc.data()['price'] as num? ?? 0).toDouble(),
            );

            _computeLast7Days(snapshot.docs);

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
        _activeBusesCount = snapshot.docs
            .where((doc) => (doc.data()['status'] ?? 'Active') == 'Active')
            .length;
        _inactiveBusesCount = _totalBuses - _activeBusesCount;
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
            _computeUserSignupsLast7Days(snapshot.docs);
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error listening to users: $e');
          },
        );
  }

  /// Buckets user documents into the last 7 calendar days based on their
  /// `createdAt` timestamp, so the "Total Users" dashboard card can show a
  /// real signups-per-day mini-chart instead of a flat/empty one.
  void _computeUserSignupsLast7Days(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final signupCounts = List.filled(7, 0);

    for (final doc in docs) {
      final data = doc.data();
      final createdAtRaw = data['createdAt'];
      DateTime? createdAt;
      if (createdAtRaw is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
      } else if (createdAtRaw is Timestamp) {
        createdAt = createdAtRaw.toDate();
      }
      if (createdAt == null) continue;

      final createdDay = DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
      );

      final index = days.indexWhere((d) => d == createdDay);
      if (index == -1) continue;

      signupCounts[index]++;
    }

    // Merge signup counts into the existing _last7Days list (which already
    // holds booking/earnings data computed separately) rather than
    // overwriting it.
    _last7Days = List.generate(7, (i) {
      final existing = i < _last7Days.length ? _last7Days[i] : null;
      return DailyMetric(
        day: days[i],
        bookingsCreated: existing?.bookingsCreated ?? 0,
        approvedCreated: existing?.approvedCreated ?? 0,
        earnings: existing?.earnings ?? 0,
        usersCreated: signupCounts[i],
      );
    });
  }

  /// Buckets booking documents into the last 7 calendar days based on their
  /// `createdAt` timestamp, so each dashboard card can show a small trend
  /// chart (bookings/day, approved/day, earnings/day).
  void _computeLast7Days(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final bookingCounts = List.filled(7, 0);
    final approvedCounts = List.filled(7, 0);
    final earningsPerDay = List.filled(7, 0.0);

    for (final doc in docs) {
      final data = doc.data();
      final createdAtRaw = data['createdAt'];
      DateTime? createdAt;
      if (createdAtRaw is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
      } else if (createdAtRaw is Timestamp) {
        createdAt = createdAtRaw.toDate();
      }
      if (createdAt == null) continue;

      final createdDay = DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
      );

      final index = days.indexWhere((d) => d == createdDay);
      if (index == -1) continue;

      bookingCounts[index]++;
      if (data['status'] == 'approved') {
        approvedCounts[index]++;
        earningsPerDay[index] += (data['price'] as num? ?? 0).toDouble();
      }
    }

    _last7Days = List.generate(7, (i) {
      final existing = i < _last7Days.length ? _last7Days[i] : null;
      return DailyMetric(
        day: days[i],
        bookingsCreated: bookingCounts[i],
        approvedCreated: approvedCounts[i],
        earnings: earningsPerDay[i],
        usersCreated: existing?.usersCreated ?? 0,
      );
    });
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
