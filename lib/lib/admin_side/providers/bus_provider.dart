import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/bus_model.dart';

class BusProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<BusModel> _buses = [];
  bool _isLoading = false;

  BusProvider() {
    _listenToBuses();
  }

  // Getters
  List<BusModel> get buses => _buses;
  bool get isLoading => _isLoading;

  void _listenToBuses() {
    _isLoading = true;
    notifyListeners();

    _subscription = _firestore
        .collection('buses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _buses = snapshot.docs.map((doc) {
              final data = doc.data();
              return BusModel.fromMap({'id': doc.id, ...data});
            }).toList();
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error loading buses: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Add a new bus
  Future<void> addBus({
    required String from,
    required String to,
    required DateTime departureAt,
    required double ticketPrice,
    required String driverName,
    required String numberPlate,
    required int totalSeats,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('buses').add({
        'from': from,
        'to': to,
        'departureAt': departureAt,
        'ticketPrice': ticketPrice,
        'driverName': driverName,
        'numberPlate': numberPlate,
        'totalSeats': totalSeats,
        'status': 'Active',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('Bus created: ${doc.id}');
    } catch (e) {
      debugPrint('Error adding bus: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update bus status
  Future<void> updateBusStatus(String busId, String newStatus) async {
    try {
      await _firestore.collection('buses').doc(busId).update({
        'status': newStatus,
      });
    } catch (e) {
      debugPrint('Error updating bus status: $e');
    }
  }

  // Delete a bus
  Future<void> deleteBus(String busId) async {
    try {
      await _firestore.collection('buses').doc(busId).delete();
    } catch (e) {
      debugPrint('Error deleting bus: $e');
    }
  }

  // Get active buses count
  int get activeBusesCount {
    return _buses.where((bus) => bus.status == 'Active').length;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
