import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lamhti_app/Utils/Toast.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oAuthCredential);

      debugPrint("Signed in as: ${userCredential.user?.uid}");

      //As it only shows fullname for the first time when signing in so storing it as display name
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        final displayName = "${appleCredential.givenName ?? ""} ${appleCredential.familyName ?? ""}".trim();
        await userCredential.user?.updateDisplayName(displayName);
      }

      return userCredential.user;
    } catch (e) {
      debugPrint("Apple sign-in error: $e");
      Toast.toastMessage("Apple sign-in error: $e", Colors.red);
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }
}
