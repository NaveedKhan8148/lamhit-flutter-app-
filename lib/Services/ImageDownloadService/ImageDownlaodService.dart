
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lamhti_app/Utils/Toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageDownloadService{

  Future<void> downloadImageToPhone(String imageUrl, String filename, BuildContext context) async{
    final dio = Dio();

    try{
      if(Platform.isAndroid && await Permission.storage.request().isDenied){
        Toast.toastMessage("Storage permission denied", Colors.red);
        return;
      }

      Directory? downloadDir;

      if(Platform.isAndroid){
        downloadDir = Directory("/storage/emulated/0/Download");
      } else if(Platform.isIOS){
        downloadDir = await getApplicationDocumentsDirectory();
      }

      String filePath = "${downloadDir!.path}/$filename";

      await dio.download(
          imageUrl,
          filePath,
        onReceiveProgress: (received, total){
            if(total != -1){
              Toast.toastMessage("Downloading: ${(received / total*100).toStringAsFixed(0)}", Colors.black);
            }
        }
      );

      Toast.toastMessage("Image downloaded to $filePath", Colors.black);

    } catch(e){
      Toast.toastMessage("Download failed $e", Colors.red);
    }

  }

}