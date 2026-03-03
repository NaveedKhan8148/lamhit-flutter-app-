import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:lamhti_app/Utils/Toast.dart';

class AccountDeletionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Main method to delete user account and all associated data
  Future<bool> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Toast.toastMessage("No user is currently signed in.", Colors.red);
        return false;
      }

      final uid = user.uid;

      // Step 1: Delete user's uploaded images from Storage
      await _deleteUserImages(uid);

      // Step 2: Delete user's upload documents from Firestore
      await _deleteUserUploads(uid);

      // Step 3: Delete user's purchase records
      await _deleteUserPurchases(uid);

      // Step 4: Delete user's Firestore document
      await _deleteUserDocument(uid);

      // Step 5: Delete Firebase Auth account
      await user.delete();

      debugPrint("Account deleted successfully for user: $uid");
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth error during account deletion: ${e.code} - ${e.message}");
      
      if (e.code == 'requires-recent-login') {
        Toast.toastMessage(
          "For security, please sign out and sign in again before deleting your account.",
          Colors.orange,
        );
      } else {
        Toast.toastMessage(
          "Failed to delete account: ${e.message}",
          Colors.red,
        );
      }
      return false;
    } catch (e) {
      debugPrint("Error during account deletion: $e");
      Toast.toastMessage(
        "An error occurred while deleting your account. Please try again.",
        Colors.red,
      );
      return false;
    }
  }

  /// Delete all images uploaded by the user from Firebase Storage
  Future<void> _deleteUserImages(String uid) async {
    try {
      final storageRef = _storage.ref().child("uploads/$uid");
      
      // List all files in the user's upload folder
      final listResult = await storageRef.listAll();
      
      // Delete each file
      for (var item in listResult.items) {
        try {
          await item.delete();
          debugPrint("Deleted image: ${item.fullPath}");
        } catch (e) {
          debugPrint("Failed to delete image ${item.fullPath}: $e");
        }
      }
      
      debugPrint("Deleted ${listResult.items.length} images for user $uid");
    } catch (e) {
      debugPrint("Error deleting user images: $e");
      // Continue with deletion even if image deletion fails
    }
  }

  /// Delete all upload documents created by the user from Firestore
  Future<void> _deleteUserUploads(String uid) async {
    try {
      final uploadsQuery = await _firestore
          .collection("uploads")
          .where("userId", isEqualTo: uid)
          .get();

      // Delete in batches (Firestore batch limit is 500)
      final batch = _firestore.batch();
      int count = 0;

      for (var doc in uploadsQuery.docs) {
        batch.delete(doc.reference);
        count++;
        
        // Commit batch if we reach 500 operations
        if (count >= 500) {
          await batch.commit();
          count = 0;
        }
      }

      // Commit remaining operations
      if (count > 0) {
        await batch.commit();
      }

      debugPrint("Deleted ${uploadsQuery.docs.length} upload documents for user $uid");
    } catch (e) {
      debugPrint("Error deleting user uploads: $e");
      // Continue with deletion even if this fails
    }
  }

  /// Delete user's purchase records from Firestore
  Future<void> _deleteUserPurchases(String uid) async {
    try {
      // Update uploads where this user was the purchaser
      final purchasedQuery = await _firestore
          .collection("uploads")
          .where("purchasedBy", isEqualTo: uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in purchasedQuery.docs) {
        // Remove purchaser information but keep the upload document
        batch.update(doc.reference, {
          "purchasedBy": "",
          "purchasedAt": null,
        });
      }

      if (purchasedQuery.docs.isNotEmpty) {
        await batch.commit();
      }

      debugPrint("Cleaned up ${purchasedQuery.docs.length} purchase records for user $uid");
    } catch (e) {
      debugPrint("Error cleaning up user purchases: $e");
      // Continue with deletion even if this fails
    }
  }

  /// Delete user's main document from Firestore
  Future<void> _deleteUserDocument(String uid) async {
    try {
      await _firestore.collection("users").doc(uid).delete();
      debugPrint("Deleted user document for user $uid");
    } catch (e) {
      debugPrint("Error deleting user document: $e");
      // Continue with deletion even if this fails
    }
  }

  /// Re-authenticate user before deletion (required for sensitive operations)
  /// This method can be called if the initial deletion fails with 'requires-recent-login'
  Future<bool> reauthenticateUser({
    String? email,
    String? password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final providerId = user.providerData.first.providerId;

      if (providerId == "password" && email != null && password != null) {
        // Re-authenticate with email/password
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      } else {
        // For Google/Apple, user needs to sign out and sign in again
        Toast.toastMessage(
          "Please sign out and sign in again before deleting your account.",
          Colors.orange,
        );
        return false;
      }
    } catch (e) {
      debugPrint("Re-authentication error: $e");
      Toast.toastMessage("Re-authentication failed. Please try again.", Colors.red);
      return false;
    }
  }
}
