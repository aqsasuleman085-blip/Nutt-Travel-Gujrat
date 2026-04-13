import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bus_model.dart';
import '../services/storage_service.dart';

class BusProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  late final StorageService _storageService;
  
  List<BusModel> _buses = [];
  bool _isLoading = false;
  
  BusProvider(this._prefs) {
    _storageService = StorageService(_prefs);
    _loadBuses();
  }
  
  // Getters
  List<BusModel> get buses => _buses;
  bool get isLoading => _isLoading;
  
  // Load buses from storage
  void _loadBuses() {
    final busesData = _storageService.getBuses();
    _buses = busesData.map((busData) => BusModel.fromMap(busData)).toList();
    notifyListeners();
  }
  
  // Save buses to storage
  Future<void> _saveBuses() async {
    final busesData = _buses.map((bus) => bus.toMap()).toList();
    await _storageService.saveBuses(busesData);
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
      final newBus = BusModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        from: from,
        to: to,
        departureTime: departureTime,
        ticketPrice: ticketPrice,
        driverName: driverName,
        numberPlate: numberPlate,
      );
      
      _buses.add(newBus);
      await _saveBuses();
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
      final busIndex = _buses.indexWhere((bus) => bus.id == busId);
      if (busIndex != -1) {
        _buses[busIndex] = BusModel(
          id: _buses[busIndex].id,
          from: _buses[busIndex].from,
          to: _buses[busIndex].to,
          departureTime: _buses[busIndex].departureTime,
          ticketPrice: _buses[busIndex].ticketPrice,
          driverName: _buses[busIndex].driverName,
          numberPlate: _buses[busIndex].numberPlate,
          status: newStatus,
          createdAt: _buses[busIndex].createdAt,
        );
        
        await _saveBuses();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating bus status: $e');
    }
  }
  
  // Delete a bus
  Future<void> deleteBus(String busId) async {
    try {
      _buses.removeWhere((bus) => bus.id == busId);
      await _saveBuses();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting bus: $e');
    }
  }
  
  // Get active buses count
  int get activeBusesCount {
    return _buses.where((bus) => bus.status == 'Active').length;
  }
}