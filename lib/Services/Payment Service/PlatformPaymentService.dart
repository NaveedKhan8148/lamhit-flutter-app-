import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:lamhti_app/API%20Models/PaymentIntentAPIModel.dart';
import 'package:lamhti_app/Services/Payment%20Service/InAppPurchaseService.dart';
import 'package:lamhti_app/Utils/Toast.dart';

enum PaymentMethod { stripe, inAppPurchase }

class PlatformPaymentService {
  static final PlatformPaymentService _instance = 
      PlatformPaymentService._internal();
  
  late InAppPurchaseService _iapService;
  String? _lastIapTransactionId;
  
  // Configuration
  final bool _forceIAPOnAndroid = false; // Set to true to use IAP on Android

  factory PlatformPaymentService() {
    return _instance;
  }

  PlatformPaymentService._internal() {
    _iapService = InAppPurchaseService();
  }

  Future<void> initialize() async {
    if (_shouldUseIAP()) {
      await _iapService.initialize();
      debugPrint('IAP initialized for iOS');
    } else {
      debugPrint('Using non-iOS payment provider');
    }
  }

  /// Determines if IAP should be used based on platform
  bool _shouldUseIAP() {
    if (Platform.isIOS) {
      return true; // Always use IAP on iOS (App Store requirement)
    } else if (Platform.isAndroid && _forceIAPOnAndroid) {
      return true; // Use IAP on Android if configured
    }
    return false;
  }

  /// Get the active payment method for current platform
  PaymentMethod getPaymentMethod() {
    return _shouldUseIAP() ? PaymentMethod.inAppPurchase : PaymentMethod.stripe;
  }

  /// Returns true when iOS IAP is required and successfully initialized.
  bool isIAPReady() {
    return _shouldUseIAP() && _iapService.isAvailable;
  }

  /// Unified payment flow - handles platform-specific payment
  Future<bool> processPayment({
    required int amountInCents,
    required String imageId,
    required String accountId,
    required String productId, // For IAP: use InAppPurchaseService.imageDownloadProductId
  }) async {
    try {
      if (_shouldUseIAP()) {
        if (!_iapService.isAvailable) {
          // Retry initialization to avoid false negatives from app startup timing.
          await _iapService.initialize();
        }
        if (!_iapService.isAvailable) {
          Toast.toastMessage(
            'Apple In-App Purchase is currently unavailable.',
            Colors.red,
          );
          return false;
        }
        return await _processIAPPayment(productId: productId);
      } else {
        return await _processStripePayment(
          amountInCents: amountInCents,
          accountId: accountId,
        );
      }
    } catch (e) {
      debugPrint('Payment processing error: $e');
      Toast.toastMessage('Payment error: $e', Colors.red);
      return false;
    }
  }

  /// Process payment via In-App Purchase (iOS/Android)
  Future<bool> _processIAPPayment({
    required String productId,
  }) async {
    try {
      debugPrint('Processing IAP payment for product: $productId');
      
      final purchase = await _iapService.purchaseAndWait(productId);
      if (purchase == null) {
        Toast.toastMessage('Purchase not completed', Colors.red);
        return false;
      }

      _lastIapTransactionId = purchase.purchaseID ??
          (purchase.verificationData.serverVerificationData.isNotEmpty
              ? purchase.verificationData.serverVerificationData
              : purchase.verificationData.localVerificationData);

      return true;
    } catch (e) {
      debugPrint('IAP payment error: $e');
      Toast.toastMessage('Purchase failed: $e', Colors.red);
      return false;
    }
  }

  /// Process payment via non-iOS provider (Android/Web)
  Future<bool> _processStripePayment({
    required int amountInCents,
    required String accountId,
  }) async {
    try {
      if (Platform.isIOS) {
        Toast.toastMessage(
          'Digital content purchases on iOS must use Apple In-App Purchase.',
          Colors.red,
        );
        return false;
      }

      debugPrint('Processing non-iOS payment');
      
      // Create payment intent
      final paymentIntent = 
          await _createStripePaymentIntent(amountInCents, accountId);
      
      if (paymentIntent == null) {
        Toast.toastMessage('Unable to create payment', Colors.red);
        return false;
      }

      // Open payment sheet
      return await _openStripePaymentSheet(paymentIntent.clientSecret!);
    } catch (e) {
      debugPrint('Non-iOS payment error: $e');
      Toast.toastMessage('Payment error: $e', Colors.red);
      return false;
    }
  }

  /// Create payment intent for non-iOS provider
  Future<PaymentIntentAPIModel?> _createStripePaymentIntent(
    int amountInCents,
    String accountId,
  ) async {
    try {
      final url = Uri.parse(
        "https://lamhti-backend-kn795pm9z-lamhtis-projects.vercel.app/api/createPaymentIntent",
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"amount": amountInCents, "accountId": accountId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentIntentAPIModel.fromJson(data);
      } else {
        debugPrint('Failed to create payment intent: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      Toast.toastMessage('Unable to create payment', Colors.red);
      return null;
    }
  }

  /// Open non-iOS payment sheet
  Future<bool> _openStripePaymentSheet(String clientSecret) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: "Lamhti",
          style: ThemeMode.light,
          customFlow: false,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      
      Toast.toastMessage("Payment Successful!", Colors.green);
      return true;
    } on StripeException catch (e) {
      debugPrint("Payment Cancelled: ${e.error.localizedMessage}");
      Toast.toastMessage("Payment Cancelled!", Colors.red);
      return false;
    } catch (e) {
      debugPrint("Payment provider error: $e");
      Toast.toastMessage("Payment failed: $e", Colors.red);
      return false;
    }
  }

  /// Check if user has IAP product purchased
  bool isPurchased(String productId) {
    if (_shouldUseIAP()) {
      return _iapService.isPurchased(productId);
    }
    return false;
  }

  /// Get product price (for display)
  String? getProductPrice(String productId) {
    if (_shouldUseIAP()) {
      return _iapService.getProductPrice(productId);
    }
    return null;
  }

  /// Best-effort transaction id for the last successful IAP (this session).
  String? getLastIapTransactionId() => _lastIapTransactionId;

  Future<void> dispose() async {
    if (_shouldUseIAP()) {
      await _iapService.dispose();
    }
  }
}
