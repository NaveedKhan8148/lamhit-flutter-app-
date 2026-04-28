import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/ImageUploadService.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/User%20Details%20Storage/UserDetailsStorageService.dart';
import 'package:lamhti_app/Services/ImageCheckAPI/ImageCheckAPI.dart';
import 'package:lamhti_app/Utils/ReuseableBottomButton.dart';
import 'package:lamhti_app/Utils/Toast.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _imageFile;
  bool isLoading = false;
  bool isProcessingStatus = false;
  bool _cancelled = false;

  // Loading stage message shown to user during the process
  String _loadingMessage = "Connecting to server, please wait...";

  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final locationController = TextEditingController();
  final imageSizeController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageCategoryController = TextEditingController();

  final ImageCheckAPI imageCheckAPI = ImageCheckAPI();
  final ImageUploadService imageUploadService = ImageUploadService();
  final UserDetailsStorageService userDetailsStorageService =
      UserDetailsStorageService();

  late final String userUID;

  @override
  void initState() {
    super.initState();
    userUID = FirebaseAuth.instance.currentUser!.uid;
    setState(() {
      isProcessingStatus = false;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    locationController.dispose();
    imageSizeController.dispose();
    descriptionController.dispose();
    imageCategoryController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() => _imageFile = File(pickedImage.path));
    }
  }

  void _setLoadingMessage(String msg) {
    if (mounted && !_cancelled) setState(() => _loadingMessage = msg);
  }

  void verifyAndUpload() async {
    debugPrint('[Upload] Upload button pressed');

    if (_imageFile == null) {
      Toast.toastMessage("Please select an image first", Colors.orange);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      Toast.toastMessage("Please fill all required fields", Colors.orange);
      return;
    }

    _cancelled = false;
    setState(() {
      isLoading = true;
      _loadingMessage = "Starting image server...\nFirst-time startup may take ~2 minutes.\nPlease keep the app open.";
    });

    try {
      // ── Step 1: Try image verification (best-effort — falls back if server down) ──
      _setLoadingMessage("Starting image server...\nPlease keep the app open.");
      debugPrint('[Upload] Calling image check API...');

      bool verificationSkipped = false;
      bool shouldUpload = true;

      try {
        final apiResponse = await imageCheckAPI.getImageCheckAPIResponse(
          _imageFile!,
          userUID,
          onStatusUpdate: _setLoadingMessage,
        );

        if (apiResponse == null) {
          debugPrint('[Upload] API returned null — skipping verification');
          verificationSkipped = true;
        } else {
          debugPrint('[Upload] API Response status: ${apiResponse.status}');
          if (apiResponse.status == "rejected") {
            final reason =
                apiResponse.overallReason ?? "Image does not meet requirements";
            debugPrint('[Upload] Image rejected: $reason');
            setState(() => _imageFile = null);
            Toast.toastMessage("Image rejected: $reason", Colors.red);
            _showErrorDialog("Image Rejected", reason);
            shouldUpload = false;
          } else if (apiResponse.status != "approved") {
            debugPrint('[Upload] Unexpected status: ${apiResponse.status} — skipping verification');
            verificationSkipped = true;
          }
        }
      } catch (verifyError) {
        // Server unreachable / timed out — skip check, upload anyway
        debugPrint('[Upload] Verification server failed: $verifyError');
        debugPrint('[Upload] Falling back to direct upload...');
        verificationSkipped = true;
      }

      if (!shouldUpload || _cancelled) return;

      // ── Step 2: Upload to Firebase ──
      _setLoadingMessage("Uploading image, please wait...");

      if (verificationSkipped) {
        Toast.toastMessage(
          "Verification server offline — uploading directly",
          Colors.orange,
        );
      }

      await imageUploadService.uploadImageAndData(
        email: FirebaseAuth.instance.currentUser!.email!,
        imageFile: _imageFile!,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        category: imageCategoryController.text,
        location: locationController.text,
        price: amountController.text,
        imageSize: imageSizeController.text,
      );

      debugPrint('[Upload] Upload successful!');
      Toast.toastMessage("Image uploaded successfully!", Colors.green);

      // Clear form
      if (mounted) {
        setState(() {
          _imageFile = null;
          titleController.clear();
          amountController.clear();
          imageSizeController.clear();
          imageCategoryController.clear();
          locationController.clear();
          descriptionController.clear();
        });
      }
    } on FirebaseException catch (e) {
      if (_cancelled) return;
      debugPrint('[Upload] Firebase exception: ${e.code} - ${e.message}');
      final msg = e.message ?? e.code;
      Toast.toastMessage("Upload error: $msg", Colors.red);
      _showErrorDialog("Upload Error", msg);
    } catch (e) {
      if (_cancelled) return;
      debugPrint('[Upload] Error: $e');
      final raw = e.toString();
      final msg = raw.startsWith('Exception: ') ? raw.substring(11) : raw;
      Toast.toastMessage(msg, Colors.red);
      _showErrorDialog("Error", msg);
    } finally {
      if (mounted && !_cancelled) setState(() => isLoading = false);
      debugPrint('[Upload] Upload process ended');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isProcessingStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  _loadingMessage,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 32.h),
              TextButton.icon(
                onPressed: () {
                  _cancelled = true;
                  if (mounted) setState(() => isLoading = false);
                },
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Upload Image",
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Image picker
                InkWell(
                  onTap: pickImage,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.3,
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0.r),
                      border: Border.all(color: Colors.grey, width: 2.w),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add, size: 40),
                              SizedBox(height: 10),
                              Text(
                                "Tap to pick an image",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 40.h),

                // Title
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Image Title",
                    hintText: "Enter image title",
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Please provide title"
                      : null,
                ),
                SizedBox(height: 20.h),

                // Amount
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Amount",
                    hintText: "Enter amount between \$5 to \$2000",
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return "Please enter an amount";
                    final amount = double.tryParse(v);
                    if (amount == null) return "Please enter a valid number";
                    if (amount < 5 || amount > 2000)
                      return "Amount must be between 5 and 2000";
                    return null;
                  },
                ),
                SizedBox(height: 20.h),

                // Image Size
                TextFormField(
                  controller: imageSizeController,
                  decoration: const InputDecoration(
                    labelText: "Image size",
                    hintText: "Enter image size",
                  ),
                ),
                SizedBox(height: 20.h),

                // Location
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: "Location",
                    hintText: "Enter location",
                  ),
                ),
                SizedBox(height: 20.h),

                // Category
                TextFormField(
                  controller: imageCategoryController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Image Category",
                    hintText: "Select image category",
                    border: const OutlineInputBorder(),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (value) =>
                          imageCategoryController.text = value,
                      itemBuilder: (context) => [
                        'Art',
                        'Tech',
                        'Food',
                        'Travel',
                        'Nature',
                        'Fashion',
                        'Other',
                      ]
                          .map((e) =>
                              PopupMenuItem(value: e, child: Text(e)))
                          .toList(),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Please select a category" : null,
                ),
                SizedBox(height: 20.h),

                // Description
                TextFormField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Image Description",
                    hintText: "Enter image description",
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Please provide description"
                      : null,
                ),
                SizedBox(height: 40.h),

                ReuseableBottomButton(
                  buttonText: "Upload Now",
                  onTap: verifyAndUpload,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🌐 WebView Screen (kept for potential future use)
class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => isLoading = false),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Onboarding")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}