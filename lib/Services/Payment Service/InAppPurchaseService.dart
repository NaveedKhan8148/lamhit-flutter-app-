import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lamhti_app/Utils/Toast.dart';

class InAppPurchaseService {
  static final InAppPurchaseService _instance = InAppPurchaseService._internal();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  
  final Map<String, ProductDetails> _products = {};
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;

  factory InAppPurchaseService() {
    return _instance;
  }

  InAppPurchaseService._internal();

  // Product IDs - Match these with App Store Connect and Google Play Console
  static const String imageDownloadProductId = 'com.lamhti.lamhti_mobile';
  static const String premiumAccessProductId = 'com.lamhti.premium_access';

  Future<void> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        debugPrint('In-App Purchase not available on this device');
        return;
      }

      // Load products
      await _loadProducts();

      // Listen to purchase stream
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onError: (error) {
          debugPrint('Purchase Stream Error: $error');
          Toast.toastMessage('Purchase error: $error', Colors.red);
        },
      );

      // Restore previous purchases
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Error initializing IAP: $e');
      Toast.toastMessage('Unable to initialize payments', Colors.red);
    }
  }

  Future<void> _loadProducts() async {
    try {
      const productIds = {
        imageDownloadProductId,
        premiumAccessProductId,
      };

      ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      for (ProductDetails product in response.productDetails) {
        _products[product.id] = product;
        debugPrint('Loaded product: ${product.id} - ${product.title}');
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Future<bool> purchaseProduct(String productId) async {
    try {
      if (!_isAvailable) {
        Toast.toastMessage('In-App Purchase not available', Colors.red);
        return false;
      }

      if (!_products.containsKey(productId)) {
        Toast.toastMessage('Product not found', Colors.red);
        return false;
      }

      final ProductDetails product = _products[productId]!;
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return true; // Purchase initiated, will be confirmed in stream
    } catch (e) {
      debugPrint('Error purchasing product: $e');
      Toast.toastMessage('Purchase failed: $e', Colors.red);
      return false;
    }
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _updatePurchaseStatus(purchaseDetails);
    }
  }

  Future<void> _updatePurchaseStatus(PurchaseDetails purchaseDetails) async {
    try {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending: ${purchaseDetails.productID}');
        Toast.toastMessage('Processing purchase...', Colors.blue);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchaseDetails.error}');
        Toast.toastMessage('Purchase failed: ${purchaseDetails.error}', Colors.red);
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        debugPrint('Purchase restored: ${purchaseDetails.productID}');
        _purchases.add(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        debugPrint('Purchase completed: ${purchaseDetails.productID}');
        
        // Verify purchase if needed (for your backend)
        await _verifyPurchase(purchaseDetails);
        
        _purchases.add(purchaseDetails);
        Toast.toastMessage('Purchase successful!', Colors.green);
      }

      // Complete purchase for consumable items (if needed)
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    } catch (e) {
      debugPrint('Error updating purchase status: $e');
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // You can send the receipt to your backend for verification
      debugPrint('Purchase receipt: ${purchaseDetails.verificationData.localVerificationData}');
      // TODO: Send receipt to backend for server-side verification
    } catch (e) {
      debugPrint('Error verifying purchase: $e');
    }
  }

  bool isPurchased(String productId) {
    return _purchases.any((p) => p.productID == productId && p.status == PurchaseStatus.purchased);
  }

  ProductDetails? getProduct(String productId) {
    return _products[productId];
  }

  List<ProductDetails> getAllProducts() {
    return _products.values.toList();
  }

  String? getProductPrice(String productId) {
    return _products[productId]?.price;
  }

  Future<void> dispose() async {
    await _purchaseSubscription.cancel();
  }
}
