import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ImageDeleteService{

  Future<void> deleteUploadedImage(String imageUrl, String documentId) async{
    try{
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);

      await ref.delete();

      await FirebaseFirestore.instance.collection("uploads").doc(documentId).delete();

    }catch(e){
      debugPrint(e.toString());
      throw e;
    }
  }

}