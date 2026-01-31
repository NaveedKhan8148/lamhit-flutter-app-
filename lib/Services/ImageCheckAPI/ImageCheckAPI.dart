import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:lamhti_app/API%20Models/ImageCheckAPIModel.dart';

class ImageCheckAPI {
  Future<ImageCheckAPIModel?> getImageCheckAPIResponse(
    File imageFile,
    String userId,
  ) async {
    final apiUrl = Uri.parse(
      "https://lamhti-image-check-api.hf.space/check_image/",
    );

    var request = http.MultipartRequest("POST", apiUrl);

    request.fields["userId"] = userId;

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        imageFile.path,
        filename: path.basename(imageFile.path),
      ),
    );

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonData = jsonDecode(respStr);

        return ImageCheckAPIModel.fromJson(jsonData);
      } else {
        debugPrint("Status code not 200");
        return null;
      }
    } catch (e) {
      debugPrint("Exception in getting response from API: " + e.toString());
    }
  }
}
