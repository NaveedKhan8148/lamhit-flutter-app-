import 'dart:io';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/ImageBuyingService.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/ImageUploadService.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/User%20Details%20Storage/UserDetailsStorageService.dart';
import 'package:lamhti_app/Services/Payment%20Service/BuyerPayoutService.dart';
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
  BuyerPayoutService buyerPayoutService = BuyerPayoutService();
  
  // Platform-aware payment service (handles IAP for iOS, Stripe for Android/Web)
  final PlatformPaymentService _platformPaymentService = PlatformPaymentService();

  ImageBuyingService imageBuyingService = ImageBuyingService();

  ImageUploadService _imageUploadService = ImageUploadService();

  bool isLoadingSheet = false;

  final _userUid = FirebaseAuth.instance.currentUser!.uid;

  Future<bool> makePaymentAndBuyImage(int priceInCents) async {
    try {
      setState(() {
        isLoadingSheet = true; // Start loading
      });

      String? _accountId = await _imageUploadService.getAccountIdFromUpload(widget.imageId!);

      debugPrint("SELLER Account ID: $_accountId");

      // Use platform-aware payment service
      final paymentSuccessful = await _platformPaymentService.processPayment(
        amountInCents: priceInCents,
        imageId: widget.imageId ?? "unknown",
        accountId: _accountId ?? "dummyId",
        productId: InAppPurchaseService.imageDownloadProductId,
      );

      // Hide loader BEFORE showing payment sheet
      setState(() {
        isLoadingSheet = false;
      });

      return paymentSuccessful;

      // If no exception, update image status
      // await imageBuyingService.updateImageStatusAndDetails(
      //   widget.imageId!,
      //   _userUid,
      // );
    } catch (e) {
      setState(() {
        isLoadingSheet = false;
      });

      debugPrint("Payment Error: $e");
      Toast.toastMessage("Payment Error: $e", Colors.red);
      return false;
    }
  }

  @override
  bool isTapValue = false;
  Widget build(BuildContext context) {
    final iapPrice = _platformPaymentService.getProductPrice(
      InAppPurchaseService.imageDownloadProductId,
    );
    final isIos = Platform.isIOS;

    return isLoadingSheet
        ? Scaffold(body: Center(child: CircularProgressIndicator()))
        : WillPopScope(
          onWillPop: () async {
            if (isTapValue == true) {
              isTapValue = false;
              setState(() {});
              return false;
            } else {
              return true;
            }
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // Background image
                SizedBox(
                  height:
                      isTapValue
                          ? MediaQuery.of(context).size.height
                          : MediaQuery.of(context).size.height * 0.7,
                  width: double.infinity,
                  // child: InteractiveViewer(
                  //   panEnabled: true,
                  //   minScale: 0.8,
                  //   maxScale: 10.0,
                  //   child: CachedNetworkImage(
                  //     imageUrl: widget.imageUrl,
                  //     placeholder:
                  //         (context, url) => Shimmer.fromColors(
                  //           baseColor: Colors.grey[300]!,
                  //           highlightColor: Colors.grey[100]!,
                  //           child: Container(color: Colors.white),
                  //         ),
                  //     errorWidget:
                  //         (context, url, error) =>
                  //             Icon(Icons.error, color: Colors.red),
                  //     fit: BoxFit.cover,
                  //   ),
                  // ),
                  child: GestureDetector(
                    onTap: () {
                      isTapValue = true;
                      setState(() {});
                    },
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      placeholder:
                          (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                      errorWidget:
                          (context, url, error) =>
                              Icon(Icons.error, color: Colors.red),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // SizedBox(
                //   height: MediaQuery.of(context).size.height * 0.55,
                //   width: double.infinity,
                //   child: InteractiveViewer(
                //     panEnabled: true, // Allow panning
                //     minScale: 0.8, // Minimum zoom out
                //     maxScale: 4.0, // Maximum zoom in
                //     child: CachedNetworkImage(
                //       imageUrl: widget.imageUrl,
                //       placeholder:
                //           (context, url) => Shimmer.fromColors(
                //             baseColor: Colors.grey[300]!,
                //             highlightColor: Colors.grey[100]!,
                //             child: Container(color: Colors.white),
                //           ),
                //       errorWidget:
                //           (context, url, error) =>
                //               Icon(Icons.error, color: Colors.red),
                //       fit: BoxFit.cover,
                //     ),
                //   ),
                // ),
                Positioned(
                  top: 40.h,
                  left: 10.w,
                  child: InkWell(
                    onTap: () {
                      if (isTapValue == true) {
                        isTapValue = false;
                        setState(() {});
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.6),
                      radius: 22.r,
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),

                isTapValue == true
                    ? SizedBox()
                    : Align(
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
                            horizontal: 20.w,
                            vertical: 15.h,
                          ),
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
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                                      Text(
                                        'Description : ${widget.imageDescription}',
                                        // overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      widget.location.isEmpty
                                          ? SizedBox()
                                          : SizedBox(height: 5.h),
                                      widget.imageSize.isEmpty
                                          ? SizedBox()
                                          : Text(
                                            'Image Size : ${widget.imageSize}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                      widget.location.isEmpty
                                          ? SizedBox()
                                          : SizedBox(height: 5.h),
                                      widget.location.isEmpty
                                          ? SizedBox()
                                          : Text(
                                            'Location : ${widget.location}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,

                                            style: GoogleFonts.poppins(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                      SizedBox(height: 5.h),

                                      Visibility(
                                        visible: !widget.isOwner,
                                        child: Text(
                                          isIos
                                              ? "Price: ${iapPrice ?? ''}"
                                              : "Price: \$${widget.imagePrice.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                    ],
                                  ),
                                ),
                              ),

                              Visibility(
                                visible: !widget.isOwner,
                                child: SizedBox(
                                  width: double.infinity,

                                  child: ReuseableBottomButton(
                                    buttonText:
                                        isIos
                                            ? "Buy Now ${iapPrice != null ? 'for $iapPrice' : ''}"
                                            : "Buy Now for \$${widget.imagePrice}",
                                    onTap: () async {
                                      try {
                                        final priceInCents =
                                            (widget.imagePrice * 100).round();
                                        log(
                                          '🟢 Buy tapped. priceInCents=$priceInCents, imageId=${widget.imageId}',
                                        );

                                        // 1) Take payment
                                        final paid =
                                            await makePaymentAndBuyImage(
                                              priceInCents,
                                            );
                                        log('💳 Payment result: $paid');
                                        if (!paid) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Payment was not completed.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        // 2) Mark as sold
                                        final txId =
                                            _platformPaymentService.getLastIapTransactionId();
                                        await ImageUploadService().markItemSoldAfterPayment(
                                          documentId: widget.imageId!,
                                          paymentMethod: isIos ? 'iap' : 'stripe',
                                          transactionId: isIos ? txId : null,
                                          productId: isIos
                                              ? InAppPurchaseService.imageDownloadProductId
                                              : null,
                                        );
                                        log(
                                          '✅ Marked item sold: ${widget.imageId}',
                                        );

                                        // 3) Email buyer
                                        final buyerEmail =
                                            FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.email;
                                        if (buyerEmail != null &&
                                            buyerEmail.isNotEmpty) {
                                          final buyerOk = await MailSender.send(
                                            toEmail: buyerEmail,
                                            subject: 'Purchase Confirmation',
                                            textBody:
                                                'Hello,\nYou purchased  “${widget.imageTitle}” from lamthi at a cost of \$${widget.imagePrice}',
                                          );
                                          log(
                                            '📧 Buyer email -> $buyerEmail | sent=$buyerOk',
                                          );
                                        } else {
                                          log(
                                            '⚠️ No buyer email available on current user.',
                                          );
                                        }

                                        // 4) Email seller
                                        // Prefer a known seller email prop; otherwise load from Firestore (uploads/{id}.email)
                                        String? sellerEmail = widget.ownerEmail;

                                        if (sellerEmail != null &&
                                            sellerEmail.isNotEmpty) {
                                          // final sellerOk = await MailSender.send(
                                          //   toEmail: 'kngssaim@gmail.com',
                                          //   subject: 'Your item was sold — Lamhti',
                                          //   textBody:
                                          //       'Hello,\n\nGreat news! Your product “${widget.imageTitle}” has been sold for \$${widget.imagePrice}.\n'
                                          //       'Buyer: ${buyerEmail ?? "Lamhti buyer"}\n'
                                          //       'Date: ${DateTime.now().toIso8601String()}\n\n'
                                          //       'We’ll handle the next steps as per your settings.\n\n'
                                          //       '— Lamhti Team',
                                          // );
                                          bool sellerOk = await MailSender.send(
                                            toEmail: sellerEmail,
                                            subject:
                                                'Your item was sold — Lamhti',
                                            textBody:
                                                'Hello,\nCongratulations ! Your product “${widget.imageTitle}” has been sold for \$${widget.imagePrice}.\n'
                                                'Buyer: ${FirebaseAuth.instance.currentUser?.email ?? "Lamhti buyer"}\n'
                                                'Date: ${DateTime.now().toIso8601String()}\n\n'
                                                'We’ll handle the next steps as per your settings.\n\n'
                                                '~TEAM LAMHTI',
                                          );
                                          log(
                                            '📧 Seller email -> $sellerEmail | sent=$sellerOk',
                                          );
                                        } else {
                                          log(
                                            '⚠️ No seller email found for imageId=${widget.imageId}',
                                          );
                                        }

                                        // 5) Done
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Purchase complete. Emails sent.',
                                            ),
                                          ),
                                        );
                                      } catch (e, st) {
                                        log(
                                          '❌ Buy flow error: $e',
                                          stackTrace: st,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                            ),
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
              ],
            ),
          ),
        );
  }
}
