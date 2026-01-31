import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageFetchService {
  // Stream for real-time updates
  Stream<QuerySnapshot> getAllImages() {
    return FirebaseFirestore.instance
        .collection("uploads")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  // Future for one-time data fetch
  Future<QuerySnapshot> getFeaturedImages() {
    return FirebaseFirestore.instance
        .collection("uploads")
        .where("status", isEqualTo: "available")
        .orderBy("timestamp", descending: true)
        .limit(6)
        .get();
  }

  Future<QuerySnapshot> getAllAvailableImagesFuture() {
    return FirebaseFirestore.instance
        .collection("uploads")
        .where("status", isEqualTo: "available")
        .orderBy("timestamp", descending: true)
        .get();
  }

  // Future<void> deleteUnsoldUploads() async {
  //   try {
  //     final uploadsRef = FirebaseFirestore.instance.collection('uploads');
  //     final querySnapshot = await uploadsRef.get();

  //     final now = DateTime.now();

  //     for (var doc in querySnapshot.docs) {
  //       final data = doc.data();

  //       final bool isSold = data['isSold'] ?? false;
  //       final String? imageUrl = data['imageUrl'];
  //       final String? lastSoldTimeStr = data['lastSoldTime'];
  //       if (lastSoldTimeStr == null) continue;

  //       final DateTime? lastSoldTime = DateTime.tryParse(lastSoldTimeStr);
  //       if (lastSoldTime == null) continue;

  //       final difference = now.difference(lastSoldTime).inMinutes;

  //       bool shouldDelete = false;
  //       int timeLeft = 0;

  //       if (!isSold) {
  //         timeLeft = 10 - difference;
  //         if (difference >= 10) {
  //           shouldDelete = true;
  //         }
  //       } else {
  //         timeLeft = 20 - difference;
  //         if (difference >= 20) {
  //           shouldDelete = true;
  //         }
  //       }

  //       // 🔹 Log remaining time before deletion
  //       if (!shouldDelete) {
  //         log(
  //           '⏳ ${doc.id} | isSold: $isSold | Time left for delete: ${timeLeft > 0 ? timeLeft : 0} minutes',
  //         );
  //       }

  //       if (shouldDelete) {
  //         await uploadsRef.doc(doc.id).delete();

  //         if (imageUrl != null && imageUrl.isNotEmpty) {
  //           try {
  //             final ref = FirebaseStorage.instance.refFromURL(imageUrl);
  //             await ref.delete();
  //           } catch (e) {
  //             log('⚠️ Error deleting image: $e');
  //           }
  //         }

  //         log(
  //           '🗑️ Deleted: ${doc.id} (isSold: $isSold, diff: $difference min)',
  //         );
  //       }
  //     }

  //     log('✅ Cleanup completed successfully.');
  //   } catch (e) {
  //     log('❌ Error deleting uploads: $e');
  //   }
  // }

  DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  String _fmtLeft(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    return '${days}d ${hours}h ${mins}m';
  }

  Future<void> deleteUnsoldUploads() async {
    try {
      final uploadsRef = FirebaseFirestore.instance.collection('uploads');
      final querySnapshot = await uploadsRef.get();

      final now = DateTime.now();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        final bool isSold = (data['isSold'] as bool?) ?? false;
        final String? imageUrl = data['imageUrl'] as String?;

        // lastSoldTime can be String ISO, Timestamp, or millis
        final DateTime? lastSoldTime = _toDateTime(data['lastSoldTime']);
        if (lastSoldTime == null) {
          log('⏭️ Skipped ${doc.id}: lastSoldTime is null/invalid');
          continue;
        }

        // Expiry: unsold -> 3 days, sold -> 14 days (from lastSoldTime)
        final expiry = lastSoldTime.add(Duration(days: isSold ? 14 : 3));

        if (now.isAfter(expiry)) {
          // Delete Firestore document
          await uploadsRef.doc(doc.id).delete();

          // Delete image from Storage
          if (imageUrl != null && imageUrl.isNotEmpty) {
            try {
              final ref = FirebaseStorage.instance.refFromURL(imageUrl);
              await ref.delete();
            } catch (e) {
              log('⚠️ Error deleting image for ${doc.id}: $e');
            }
          }

          final diffMins = now.difference(lastSoldTime).inMinutes;
          log(
            '🗑️ Deleted ${doc.id} (isSold: $isSold, since lastSoldTime: ${diffMins}m, expired at: $expiry)',
          );
        } else {
          final left = expiry.difference(now);
          log(
            '⏳ ${doc.id} (isSold: $isSold) — time left to delete: ${_fmtLeft(left)} (deletes on: $expiry)',
          );
        }
      }

      log('✅ Cleanup completed successfully.');
    } catch (e) {
      log('❌ Error deleting uploads: $e');
    }
  }

  Future<QuerySnapshot> getAllAvailableImagesWithPagination({
    DocumentSnapshot? lastDoc,
    int limit = 10,
  }) async {
    Query query = FirebaseFirestore.instance
        .collection("uploads")
        .where("status", isEqualTo: "available")
        .orderBy("timestamp", descending: true)
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.get();
  }

  Future<QuerySnapshot> getUserAvaiableUplaods(String userId) {
    return FirebaseFirestore.instance
        .collection("uploads")
        .where("userId", isEqualTo: userId)
        .where("status", isEqualTo: "available")
        .orderBy("timestamp", descending: true)
        .get();
  }

  //method for my purchases screen
  Future<QuerySnapshot> getUserPurchases(String buyerId) {
    return FirebaseFirestore.instance
        .collection("uploads")
        .where("purchasedBy", isEqualTo: buyerId)
        .where("status", isEqualTo: "sold")
        .orderBy("purchasedAt", descending: true)
        .get();
  }
}
