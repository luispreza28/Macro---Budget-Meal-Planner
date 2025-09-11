import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../core/constants/app_constants.dart';

/// Service for handling Google Play Billing and subscription management
class BillingService {
  BillingService() {
    _initialize();
  }

  static const String monthlySubscriptionId = 'macro_planner_monthly';
  static const String annualSubscriptionId = 'macro_planner_annual';
  
  static const Set<String> productIds = {
    monthlySubscriptionId,
    annualSubscriptionId,
  };

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  final StreamController<BillingState> _stateController = StreamController<BillingState>.broadcast();
  final StreamController<List<ProductDetails>> _productsController = StreamController<List<ProductDetails>>.broadcast();
  final StreamController<PurchaseDetails> _purchaseController = StreamController<PurchaseDetails>.broadcast();

  BillingState _currentState = BillingState.loading;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  // Getters for current state
  BillingState get currentState => _currentState;
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  
  // Streams for UI updates
  Stream<BillingState> get stateStream => _stateController.stream;
  Stream<List<ProductDetails>> get productsStream => _productsController.stream;
  Stream<PurchaseDetails> get purchaseStream => _purchaseController.stream;

  Future<void> _initialize() async {
    try {
      _updateState(BillingState.loading);
      
      // Check if the store is available
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        _updateState(BillingState.unavailable);
        return;
      }

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription.cancel(),
        onError: (error) {
          debugPrint('Purchase stream error: $error');
          _updateState(BillingState.error);
        },
      );

      // Load products
      await _loadProducts();
      
      // Restore purchases
      await restorePurchases();

    } catch (e) {
      debugPrint('Billing initialization error: $e');
      _updateState(BillingState.error);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        debugPrint('Product query error: ${response.error}');
        _updateState(BillingState.error);
        return;
      }

      _products = response.productDetails;
      _productsController.add(_products);
      
      if (_currentState == BillingState.loading) {
        _updateState(BillingState.ready);
      }
    } catch (e) {
      debugPrint('Load products error: $e');
      _updateState(BillingState.error);
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _purchaseController.add(purchaseDetails);
      
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('Purchase pending: ${purchaseDetails.productID}');
          break;
        case PurchaseStatus.purchased:
          debugPrint('Purchase completed: ${purchaseDetails.productID}');
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.restored:
          debugPrint('Purchase restored: ${purchaseDetails.productID}');
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          debugPrint('Purchase error: ${purchaseDetails.error}');
          _updateState(BillingState.error);
          break;
        case PurchaseStatus.canceled:
          debugPrint('Purchase canceled: ${purchaseDetails.productID}');
          break;
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    // Verify the purchase (in production, verify with your backend)
    if (_isValidPurchase(purchaseDetails)) {
      _updateState(BillingState.subscribed);
    }
  }

  bool _isValidPurchase(PurchaseDetails purchaseDetails) {
    // Basic validation - in production, implement proper server-side verification
    return purchaseDetails.verificationData.localVerificationData.isNotEmpty &&
           productIds.contains(purchaseDetails.productID);
  }

  Future<bool> purchaseProduct(ProductDetails product) async {
    if (!_isAvailable) {
      debugPrint('Store not available');
      return false;
    }

    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      if (product.id == monthlySubscriptionId || product.id == annualSubscriptionId) {
        return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
      
      return false;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('Store not available for restore');
      return;
    }

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases error: $e');
    }
  }

  Future<bool> isSubscribed() async {
    if (!_isAvailable) return false;

    try {
      // Restore purchases to get latest state
      await _inAppPurchase.restorePurchases();
      
      // Check current subscription state (simplified approach)
      return _currentState == BillingState.subscribed;
    } catch (e) {
      debugPrint('Check subscription error: $e');
      return false;
    }
  }

  // Removed unused method - functionality moved to main subscription check

  Future<SubscriptionInfo?> getSubscriptionInfo() async {
    if (!await isSubscribed()) return null;

    try {
      // Restore purchases to get latest state
      await _inAppPurchase.restorePurchases();
      
      // Return mock subscription info for now
      if (_products.isNotEmpty) {
        final product = _products.first;
        return SubscriptionInfo(
          productId: product.id,
          productTitle: product.title,
          productDescription: product.description,
          price: product.price,
          purchaseDate: DateTime.now().subtract(const Duration(days: 7)),
          isActive: _currentState == BillingState.subscribed,
          isInTrial: false, // Simplified for now
        );
      }
    } catch (e) {
      debugPrint('Get subscription info error: $e');
    }
    
    return null;
  }

  // Removed unused method - functionality moved to SubscriptionInfo class

  Future<void> openSubscriptionManagement() async {
    if (Platform.isAndroid) {
      try {
        // Get Android-specific additions for subscription management
        // Note: androidAddition would be used for advanced subscription management
        // For now, just log the action
        debugPrint('Opening subscription management in Google Play');
      } catch (e) {
        debugPrint('Open subscription management error: $e');
      }
    }
  }

  void _updateState(BillingState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
    }
  }

  void dispose() {
    _subscription.cancel();
    _stateController.close();
    _productsController.close();
    _purchaseController.close();
  }
}

/// Represents the current state of the billing system
enum BillingState {
  loading,
  ready,
  subscribed,
  unavailable,
  error,
}

/// Information about the user's subscription
class SubscriptionInfo {
  const SubscriptionInfo({
    required this.productId,
    required this.productTitle,
    required this.productDescription,
    required this.price,
    required this.purchaseDate,
    required this.isActive,
    required this.isInTrial,
  });

  final String productId;
  final String productTitle;
  final String productDescription;
  final String price;
  final DateTime purchaseDate;
  final bool isActive;
  final bool isInTrial;

  bool get isMonthly => productId == BillingService.monthlySubscriptionId;
  bool get isAnnual => productId == BillingService.annualSubscriptionId;
}
