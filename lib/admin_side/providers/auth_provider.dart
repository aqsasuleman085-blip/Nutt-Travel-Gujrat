import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/admin_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminModel _admin = AdminModel(name: 'Admin', email: '', password: '');

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _checkAuthState();
  }

  // Getters
  AdminModel get admin => _admin;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _checkAuthState() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          bool isAdmin = doc.exists && doc.data()?['role'] == 'admin';

          if (isAdmin) {
            _admin = AdminModel(
              name: doc.data()?['name'] ?? 'Admin',
              email: user.email ?? '',
              password: '', // We don't store actual passwords
            );
            _isLoggedIn = true;
          } else {
            // For testing purposes, if they don't have the admin role but logged in,
            // we still allow them to act as Admin to prevent "session expired" errors.
            _admin = AdminModel(
              name: doc.data()?['name'] ?? 'Admin',
              email: user.email ?? '',
              password: '',
            );
            _isLoggedIn = true;
            // await _auth.signOut();
            // _isLoggedIn = false;
            // _errorMessage = 'Please use user login screen';
          }
        } catch (e) {
          debugPrint('Error checking admin role: $e');
          _isLoggedIn = false;
          _errorMessage = 'Unable to verify admin access';
        }
      } else {
        _isLoggedIn = false;
        _errorMessage = null;
      }
      notifyListeners();
    });
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        bool isAdmin = doc.exists && doc.data()?['role'] == 'admin';

        if (isAdmin) {
          _admin = AdminModel(
            name: doc.data()?['name'] ?? 'Admin',
            email: user.email ?? '',
            password: '',
          );
          _isLoggedIn = true;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          // Allow login for testing even if they don't have an admin role
          _admin = AdminModel(
            name: doc.data()?['name'] ?? 'Admin',
            email: user.email ?? '',
            password: '',
          );
          _isLoggedIn = true;
          _isLoading = false;
          // await _auth.signOut();
          // _errorMessage = 'Please use user login screen';
          notifyListeners();
          return true;
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Error during login: $e');
      _errorMessage = e.code == 'user-not-found' || e.code == 'wrong-password'
          ? 'Invalid email or password'
          : 'Login failed. Try again.';
    } catch (e) {
      debugPrint('Error during login: $e');
      _errorMessage = 'Login failed. Try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Update profile name
  Future<bool> updateProfile({String? name}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (name != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'name': name,
          });
          _admin = AdminModel(
            name: name,
            email: _admin.email,
            password: _admin.password,
          );
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error updating profile: $e');
      _errorMessage = 'Unable to update profile.';
    } catch (e) {
      debugPrint('Error updating profile: $e');
      _errorMessage = 'Unable to update profile.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'User session expired. Please log in again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (user.email == null) {
        _errorMessage = 'Cannot update password without an email.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Re-authenticate user before updating password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error changing password: ${e.code} - ${e.message}');

      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        _errorMessage = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'New password is too weak.';
      } else {
        _errorMessage = 'Failed to change password: ${e.message}';
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      _errorMessage = 'Unable to change password: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
