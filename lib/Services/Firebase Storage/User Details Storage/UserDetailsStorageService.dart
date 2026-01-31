import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:lamhti_app/Services/Seller Account Creation/SellerAccountCreationService.dart';

class UserDetailsStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SellerAccountCreationService _sellerService =
  SellerAccountCreationService();

  /// ✅ CALL THIS ONLY AFTER SIGN-UP (NOT SIGN-IN)
  /// Creates Stripe account ONLY if it doesn't exist
  Future<void> setupUserDetailsIfNeeded() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDocRef = _firestore.collection("users").doc(user.uid);
      final snapshot = await userDocRef.get();

      // ✅ If accountId already exists → DO NOTHING
      if (snapshot.exists &&
          snapshot.data()?["accountId"] != null &&
          snapshot.data()!["accountId"].toString().startsWith("acct_")) {
        debugPrint("Stripe account already exists. Skipping creation.");
        return;
      }

      // ✅ Create Stripe account ONCE
      final apiResponse = await _sellerService.createAccountId();
      final accountId = apiResponse?.accountId;

      if (accountId == null) {
        debugPrint("Stripe account creation failed.");
        return;
      }

      await userDocRef.set({
        "uid": user.uid,
        "email": user.email,
        "name": user.displayName,
        "accountId": accountId,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("Stripe account created & saved: $accountId");
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
      if (accountId == null || !accountId.startsWith("acct_")) {
        return null;
      }

      return accountId;
    } catch (e) {
      debugPrint("getUserAccountId error: $e");
      return null;
    }
  }
}
