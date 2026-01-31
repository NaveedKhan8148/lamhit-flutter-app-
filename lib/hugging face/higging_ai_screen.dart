import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AiImageGatePage extends StatefulWidget {
  const AiImageGatePage({super.key});

  @override
  State<AiImageGatePage> createState() => _AiImageGatePageState();
}

class _AiImageGatePageState extends State<AiImageGatePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selected;

  bool _loading = false;
  String? _label; // "Safe" | "Naked"
  double? _confidence;
  String? _error;

  static const String _endpoint =
      "https://asia-south1-lamhti.cloudfunctions.net/detectAdultContent"; // <-- Replace PROJECT_ID

  Future<bool> _ensurePhotoPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      if (Platform.isAndroid && status.isDenied) {
        final storage = await Permission.storage.request();
        if (storage.isGranted) return true;
        if (storage.isPermanentlyDenied || status.isPermanentlyDenied) {
          await openAppSettings();
        }
        return false;
      }
      if (status.isPermanentlyDenied) await openAppSettings();
      return false;
    }
    return true;
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _selected = null;
      _label = null;
      _confidence = null;
      _error = null;
    });

    try {
      final ok = await _ensurePhotoPermission();
      if (!ok) {
        setState(() => _error = "Photo permission denied.");
        return;
      }

      XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (file == null && Platform.isAndroid) {
        final lost = await _picker.retrieveLostData();
        if (!lost.isEmpty && lost.file != null) file = lost.file;
      }

      if (file != null) {
        setState(() => _selected = file);
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final picked = result.files.single;
        final dir = await getTemporaryDirectory();
        final tempPath = '${dir.path}/${picked.name}';
        final f = File(tempPath);
        await f.writeAsBytes(picked.bytes!);
        setState(() => _selected = XFile(f.path, name: picked.name));
      } else {
        setState(() => _error = "No image selected.");
      }
    } catch (e) {
      setState(() => _error = "Picker error: $e");
    }
  }

  Future<void> _analyze() async {
    if (_selected == null) return;
    setState(() {
      _loading = true;
      _label = null;
      _confidence = null;
      _error = null;
    });

    try {
      final bytes = await File(_selected!.path).readAsBytes();
      final mime =
          lookupMimeType(_selected!.path, headerBytes: bytes) ??
          'application/octet-stream';

      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': mime, 'Accept': 'application/json'},
        body: bytes,
      );

      if (res.statusCode != 200) {
        setState(() {
          _error = "API error (${res.statusCode}) ${res.body}";
          _loading = false;
        });
        log('$_error');
        return;
      }

      final Map<String, dynamic> map =
          jsonDecode(res.body) as Map<String, dynamic>;
      final List<dynamic>? predictions = map["predictions"] as List<dynamic>?;

      if (predictions == null || predictions.isEmpty) {
        setState(() {
          _error = "Invalid response from server.";
          _loading = false;
        });
        return;
      }

      predictions.sort(
        (a, b) => (b["confidence"] as num).compareTo(a["confidence"] as num),
      );
      final top = predictions.first;
      setState(() {
        _label = top["label"] as String?;
        _confidence = (top["confidence"] as num?)?.toDouble();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Adult Content Detector")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text("Select from Gallery"),
          ),
          const SizedBox(height: 12),

          if (_selected != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_selected!.path),
                height: 240,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _loading ? null : _analyze,
              icon:
                  _loading
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.search),
              label: Text(_loading ? "Analyzing..." : "Analyze Image"),
            ),
            const SizedBox(height: 16),
          ],

          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.45)),
              ),
              child: SelectableText(
                "Error: $_error",
                style: const TextStyle(color: Colors.red),
              ),
            ),

          if (_label != null && _confidence != null)
            _NSFWResultChip(
              label: _label!,
              confidence: _confidence!,
              theme: theme,
              blockThreshold: 0.85,
            ),

          const SizedBox(height: 28),
          const Text(
            "Tip: If result is “Adult” with high confidence (≥85%), you should block; else it's likely safe.",
          ),
        ],
      ),
    );
  }
}

class _NSFWResultChip extends StatelessWidget {
  final String label; // "Safe" | "Naked"
  final double confidence; // 0..1
  final ThemeData theme;
  final double blockThreshold;

  const _NSFWResultChip({
    required this.label,
    required this.confidence,
    required this.theme,
    required this.blockThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final isNaked = label.toLowerCase() == "naked";
    final percent = (confidence * 100).toStringAsFixed(1);
    final blocked = isNaked && confidence >= blockThreshold;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Icon(
              isNaked
                  ? Icons.warning_amber_outlined
                  : Icons.check_circle_outline,
              color: isNaked ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isNaked
                    ? "Detected Adult Content ($percent%)"
                    : "Safe Image ($percent%)",
                style: theme.textTheme.titleMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    blocked
                        ? Colors.red.withOpacity(0.12)
                        : Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                blocked ? "BLOCK" : "SAFE",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: blocked ? Colors.red.shade800 : Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;

// class AiImageGatePage extends StatefulWidget {
//   const AiImageGatePage({Key? key}) : super(key: key);

//   @override
//   State<AiImageGatePage> createState() => _AiImageGatePageState();
// }

// class _AiImageGatePageState extends State<AiImageGatePage> {
//   File? _image;
//   bool _loading = false;
//   Map<String, dynamic>? _result;

//   final picker = ImagePicker();

//   final String cloudFnUrl =
//       "https://detectsensitiveimage-qndxykwqkq-el.a.run.app";

//   Future<void> _pickImage() async {
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked == null) return;
//     setState(() => _image = File(picked.path));
//   }

//   Future<void> _analyze() async {
//     if (_image == null) return;
//     setState(() {
//       _loading = true;
//       _result = null;
//     });

//     try {
//       final req = http.MultipartRequest("POST", Uri.parse(cloudFnUrl))
//         ..files.add(await http.MultipartFile.fromPath("image", _image!.path));

//       final res = await req.send();
//       final body = await res.stream.bytesToString();

//       if (res.statusCode == 200) {
//         setState(() => _result = jsonDecode(body));
//       } else {
//         setState(() => _result = {"error": "Analysis failed", "details": body});
//       }
//     } catch (e) {
//       setState(() => _result = {"error": e.toString()});
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("AI Image Safety Checker")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             if (_image != null)
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.file(_image!, height: 240, fit: BoxFit.cover),
//               ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               icon: const Icon(Icons.photo),
//               label: const Text("Pick Image"),
//               onPressed: _pickImage,
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton.icon(
//               icon: const Icon(Icons.shield),
//               label: const Text("Analyze Image"),
//               onPressed: _analyze,
//             ),
//             const SizedBox(height: 20),
//             if (_loading) const CircularProgressIndicator(),
//             if (_result != null) Expanded(child: _buildResult()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildResult() {
//     if (_result!.containsKey("error")) {
//       return Text(
//         "❌ ${_result!["error"]}\n${_result!["details"] ?? ""}",
//         style: const TextStyle(color: Colors.red),
//       );
//     }

//     final adult = _result!["adultResult"];
//     final sensitive = _result!["sensitiveResult"];

//     return ListView(
//       children: [
//         const Text(
//           "🔞 Adult Content Detection",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         Text(const JsonEncoder.withIndent("  ").convert(adult)),
//         const Divider(),
//         const Text(
//           "🩸 Sensitive / Violent Content Detection",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         Text(const JsonEncoder.withIndent("  ").convert(sensitive)),
//       ],
//     );
//   }
// }
