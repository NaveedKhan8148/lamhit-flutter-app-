import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lamhti_app/Utils/Toast.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint("Google sign-in cancelled or failed.");
        Toast.toastMessage("Google sign-in cancelled or failed. Account not created.", Colors.red);
        return null;
      }; // Cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      Toast.toastMessage("Google sign-in error: $e", Colors.red);
      return null;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
