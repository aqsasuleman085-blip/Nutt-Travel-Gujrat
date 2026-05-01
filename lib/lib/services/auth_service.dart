import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthResult {
  final bool success;
  final String? message;

  const AuthResult({required this.success, this.message});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AuthResult> signUpUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'user',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      await _auth.signOut();
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      final message = e.code == 'email-already-in-use'
          ? 'Email already in use'
          : 'Signup failed. Try again.';
      return AuthResult(success: false, message: message);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Signup failed. Try again.',
      );
    }
  }

  Future<AuthResult> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (doc.exists && doc.data()?['role'] == 'user') {
        return const AuthResult(success: true);
      }

      await _auth.signOut();
      return const AuthResult(
        success: false,
        message: 'Please use admin login screen',
      );
    } on FirebaseAuthException catch (e) {
      final message = e.code == 'user-not-found' || e.code == 'wrong-password'
          ? 'Invalid email or password'
          : 'Login failed. Try again.';
      return AuthResult(success: false, message: message);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Login failed. Try again.',
      );
    }
  }

  Future<AuthResult> updateUserProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email != email) {
        await currentUser.updateEmail(email);
      }

      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'email': email,
      });

      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      final message = e.code == 'requires-recent-login'
          ? 'Please log in again to update email.'
          : 'Unable to update profile.';
      return AuthResult(success: false, message: message);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to update profile.',
      );
    }
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return const AuthResult(success: false, message: 'Not logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      final message = e.code == 'wrong-password'
          ? 'Current password is incorrect'
          : 'Unable to change password.';
      return AuthResult(success: false, message: message);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to change password.',
      );
    }
  }
}
