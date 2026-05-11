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
  bool _iapLoading = false;
  Timer? _iapRetryTimer;

  final _userUid = FirebaseAuth.instance.currentUser!.uid;

  bool _isPrivateRelayEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return email.toLowerCase().contains('privaterelay.appleid.com');
  }

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

  void _startIapPricePolling() {
    final price = _platformPaymentService
        .getProductPrice(InAppPurchaseService.imageDownloadProductId);
    if (price != null) return;

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

  @override
  Widget build(BuildContext context) {
    final iapPrice = _platformPaymentService
        .getProductPrice(InAppPurchaseService.imageDownloadProductId);
    final isIos = Platform.isIOS;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = screenWidth >= 600;

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
            SizedBox(
              height: isTapValue
                  ? screenHeight
                  : screenHeight * (isLandscape ? 0.82 : 0.72),
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

            if (!isTapValue)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: isLandscape 
                        ? screenHeight * 0.75 
                        : screenHeight * 0.55,
                    minHeight: screenHeight * 0.35,
                  ),
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 28.w : 20.w, vertical: 15.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          // Main Content
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.imageTitle,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 28.sp : (isLandscape ? 20.sp : 24.sp),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Description : ${widget.imageDescription}',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 18.sp : (isLandscape ? 14.sp : 16.sp),
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
                                    fontSize: isTablet ? 18.sp : (isLandscape ? 14.sp : 16.sp),
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
                                    fontSize: isTablet ? 18.sp : (isLandscape ? 14.sp : 16.sp),
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                              SizedBox(height: 10.h),

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
                                              fontSize: isTablet ? 18.sp : (isLandscape ? 14.sp : 16.sp),
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
                                          fontSize: isTablet ? 20.sp : (isLandscape ? 15.sp : 18.sp),
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                              SizedBox(height: 20.h),
                            ],
                          ),

                          // Buy Button
                          if (!widget.isOwner)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).padding.bottom + 10.h,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: ReuseableBottomButton(
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
                                      // log('🟢 Buy tapped. priceInCents=$priceInCents, imageId=${widget.imageId}');

                                      final paid = await makePaymentAndBuyImage(
                                          priceInCents);
                                      log('💳 Payment result: $paid');
                                      if (!paid) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Payment was not completed.')),
                                          );
                                        }
                                        return;
                                      }

                                      final txId = _platformPaymentService
                                          .getLastIapTransactionId();
                                      await ImageUploadService()
                                          .markItemSoldAfterPayment(
                                        documentId: widget.imageId!,
                                        paymentMethod: 'iap',
                                        transactionId: txId,
                                        productId: InAppPurchaseService
                                            .imageDownloadProductId,
                                      );
                                      log('✅ Marked item sold: ${widget.imageId}');

                                      final buyerEmail =
                                          FirebaseAuth.instance.currentUser?.email;

                                      if (buyerEmail != null &&
                                          buyerEmail.isNotEmpty &&
                                          !_isPrivateRelayEmail(buyerEmail)) {
                                        final buyerOk = await MailSender.send(
                                          toEmail: buyerEmail,
                                          subject: 'Purchase Confirmation',
                                          textBody:
                                              'Hello,\nYou purchased "${widget.imageTitle}" '
                                              'from Lamhti at a cost of \$${widget.imagePrice}',
                                        );
                                        log('📧 Buyer email -> $buyerEmail | sent=$buyerOk');
                                      } else {
                                        log('⚠️ Buyer email skipped — private relay or null: $buyerEmail');
                                      }

                                      final sellerEmail = widget.ownerEmail;
                                      final buyerLabel =
                                          (buyerEmail != null &&
                                                  !_isPrivateRelayEmail(buyerEmail))
                                              ? buyerEmail
                                              : 'Lamhti buyer';

                                      if (sellerEmail.isNotEmpty &&
                                          !_isPrivateRelayEmail(sellerEmail)) {
                                        final sellerOk = await MailSender.send(
                                          toEmail: sellerEmail,
                                          subject: 'Your item was sold — Lamhti',
                                          textBody:
                                              'Hello,\nCongratulations! Your product '
                                              '"${widget.imageTitle}" has been sold for '
                                              '\$${widget.imagePrice}.\n'
                                              'Buyer: $buyerLabel\n'
                                              'Date: ${DateTime.now().toIso8601String()}\n\n'
                                              'We\'ll handle the next steps as per your settings.\n\n'
                                              '~TEAM LAMHTI',
                                        );
                                        log('📧 Seller email -> $sellerEmail | sent=$sellerOk');
                                      } else {
                                        log('⚠️ Seller email skipped — private relay or empty: $sellerEmail');
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Purchase complete!')),
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
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}