import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lamhti_app/Services/Firebase Storage/ImageUploadService.dart';
import 'package:lamhti_app/Services/Firebase Storage/User Details Storage/UserDetailsStorageService.dart';
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
  bool isUserOnboarded = false;
  String _onBoardingLink = "";

  final _formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController imageSizeController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController imageCategoryController = TextEditingController();

  final ImageCheckAPI imageCheckAPI = ImageCheckAPI();
  final ImageUploadService imageUploadService = ImageUploadService();
  final UserDetailsStorageService userDetailsStorageService =
      UserDetailsStorageService();

  String userUID = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    // Seller onboarding disabled (Stripe removed)
    // Sellers can now upload immediately without onboarding
    setState(() {
      isProcessingStatus = false;
      isUserOnboarded = true;
    });
  }

  Future<void> checkUserOnboardingStatus() async {
    // ✅ Onboarding check disabled - no longer required
    // Sellers can upload images to sell directly via IAP
    setState(() => isProcessingStatus = false);
  }

  Future<void> pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  void verifyAndUpload() async {
    if (_imageFile != null && _formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        var apiResponse = await imageCheckAPI.getImageCheckAPIResponse(
          _imageFile!,
          userUID,
        );

        if (apiResponse?.status == "approved") {
          await imageUploadService.uploadImageAndData(
            email: FirebaseAuth.instance.currentUser!.email!,
            imageFile: _imageFile!,
            title: titleController.text.trim(),
            description: descriptionController.text.trim(),
            category: imageCategoryController.text.toString(),
            location: locationController.text,
            price: amountController.text,
            imageSize: imageSizeController.text,
          );

          Toast.toastMessage("Image upload successful!", Colors.black);

          setState(() {
            _imageFile = null;
            titleController.clear();
            amountController.clear();
            imageSizeController.clear();
            imageCategoryController.clear();
            locationController.clear();
            descriptionController.clear();
          });
        } else if (apiResponse?.status == "rejected") {
          setState(() => _imageFile = null);
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text(
                "Error",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                apiResponse!.overallReason!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Ok"),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        Toast.toastMessage("Something went wrong $e", Colors.red);
      } finally {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isProcessingStatus) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return isLoading
        ? Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          const Center(
            child: Text(
              "Analyzing image, Please wait...",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    )
        : Scaffold(
      appBar: AppBar(
        title: Text(
          "Upload Image",
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                InkWell(
                  onTap: pickImage,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.3,
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0.r),
                      border:
                      Border.all(color: Colors.grey, width: 2.w),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                      borderRadius:
                      BorderRadius.circular(12.r),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, size: 40),
                        SizedBox(height: 10),
                        Text(
                          "Tap to pick an image",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Image Title",
                    hintText: "Enter image title",
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? "Please provide title"
                      : null,
                ),
                SizedBox(height: 20.h),

                // Amount
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: "Amount",
                    hintText: "Enter amount between \$5 to \$2000",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter an amount";
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return "Please enter a valid number";
                    } else if (amount < 5 || amount > 2000) {
                      return "Amount must be between 5 and 2000";
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20.h),
                TextFormField(
                  controller: imageSizeController,
                  decoration: const InputDecoration(
                    labelText: "Image size",
                    hintText: "Enter image size",
                  ),
                ),

                SizedBox(height: 20.h),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: "Location",
                    hintText: "Enter location",
                  ),
                ),

                SizedBox(height: 20.h),
                TextFormField(
                  controller: imageCategoryController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Image Category",
                    hintText: "Select image category",
                    border: const OutlineInputBorder(),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (value) {
                        imageCategoryController.text = value;
                      },
                      itemBuilder: (context) {
                        return [
                          'Art',
                          'Tech',
                          'Food',
                          'Travel',
                          'Nature',
                          'Fashion',
                          'Other',
                        ]
                            .map((e) => PopupMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                            .toList();
                      },
                    ),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? "Please select a category"
                      : null,
                ),

                SizedBox(height: 20.h),
                TextFormField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Image Description",
                    hintText: "Enter image description",
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
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

// 🔥 Dialog Function
void _showOnboardingDialog(BuildContext context, String link) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text("Complete Seller Payout Onboarding"),
        content: const Text(
          "This step is only for sellers to receive payouts. Buyers purchase digital content using Apple In-App Purchase on iOS.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WebViewScreen(url: link),
                ),
              );
            },
            child: const Text("Continue"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
        ],
      );
    },
  );
}

// 🌐 WebView Screen
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
