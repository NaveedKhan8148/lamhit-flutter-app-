import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/ImageBuyingService.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/ImageUploadService.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/User%20Details%20Storage/UserDetailsStorageService.dart';
import 'package:lamhti_app/Services/Payment%20Service/InAppPurchaseService.dart';
import 'package:lamhti_app/Services/Payment%20Service/PlatformPaymentService.dart';
import 'package:lamhti_app/Services/email_service.dart';
import 'package:lamhti_app/Utils/ReuseableBottomButton.dart';
import 'package:lamhti_app/Utils/Toast.dart';
import 'package:shimmer/shimmer.dart';

class DetailedImageDisplayScreen extends StatefulWidget {
  final String imageUrl;
  final String imageTitle;
  final String imageSize;
  final String location;
  final String imageDescription;
  final double imagePrice;
  final String ownerId;
  final String ownerEmail;
  final String? imageId;
  final bool isOwner;

  const DetailedImageDisplayScreen({
    super.key,
    required this.imageUrl,
    required this.imageTitle,
    required this.imageDescription,
    required this.imagePrice,
    this.imageId,
    required this.isOwner,
    required this.ownerId,
    required this.ownerEmail,
    required this.imageSize,
    required this.location,
  });

  @override
  State<DetailedImageDisplayScreen> createState() =>
      _DetailedImageDisplayScreenState();
}

class _DetailedImageDisplayScreenState
    extends State<DetailedImageDisplayScreen> {
  final PlatformPaymentService _platformPaymentService =
      PlatformPaymentService();

  final ImageBuyingService imageBuyingService = ImageBuyingService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  bool isLoadingSheet = false;
  bool isTapValue = false;

  // ── NEW: track whether we're still waiting for IAP products ──
  bool _iapLoading = false;
  Timer? _iapRetryTimer;

  final _userUid = FirebaseAuth.instance.currentUser!.uid;

  // ─────────────────────────────────────────────────────────────
  // initState — kick off IAP price polling on iOS
  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _startIapPricePolling();
    }
  }

  @override
  void dispose() {
    _iapRetryTimer?.cancel();
    super.dispose();
  }

  /// Polls every second until the IAP product price is available (max 15 s).
  /// This ensures the Buy button is enabled by the time a reviewer taps it.
  void _startIapPricePolling() {
    final price = _platformPaymentService
        .getProductPrice(InAppPurchaseService.imageDownloadProductId);
    if (price != null) return; // already loaded

    setState(() => _iapLoading = true);

    int attempts = 0;
    _iapRetryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      attempts++;
      final p = _platformPaymentService
          .getProductPrice(InAppPurchaseService.imageDownloadProductId);

      if (p != null || attempts >= 15) {
        timer.cancel();
        if (mounted) setState(() => _iapLoading = false);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Payment
  // ─────────────────────────────────────────────────────────────
  Future<bool> makePaymentAndBuyImage(int priceInCents) async {
    try {
      setState(() => isLoadingSheet = true);

      final accountId =
          await _imageUploadService.getAccountIdFromUpload(widget.imageId!);
      debugPrint("SELLER Account ID: $accountId");

      final paymentSuccessful = await _platformPaymentService.processPayment(
        amountInCents: priceInCents,
        imageId: widget.imageId ?? "unknown",
        accountId: accountId ?? "dummyId",
        productId: InAppPurchaseService.imageDownloadProductId,
      );

      setState(() => isLoadingSheet = false);
      return paymentSuccessful;
    } catch (e) {
      setState(() => isLoadingSheet = false);
      debugPrint("Payment Error: $e");
      Toast.toastMessage("Payment Error: $e", Colors.red);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final iapPrice = _platformPaymentService
        .getProductPrice(InAppPurchaseService.imageDownloadProductId);
    final isIos = Platform.isIOS;

    // Show full-screen loader while payment sheet is open
    if (isLoadingSheet) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: () async {
        if (isTapValue) {
          setState(() => isTapValue = false);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Hero image ──────────────────────────────────────
            SizedBox(
              height: isTapValue
                  ? MediaQuery.of(context).size.height
                  : MediaQuery.of(context).size.height * 0.7,
              width: double.infinity,
              child: GestureDetector(
                onTap: () => setState(() => isTapValue = true),
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.red),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // ── Back button ─────────────────────────────────────
            Positioned(
              top: 40.h,
              left: 10.w,
              child: InkWell(
                onTap: () {
                  if (isTapValue) {
                    setState(() => isTapValue = false);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  radius: 22.r,
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),

            // ── Bottom sheet ────────────────────────────────────
            if (!isTapValue)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.33,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 15.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            height: 5.h,
                            width: 40.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),

                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  widget.imageTitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                // Description
                                Text(
                                  'Description : ${widget.imageDescription}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                if (widget.imageSize.isNotEmpty) ...[
                                  SizedBox(height: 5.h),
                                  Text(
                                    'Image Size : ${widget.imageSize}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                                if (widget.location.isNotEmpty) ...[
                                  SizedBox(height: 5.h),
                                  Text(
                                    'Location : ${widget.location}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                                SizedBox(height: 5.h),

                                // Price
                                if (!widget.isOwner)
                                  _iapLoading && isIos
                                      ? Row(
                                          children: [
                                            SizedBox(
                                              height: 16.h,
                                              width: 16.w,
                                              child:
                                                  const CircularProgressIndicator(
                                                      strokeWidth: 2),
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Loading price...',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          isIos
                                              ? "Price: ${iapPrice ?? 'Unavailable'}"
                                              : "Price: \$${widget.imagePrice.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                SizedBox(height: 10.h),
                              ],
                            ),
                          ),
                        ),

                        // Buy button
                        if (!widget.isOwner)
                          SizedBox(
                            width: double.infinity,
                            child: ReuseableBottomButton(
                              // ── KEY FIX: button is enabled as soon as
                              //    iapPrice loads; spinner shown while waiting ──
                              enabled: isIos
                                  ? (iapPrice != null && !_iapLoading)
                                  : true,
                              buttonText: isIos
                                  ? (_iapLoading
                                      ? "Loading price..."
                                      : iapPrice != null
                                          ? "Buy Now for $iapPrice"
                                          : "Unavailable")
                                  : "Buy Now for \$${widget.imagePrice}",
                              onTap: () async {
                                if (isIos && iapPrice == null) {
                                  Toast.toastMessage(
                                    'Apple In-App Purchase price not loaded yet, please wait.',
                                    Colors.orange,
                                  );
                                  return;
                                }
                                try {
                                  final priceInCents =
                                      (widget.imagePrice * 100).round();
                                  log('🟢 Buy tapped. priceInCents=$priceInCents, imageId=${widget.imageId}');

                                  // 1) Take payment
                                  final paid =
                                      await makePaymentAndBuyImage(priceInCents);
                                  log('💳 Payment result: $paid');
                                  if (!paid) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Payment was not completed.')),
                                      );
                                    }
                                    return;
                                  }

                                  // 2) Mark as sold
                                  final txId = _platformPaymentService
                                      .getLastIapTransactionId();
                                  await ImageUploadService()
                                      .markItemSoldAfterPayment(
                                    documentId: widget.imageId!,
                                    paymentMethod: isIos ? 'iap' : 'stripe',
                                    transactionId: isIos ? txId : null,
                                    productId: isIos
                                        ? InAppPurchaseService
                                            .imageDownloadProductId
                                        : null,
                                  );
                                  log('✅ Marked item sold: ${widget.imageId}');

                                  // 3) Email buyer
                                  final buyerEmail =
                                      FirebaseAuth.instance.currentUser?.email;
                                  if (buyerEmail != null &&
                                      buyerEmail.isNotEmpty) {
                                    final buyerOk = await MailSender.send(
                                      toEmail: buyerEmail,
                                      subject: 'Purchase Confirmation',
                                      textBody:
                                          'Hello,\nYou purchased "${widget.imageTitle}" from Lamhti at a cost of \$${widget.imagePrice}',
                                    );
                                    log('📧 Buyer email -> $buyerEmail | sent=$buyerOk');
                                  }

                                  // 4) Email seller
                                  final sellerEmail = widget.ownerEmail;
                                  if (sellerEmail.isNotEmpty) {
                                    final sellerOk = await MailSender.send(
                                      toEmail: sellerEmail,
                                      subject: 'Your item was sold — Lamhti',
                                      textBody:
                                          'Hello,\nCongratulations! Your product "${widget.imageTitle}" has been sold for \$${widget.imagePrice}.\n'
                                          'Buyer: ${FirebaseAuth.instance.currentUser?.email ?? "Lamhti buyer"}\n'
                                          'Date: ${DateTime.now().toIso8601String()}\n\n'
                                          'We\'ll handle the next steps as per your settings.\n\n'
                                          '~TEAM LAMHTI',
                                    );
                                    log('📧 Seller email -> $sellerEmail | sent=$sellerOk');
                                  }

                                  // 5) Done
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Purchase complete. Emails sent.')),
                                    );
                                  }
                                } catch (e, st) {
                                  log('❌ Buy flow error: $e', stackTrace: st);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}