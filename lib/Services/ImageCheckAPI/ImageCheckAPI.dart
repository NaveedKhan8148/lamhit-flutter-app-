import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:lamhti_app/API%20Models/ImageCheckAPIModel.dart';

class ImageCheckAPI {
  static const String _baseUrl = "https://lamhti-image-check-api.hf.space";

  /// Polls the HF Space until it responds with non-HTML (i.e. FastAPI is live).
  /// HF free-tier cold start can take up to 2 minutes. Reports progress via [onStatusUpdate].
  Future<bool> _waitForSpaceReady({
    void Function(String message)? onStatusUpdate,
  }) async {
    const maxAttempts = 8; // 8 × 15s = up to 2 minutes
    const pollInterval = Duration(seconds: 15);

    debugPrint('[ImageCheckAPI] Waiting for HF Space to wake up...');

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final remaining = maxAttempts - attempt;
      onStatusUpdate?.call(
        'Starting image server...\nAttempt $attempt of $maxAttempts\n(${remaining * 15}s remaining)',
      );

      try {
        debugPrint('[ImageCheckAPI] Poll $attempt/$maxAttempts...');

        final response = await http
            .get(Uri.parse("$_baseUrl/"))
            .timeout(const Duration(seconds: 20));

        final body = response.body.trim();
        final isHtml = body.startsWith('<!DOCTYPE') ||
            body.startsWith('<html') ||
            body.startsWith('<HTML');

        debugPrint(
            '[ImageCheckAPI] Poll status: ${response.statusCode}, isHtml: $isHtml');

        if (response.statusCode == 200 && !isHtml) {
          debugPrint('[ImageCheckAPI] Space is ready after $attempt polls!');
          return true; // Space is live
        }

        // Still returning HTML startup page — keep waiting
      } catch (e) {
        debugPrint('[ImageCheckAPI] Poll $attempt error: $e');
      }

      if (attempt < maxAttempts) {
        debugPrint('[ImageCheckAPI] Space not ready, waiting 15s...');
        await Future.delayed(pollInterval);
      }
    }

    // Even if polling timed out, attempt the request anyway
    debugPrint('[ImageCheckAPI] Max polls reached, attempting request anyway...');
    return false;
  }

  Future<ImageCheckAPIModel?> getImageCheckAPIResponse(
    File imageFile,
    String userId, {
    void Function(String message)? onStatusUpdate,
  }) async {
    debugPrint('[ImageCheckAPI] Starting image verification...');
    debugPrint('[ImageCheckAPI] File: ${imageFile.path}');
    debugPrint('[ImageCheckAPI] Exists: ${imageFile.existsSync()}');
    debugPrint('[ImageCheckAPI] UserID: $userId');

    if (!imageFile.existsSync()) {
      throw Exception('Selected image file no longer exists. Please pick the image again.');
    }

    // Wait until the space is fully awake
    await _waitForSpaceReady(onStatusUpdate: onStatusUpdate);

    // Now send the actual request — retry up to 2 times
    const maxUploadAttempts = 2;
    const retryDelay = Duration(seconds: 15);

    for (int attempt = 1; attempt <= maxUploadAttempts; attempt++) {
      debugPrint('[ImageCheckAPI] Upload attempt $attempt/$maxUploadAttempts...');
      onStatusUpdate?.call('Analyzing image, please wait...\n(Attempt $attempt of $maxUploadAttempts)');

      try {
        return await _sendRequest(imageFile, userId);
      } on _SpaceNotReadyException {
        // Space root was ready but /check_image still returned HTML
        debugPrint('[ImageCheckAPI] check_image returned HTML on attempt $attempt, waiting...');
        if (attempt < maxUploadAttempts) {
          onStatusUpdate?.call('Server still starting up, retrying...');
          await Future.delayed(retryDelay);
        }
      } on TimeoutException {
        debugPrint('[ImageCheckAPI] Timeout on attempt $attempt');
        if (attempt < maxUploadAttempts) {
          onStatusUpdate?.call('Request timed out, retrying...');
          await Future.delayed(retryDelay);
        }
      } on SocketException catch (e) {
        debugPrint('[ImageCheckAPI] Network error: $e');
        throw Exception(
            'No internet connection. Please check your network and try again.');
      }
      // Any other exception propagates immediately (e.g. parse error)
    }

    throw Exception(
        'The image verification server is unavailable right now. '
        'Please try again in a few minutes.');
  }

  Future<ImageCheckAPIModel> _sendRequest(File imageFile, String userId) async {
    final apiUrl = Uri.parse("$_baseUrl/check_image/");

    final request = http.MultipartRequest("POST", apiUrl);
    request.fields["userId"] = userId;
    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        imageFile.path,
        filename: path.basename(imageFile.path),
      ),
    );

    debugPrint('[ImageCheckAPI] POST → $apiUrl');

    final streamed = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw TimeoutException('Upload request timed out after 60 seconds'),
    );

    final statusCode = streamed.statusCode;
    final body = await streamed.stream.bytesToString();

    debugPrint('[ImageCheckAPI] Response $statusCode: $body');

    // Detect HTML — space not fully ready yet
    final trimmed = body.trim();
    if (trimmed.startsWith('<!DOCTYPE') ||
        trimmed.startsWith('<html') ||
        trimmed.startsWith('<HTML')) {
      throw _SpaceNotReadyException();
    }

    if (statusCode == 200) {
      try {
        final json = jsonDecode(body);
        debugPrint('[ImageCheckAPI] Parsed: status=${json['status']}');
        return ImageCheckAPIModel.fromJson(json);
      } catch (e) {
        throw Exception('Could not parse server response: $e');
      }
    } else {
      throw Exception(
          'Server returned error $statusCode. Please try again.');
    }
  }
}

/// Thrown when the HF Space endpoint returns HTML instead of JSON,
/// indicating the space is still booting. Never shown to the user directly.
class _SpaceNotReadyException implements Exception {}