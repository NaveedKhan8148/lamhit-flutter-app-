import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserDetailsStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Setup user details after sign-up
  /// Creates basic user record in Firestore (no Stripe account creation)
  Future<void> setupUserDetailsIfNeeded() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDocRef = _firestore.collection("users").doc(user.uid);
      final snapshot = await userDocRef.get();

      // ✅ If user record already exists → DO NOTHING
      if (snapshot.exists) {
        debugPrint("User details already exist. Skipping setup.");
        return;
      }

      // ✅ Create basic user record (no Stripe)
      await userDocRef.set({
        "uid": user.uid,
        "email": user.email,
        "name": user.displayName,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("User details created: ${user.uid}");
    } catch (e) {
      debugPrint("setupUserDetailsIfNeeded error: $e");
    }
  }

  /// ✅ SAFE READ — NEVER CREATES ACCOUNT
  Future<String?> getUserAccountId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc =
      await _firestore.collection("users").doc(user.uid).get();

      if (!doc.exists) return null;

      final accountId = doc.data()?["accountId"] as String?;
      return accountId;
    } catch (e) {
      debugPrint("getUserAccountId error: $e");
      return null;
    }
  }
}
