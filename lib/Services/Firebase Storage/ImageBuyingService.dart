import 'package:cloud_firestore/cloud_firestore.dart';

class ImageBuyingService {

  //call this method on buy now button
  Future<void> updateImageStatusAndDetails(String imageId,
      String buyerId) async {
    await FirebaseFirestore.instance
        .collection("uploads")
        .doc(imageId)
        .update({
      "status" : "sold",
      "purchasedBy": buyerId,
      "purchasedAt" : FieldValue.serverTimestamp()
    });
  }

}