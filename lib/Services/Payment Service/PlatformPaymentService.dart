import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lamhti_app/Services/Payment%20Service/InAppPurchaseService.dart';
import 'package:lamhti_app/Utils/Toast.dart';

enum PaymentMethod { inAppPurchase }

/// PlatformPaymentService — IAP-only payment handler
/// 
/// This service processes all in-app purchases through Apple's StoreKit/Google Play Billing.
/// Digital content (images, premium access) must be purchased through IAP on all platforms
/// as per Apple App Store Review Guidelines 3.1.1
class PlatformPaymentService {
  static final PlatformPaymentService _instance = 
      PlatformPaymentService._internal();
  
  late InAppPurchaseService _iapService;
  String? _lastIapTransactionId;

  factory PlatformPaymentService() {
    return _instance;
  }

  PlatformPaymentService._internal() {
    _iapService = InAppPurchaseService();
  }

  /// Initialize IAP service
  Future<void> initialize() async {
    try {
      await _iapService.initialize();
      debugPrint('✅ IAP Payment Service initialized successfully');
    } catch (e) {
      debugPrint('❌ IAP initialization error: $e');
      Toast.toastMessage('Payment service initialization failed', Colors.red);
    }
  }

  /// Get the active payment method (always IAP)
  PaymentMethod getPaymentMethod() {
    return PaymentMethod.inAppPurchase;
  }

  /// Returns true when IAP is ready for purchases
  bool isIAPReady() {
    return _iapService.isAvailable;
  }

  /// Process payment through In-App Purchase (all platforms)
  /// 
  /// [amountInCents] - Price in cents (for reference/analytics only)
  /// [imageId] - Image identifier (for backend recording)
  /// [accountId] - Seller/account identifier 
  /// [productId] - IAP product ID (e.g., 'com.lamhti.image_download')
  Future<bool> processPayment({
    required int amountInCents,
    required String imageId,
    required String accountId,
    required String productId,
  }) async {
    try {
      // Ensure IAP is available before attempting purchase
      if (!_iapService.isAvailable) {
        await _iapService.initialize();
      }

      if (!_iapService.isAvailable) {
        Toast.toastMessage(
          'In-App Purchase service is currently unavailable. Please check your device settings.',
          Colors.red,
        );
        return false;
      }

      debugPrint('🛒 Processing IAP payment for product: $productId');
      
      final purchase = await _iapService.purchaseAndWait(productId);
      if (purchase == null) {
        Toast.toastMessage('Purchase was not completed', Colors.red);
        return false;
      }

      // Store transaction ID for reference
      _lastIapTransactionId = purchase.purchaseID ??
          (purchase.verificationData.serverVerificationData.isNotEmpty
              ? purchase.verificationData.serverVerificationData
              : purchase.verificationData.localVerificationData);

      debugPrint('✅ Payment successful - Transaction: $_lastIapTransactionId');
      return true;
      
    } catch (e) {
      debugPrint('❌ Payment processing error: $e');
      Toast.toastMessage('Payment failed: $e', Colors.red);
      return false;
    }
  }

  /// Check if user has purchased a specific product
  bool isPurchased(String productId) {
    return _iapService.isPurchased(productId);
  }

  /// Get product price for display (from App Store/Play Store)
  String? getProductPrice(String productId) {
    return _iapService.getProductPrice(productId);
  }

  /// Get last successful transaction ID from this session
  String? getLastIapTransactionId() => _lastIapTransactionId;

  /// Dispose resources
  Future<void> dispose() async {
    await _iapService.dispose();
  }
}
