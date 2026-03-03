import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lamhti_app/Utils/Toast.dart';

class EmailAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign up with email and password
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password is too weak. Please use a stronger password.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'Sign up failed: ${e.message}';
      }
      debugPrint("Sign up error: ${e.code} - ${e.message}");
      Toast.toastMessage(errorMessage, Colors.red);
      return null;
    } catch (e) {
      debugPrint("Sign up error: $e");
      Toast.toastMessage("Something went wrong during sign up.", Colors.red);
      return null;
    }
  }

  /// Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = 'Sign in failed: ${e.message}';
      }
      debugPrint("Sign in error: ${e.code} - ${e.message}");
      Toast.toastMessage(errorMessage, Colors.red);
      return null;
    } catch (e) {
      debugPrint("Sign in error: $e");
      Toast.toastMessage("Something went wrong during sign in.", Colors.red);
      return null;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      Toast.toastMessage(
        "Password reset email sent. Please check your inbox.",
        Colors.green,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'Failed to send reset email: ${e.message}';
      }
      debugPrint("Password reset error: ${e.code} - ${e.message}");
      Toast.toastMessage(errorMessage, Colors.red);
      return false;
    } catch (e) {
      debugPrint("Password reset error: $e");
      Toast.toastMessage("Something went wrong. Please try again.", Colors.red);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
