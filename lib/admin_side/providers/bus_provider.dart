import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';

class BusProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BusModel> _buses = [];
  bool _isLoading = false;

  BusProvider() {
    _loadBuses();
  }

  // Getters
  List<BusModel> get buses => _buses;
  bool get isLoading => _isLoading;

  // Listen to buses from Firestore
  void _loadBuses() {
    _firestore.collection('buses').snapshots().listen((snapshot) {
      _buses = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // ensure ID matches the doc id
        return BusModel.fromMap(data);
      }).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error listening to buses: $error');
    });
  }

  // Add a new bus
  Future<void> addBus({
    required String from,
    required String to,
    required String departureTime,
    required double ticketPrice,
    required String driverName,
    required String numberPlate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newBusData = {
        'from': from,
        'to': to,
        'departureTime': departureTime,
        'ticketPrice': ticketPrice,
        'driverName': driverName,
        'numberPlate': numberPlate,
        'status': 'Active', // Default status
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('buses').add(newBusData);
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
}