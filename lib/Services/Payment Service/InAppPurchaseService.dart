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
  final Map<String, Completer<PurchaseDetails>> _pendingPurchaseCompleters = {};
  PurchaseDetails? _lastSuccessfulPurchase;

  factory InAppPurchaseService() {
    return _instance;
  }

  InAppPurchaseService._internal();

  // Product IDs - Match these with App Store Connect and Google Play Console
  static const String imageDownloadProductId = 'com.lamhti.lamhtiapp.image_download';
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

  /// Initiates a purchase and resolves once StoreKit/Play reports success or error.
  Future<PurchaseDetails?> purchaseAndWait(
    String productId, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    try {
      if (!_isAvailable) {
        Toast.toastMessage('In-App Purchase not available', Colors.red);
        return null;
      }

      if (!_products.containsKey(productId)) {
        Toast.toastMessage('Product not found', Colors.red);
        return null;
      }

      final ProductDetails product = _products[productId]!;
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Create a completer BEFORE initiating so we can't miss the callback.
      _pendingPurchaseCompleters[productId]?.completeError(
        StateError('A new purchase was started while another was pending.'),
      );
      final completer = Completer<PurchaseDetails>();
      _pendingPurchaseCompleters[productId] = completer;

      // For image downloads we treat it as a consumable (one purchase per image).
      if (productId == imageDownloadProductId) {
        await _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam,
          autoConsume: true,
        );
      } else {
        // Non-consumable/subscription
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }

      final details = await completer.future.timeout(timeout);
      return details;
    } catch (e) {
      debugPrint('Error purchasing product: $e');
      Toast.toastMessage('Purchase failed: $e', Colors.red);
      // If initiation failed, unblock any waiters.
      final c = _pendingPurchaseCompleters.remove(productId);
      if (c != null && !c.isCompleted) {
        c.completeError(e);
      }
      return null;
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
        final c = _pendingPurchaseCompleters.remove(purchaseDetails.productID);
        if (c != null && !c.isCompleted) {
          c.completeError(purchaseDetails.error ?? StateError('Purchase error'));
        }
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        debugPrint('Purchase restored: ${purchaseDetails.productID}');
        _purchases.add(purchaseDetails);
        // Restores can also satisfy a waiting purchase flow in rare cases.
        final c = _pendingPurchaseCompleters.remove(purchaseDetails.productID);
        if (c != null && !c.isCompleted) {
          c.complete(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        debugPrint('Purchase completed: ${purchaseDetails.productID}');
        
        // Verify purchase if needed (for your backend)
        await _verifyPurchase(purchaseDetails);
        
        _purchases.add(purchaseDetails);
        _lastSuccessfulPurchase = purchaseDetails;
        Toast.toastMessage('Purchase successful!', Colors.green);

        final c = _pendingPurchaseCompleters.remove(purchaseDetails.productID);
        if (c != null && !c.isCompleted) {
          c.complete(purchaseDetails);
        }
      }

      // Complete purchase for consumable items (if needed)
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    } catch (e) {
      debugPrint('Error updating purchase status: $e');
      final c = _pendingPurchaseCompleters.remove(purchaseDetails.productID);
      if (c != null && !c.isCompleted) {
        c.completeError(e);
      }
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

  bool get isAvailable => _isAvailable;

  /// The last successful StoreKit/Play purchase reported in this session.
  PurchaseDetails? getLastSuccessfulPurchase() => _lastSuccessfulPurchase;

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
