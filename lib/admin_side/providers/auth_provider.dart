import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/admin_model.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  late final StorageService _storageService;
  
  AdminModel _admin = AdminModel(
    name: AppConstants.defaultAdminName,
    email: AppConstants.defaultAdminEmail,
    password: 'admin123',
  );
  
  bool _isLoggedIn = true;
  bool _isLoading = false;
  
  AuthProvider(this._prefs) {
    _storageService = StorageService(_prefs);
    _loadAdminProfile();
  }
  
  // Getters
  AdminModel get admin => _admin;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  
  // Load admin profile from storage
  void _loadAdminProfile() {
    final adminData = _storageService.getAdminProfile();
    if (adminData.isNotEmpty) {
      _admin = AdminModel.fromMap(adminData);
    } else {
      // Save default admin profile
      _saveAdminProfile();
    }
    notifyListeners();
  }
  
  // Save admin profile to storage
  Future<void> _saveAdminProfile() async {
    await _storageService.saveAdminProfile(_admin.toMap());
  }
  
  // Update admin profile
  Future<void> updateProfile({String? name, String? email}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (name != null) _admin = AdminModel(name: name, email: _admin.email, password: _admin.password);
      if (email != null) _admin = AdminModel(name: _admin.name, email: email, password: _admin.password);
      
      await _saveAdminProfile();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (_admin.password != currentPassword) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      _admin = AdminModel(
        name: _admin.name,
        email: _admin.email,
        password: newPassword,
      );
      
      await _saveAdminProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error changing password: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    _isLoggedIn = false;
    notifyListeners();
  }
  
  // Login (simplified for demo)
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (_admin.email == email && _admin.password == password) {
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error during login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}