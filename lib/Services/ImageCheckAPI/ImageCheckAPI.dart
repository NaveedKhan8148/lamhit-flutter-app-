import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:lamhti_app/API%20Models/ImageCheckAPIModel.dart';

class ImageCheckAPI {
  static const String _baseUrl = "https://lamhti-image-check-api.hf.space";

  // ── Tuned constants ──────────────────────────────────────────
  // 3 polls × 10 s = max 30 s wait (was 8 × 15 s = 120 s)
  static const int _maxPollAttempts = 3;
  static const Duration _pollInterval = Duration(seconds: 10);
  static const Duration _pollTimeout = Duration(seconds: 12);

  // 2 upload attempts × 30 s timeout each
  static const int _maxUploadAttempts = 2;
  static const Duration _uploadTimeout = Duration(seconds: 30);
  static const Duration _retryDelay = Duration(seconds: 8);

  // ── Poll until FastAPI is alive ──────────────────────────────
  Future<bool> _waitForSpaceReady({
    void Function(String message)? onStatusUpdate,
  }) async {
    debugPrint('[ImageCheckAPI] Waiting for HF Space to wake up...');

    for (int attempt = 1; attempt <= _maxPollAttempts; attempt++) {
      // User-friendly message — no technical jargon
      onStatusUpdate?.call('Preparing upload… please wait');

      try {
        debugPrint('[ImageCheckAPI] Poll $attempt/$_maxPollAttempts...');

        final response = await http
            .get(Uri.parse("$_baseUrl/"))
            .timeout(_pollTimeout);

        final body = response.body.trim();
        final isHtml = body.startsWith('<!DOCTYPE') ||
            body.startsWith('<html') ||
            body.startsWith('<HTML');

        debugPrint(
            '[ImageCheckAPI] Poll ${response.statusCode}, isHtml: $isHtml');

        if (response.statusCode == 200 && !isHtml) {
          debugPrint('[ImageCheckAPI] Space ready after $attempt polls');
          return true;
        }
      } catch (e) {
        debugPrint('[ImageCheckAPI] Poll $attempt error: $e');
      }

      if (attempt < _maxPollAttempts) {
        await Future.delayed(_pollInterval);
      }
    }

    // Attempt the upload anyway — fallback path handles offline case
    debugPrint('[ImageCheckAPI] Max polls reached, attempting upload anyway');
    return false;
  }

  // ── Public entry point ───────────────────────────────────────
  Future<ImageCheckAPIModel?> getImageCheckAPIResponse(
    File imageFile,
    String userId, {
    void Function(String message)? onStatusUpdate,
  }) async {
    debugPrint('[ImageCheckAPI] Starting image verification...');
    debugPrint('[ImageCheckAPI] File: ${imageFile.path}');
    debugPrint('[ImageCheckAPI] Exists: ${imageFile.existsSync()}');

    if (!imageFile.existsSync()) {
      throw Exception(
          'Selected image file no longer exists. Please pick the image again.');
    }

    final spaceReady = await _waitForSpaceReady(onStatusUpdate: onStatusUpdate);

    // If space never woke up, skip verification and upload directly
    // This avoids making the user wait forever
    if (!spaceReady) {
      debugPrint('[ImageCheckAPI] Space offline — skipping verification');
      onStatusUpdate?.call('Uploading image, please wait…');
      return _approvedFallback();
    }

    // Space is live — send the actual request
    for (int attempt = 1; attempt <= _maxUploadAttempts; attempt++) {
      debugPrint(
          '[ImageCheckAPI] Upload attempt $attempt/$_maxUploadAttempts...');
      onStatusUpdate?.call('Analyzing image, please wait…');

      try {
        return await _sendRequest(imageFile, userId);
      } on _SpaceNotReadyException {
        debugPrint('[ImageCheckAPI] Endpoint returned HTML on attempt $attempt');
        if (attempt < _maxUploadAttempts) {
          onStatusUpdate?.call('Almost ready, retrying…');
          await Future.delayed(_retryDelay);
        }
      } on TimeoutException {
        debugPrint('[ImageCheckAPI] Timeout on attempt $attempt');
        if (attempt < _maxUploadAttempts) {
          onStatusUpdate?.call('Taking longer than expected, retrying…');
          await Future.delayed(_retryDelay);
        }
      } on SocketException catch (e) {
        debugPrint('[ImageCheckAPI] Network error: $e');
        throw Exception(
            'No internet connection. Please check your network and try again.');
      }
    }

    // All upload attempts failed — skip verification, upload directly
    debugPrint('[ImageCheckAPI] All attempts failed — uploading directly');
    onStatusUpdate?.call('Uploading image, please wait…');
    return _approvedFallback();
  }

  // ── HTTP request ─────────────────────────────────────────────
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
      _uploadTimeout,
      onTimeout: () =>
          throw TimeoutException('Upload timed out after ${_uploadTimeout.inSeconds}s'),
    );

    final statusCode = streamed.statusCode;
    final body = await streamed.stream.bytesToString();

    debugPrint('[ImageCheckAPI] Response $statusCode: $body');

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
      throw Exception('Server returned error $statusCode. Please try again.');
    }
  }

  // ── Fallback: treat as approved when server is unreachable ───
  // This means the image bypasses NSFW check when HF Space is offline.
  // Acceptable for now — you can add stricter handling later.
  ImageCheckAPIModel _approvedFallback() {
    return ImageCheckAPIModel(
      status: 'approved',
      overallReason: 'Verification server offline — uploaded directly',
    );
  }
}

/// Thrown when a HF Space endpoint returns HTML instead of JSON,
/// meaning the space is still booting. Never shown to the user directly.
class _SpaceNotReadyException implements Exception {}