import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/User%20Details%20Storage/UserDetailsStorageService.dart';

class ImageUploadService {
  final userDetailsStorageService = UserDetailsStorageService();

  Future<void> uploadImageAndData({
    required File imageFile,
    required String title,
    required String description,
    required String price,
    required String imageSize,
    required String category,
    required String location,
    required String email,
  }) async {
    try {
      debugPrint('[ImageUpload] Starting upload process...');

      if (!imageFile.existsSync()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }
      if (title.trim().isEmpty) throw Exception('Title cannot be empty');
      if (description.trim().isEmpty) throw Exception('Description cannot be empty');
      if (price.trim().isEmpty) throw Exception('Price cannot be empty');

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated. Please sign in again.');
      }
      debugPrint('[ImageUpload] User UID: $uid');

      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("uploads/$uid/$fileName.jpg");
      debugPrint('[ImageUpload] Storage ref: uploads/$uid/$fileName.jpg');

      final accountId = await userDetailsStorageService.getUserAccountId();
      debugPrint('[ImageUpload] Account ID: ${accountId ?? "null - using dummyId"}');

      debugPrint('[ImageUpload] Uploading image to Firebase Storage...');
      final uploadTask = storageRef.putFile(imageFile);
      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      debugPrint('[ImageUpload] Upload complete. URL: $downloadUrl');

      debugPrint('[ImageUpload] Saving metadata to Firestore...');
      await FirebaseFirestore.instance.collection("uploads").add({
        'email': email,
        'isSold': false,
        'lastSoldTime': DateTime.now().toIso8601String(),
        'imageUrl': downloadUrl,
        'title': title,
        'price': double.tryParse(price),
        'imageSize': imageSize,
        'location': location,
        'category': category,
        'description': description,
        'userId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'available',
        'accountId': accountId ?? 'dummyId',
        'purchasedBy': '',
        'purchasedAt': null,
      });
      debugPrint('[ImageUpload] Metadata saved successfully!');
    } on FirebaseException catch (e) {
      debugPrint('[ImageUpload] Firebase error: ${e.code} - ${e.message}');
      throw Exception('Upload failed: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('[ImageUpload] Unexpected error: $e');
      throw Exception('Upload failed: $e');
    }
  }

  Future<String?> getAccountIdFromUpload(String uploadDocId) async {
    final doc = await FirebaseFirestore.instance
        .collection("uploads")
        .doc(uploadDocId)
        .get();
    if (!doc.exists) return null;
    return doc.data()?['accountId'];
  }

  Future<void> markItemSoldMinimal({required String documentId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-signed-in',
        message: 'Sign in required.',
      );
    }
    await FirebaseFirestore.instance
        .collection('uploads')
        .doc(documentId)
        .update({
      'isSold': true,
      'lastSoldTime': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markItemSoldAfterPayment({
    required String documentId,
    required String paymentMethod,
    String? transactionId,
    String? productId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-signed-in',
        message: 'Sign in required.',
      );
    }
    await FirebaseFirestore.instance
        .collection('uploads')
        .doc(documentId)
        .update({
      'status': 'sold',
      'isSold': true,
      'lastSoldTime': DateTime.now().toIso8601String(),
      'purchasedBy': user.uid,
      'purchasedAt': FieldValue.serverTimestamp(),
      'purchasePaymentMethod': paymentMethod,
      'purchaseTransactionId': transactionId ?? '',
      'purchaseProductId': productId ?? '',
    });
  }

  Future<int> purgeMyExpiredUploads({
    Duration unsoldGrace = const Duration(minutes: 5),
    Duration soldGrace = const Duration(minutes: 10),
    int pageSize = 200,
    void Function(String msg)? logFn,
  }) async {
    final log = logFn ?? (m) => debugPrint(m);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-signed-in',
        message: 'Sign in required.',
      );
    }

    final now = DateTime.now();
    final unsoldDeadline = now.subtract(unsoldGrace);
    final soldDeadline = now.subtract(soldGrace);
    final uploads = FirebaseFirestore.instance.collection('uploads');
    int totalDeleted = 0;

    Future<int> deleteDocsAndImages(
        List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
      if (docs.isEmpty) return 0;
      int deleted = 0;
      const maxBatch = 500;
      for (int i = 0; i < docs.length; i += maxBatch) {
        final slice = docs.sublist(i, (i + maxBatch).clamp(0, docs.length));
        final batch = FirebaseFirestore.instance.batch();
        for (final d in slice) {
          final imageUrl = (d.data()['imageUrl'] ?? '') as String;
          if (imageUrl.isNotEmpty) {
            try {
              await FirebaseStorage.instance.refFromURL(imageUrl).delete();
            } catch (e) {
              log('Storage delete failed for ${d.id}: $e');
            }
          }
          batch.delete(d.reference);
        }
        await batch.commit();
        deleted += slice.length;
      }
      return deleted;
    }

    // Purge unsold
    Query<Map<String, dynamic>> q1 = uploads
        .where('userId', isEqualTo: user.uid)
        .where('isSold', isEqualTo: false)
        .where('lastSoldTime',
            isLessThanOrEqualTo: Timestamp.fromDate(unsoldDeadline))
        .orderBy('lastSoldTime')
        .limit(pageSize);

    while (true) {
      final snap = await q1.get();
      if (snap.docs.isEmpty) break;
      totalDeleted += await deleteDocsAndImages(snap.docs);
      log('Deleted ${snap.docs.length} UNSOLD items...');
      q1 = q1.startAfterDocument(snap.docs.last);
    }

    // Purge sold
    Query<Map<String, dynamic>> q2 = uploads
        .where('userId', isEqualTo: user.uid)
        .where('isSold', isEqualTo: true)
        .where('lastSoldTime',
            isLessThanOrEqualTo: Timestamp.fromDate(soldDeadline))
        .orderBy('lastSoldTime')
        .limit(pageSize);

    while (true) {
      final snap = await q2.get();
      if (snap.docs.isEmpty) break;
      totalDeleted += await deleteDocsAndImages(snap.docs);
      log('Deleted ${snap.docs.length} SOLD items...');
      q2 = q2.startAfterDocument(snap.docs.last);
    }

    log('Purge complete. Total deleted: $totalDeleted');
    return totalDeleted;
  }
}