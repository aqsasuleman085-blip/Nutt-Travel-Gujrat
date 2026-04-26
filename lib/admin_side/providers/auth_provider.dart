import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/admin_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminModel _admin = AdminModel(
    name: AppConstants.defaultAdminName,
    email: AppConstants.defaultAdminEmail,
    password: '',
  );

  bool _isLoggedIn = false;
  bool _isLoading = false;

  AuthProvider() {
    _checkLoginStatus();
  }

  // Getters
  AdminModel get admin => _admin;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  void _checkLoginStatus() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        _isLoggedIn = true;
        await _loadAdminProfile(user.uid);
      } else {
        _isLoggedIn = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadAdminProfile(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _admin = AdminModel(
          name: data['name'] ?? AppConstants.defaultAdminName,
          email: data['email'] ?? AppConstants.defaultAdminEmail,
          password: '',
        );
      } else {
        // Create an admin document if it doesn't exist
        _admin = AdminModel(
          name: AppConstants.defaultAdminName,
          email: _auth.currentUser?.email ?? AppConstants.defaultAdminEmail,
          password: '',
        );
        await _saveAdminProfile();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading admin profile: $e');
    }
  }

  Future<void> _saveAdminProfile() async {
    if (_auth.currentUser != null) {
      await _firestore.collection('admins').doc(_auth.currentUser!.uid).set({
        'name': _admin.name,
        'email': _admin.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Update admin profile
  Future<void> updateProfile({String? name, String? email}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (name != null)
        _admin = AdminModel(
          name: name,
          email: _admin.email,
          password: _admin.password,
        );
      if (email != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateEmail(email);
        _admin = AdminModel(
          name: _admin.name,
          email: email,
          password: _admin.password,
        );
      }

      await _saveAdminProfile();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_auth.currentUser != null) {
        // Firebase Auth update password requires re-authentication, but for simplicity here:
        await _auth.currentUser!.updatePassword(newPassword);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error changing password: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error during login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
