import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../data/services/billing_service.dart';
import '../../data/services/local_storage_service.dart';
import 'local_storage_providers.dart';

/// Provider for the billing service instance
final billingServiceProvider = Provider<BillingService>((ref) {
  return BillingService();
});

/// Provider for billing state
final billingStateProvider = StreamProvider<BillingState>((ref) {
  final billingService = ref.watch(billingServiceProvider);
  return billingService.stateStream;
});

/// Provider for available products
final productsProvider = StreamProvider<List<ProductDetails>>((ref) {
  final billingService = ref.watch(billingServiceProvider);
  return billingService.productsStream;
});

/// Provider for purchase updates
final purchaseStreamProvider = StreamProvider<PurchaseDetails>((ref) {
  final billingService = ref.watch(billingServiceProvider);
  return billingService.purchaseStream;
});

/// Provider for subscription status
final subscriptionStatusProvider = FutureProvider<bool>((ref) {
  final billingService = ref.watch(billingServiceProvider);
  return billingService.isSubscribed();
});

/// Provider for subscription info
final subscriptionInfoProvider = FutureProvider<SubscriptionInfo?>((ref) {
  final billingService = ref.watch(billingServiceProvider);
  return billingService.getSubscriptionInfo();
});

/// Provider for Pro status (combines subscription and local storage)
final proStatusProvider = FutureProvider<bool>((ref) async {
  // Check both subscription status and local storage
  final billingService = ref.watch(billingServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  
  // First check local storage for quick access
  final localProStatus = localStorage.getProSubscriptionStatus();
  
  // Then verify with billing service
  final isSubscribed = await billingService.isSubscribed();
  
  // Update local storage if there's a discrepancy
  if (localProStatus != isSubscribed) {
    await localStorage.setProSubscriptionStatus(isSubscribed);
  }
  
  return isSubscribed;
});

/// Provider for trial status
final trialStatusProvider = FutureProvider<TrialStatus>((ref) async {
  final subscriptionInfo = await ref.watch(subscriptionInfoProvider.future);
  final localStorage = ref.watch(localStorageServiceProvider);
  
  if (subscriptionInfo != null && subscriptionInfo.isInTrial) {
    return TrialStatus.active;
  }
  
  // Check if trial was already used
  final trialUsed = localStorage.getJsonData('trial_info')?['used'] ?? false;
  if (trialUsed) {
    return TrialStatus.expired;
  }
  
  return TrialStatus.available;
});

/// Provider for monthly product details
final monthlyProductProvider = Provider<ProductDetails?>((ref) {
  final products = ref.watch(productsProvider).value ?? [];
  try {
    return products.firstWhere(
      (product) => product.id == BillingService.monthlySubscriptionId,
    );
  } catch (e) {
    return null;
  }
});

/// Provider for annual product details
final annualProductProvider = Provider<ProductDetails?>((ref) {
  final products = ref.watch(productsProvider).value ?? [];
  try {
    return products.firstWhere(
      (product) => product.id == BillingService.annualSubscriptionId,
    );
  } catch (e) {
    return null;
  }
});

/// Notifier for managing billing operations
class BillingNotifier extends StateNotifier<AsyncValue<void>> {
  BillingNotifier(this._billingService, this._localStorage) 
      : super(const AsyncValue.data(null));

  final BillingService _billingService;
  final LocalStorageService _localStorage;

  Future<bool> purchaseProduct(ProductDetails product) async {
    state = const AsyncValue.loading();
    
    try {
      final success = await _billingService.purchaseProduct(product);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    
    try {
      await _billingService.restorePurchases();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> startTrial() async {
    state = const AsyncValue.loading();
    
    try {
      // Mark trial as started in local storage
      await _localStorage.setJsonData('trial_info', {
        'started': DateTime.now().toIso8601String(),
        'used': true,
      });
      
      // Set Pro status temporarily for trial period
      await _localStorage.setProSubscriptionStatus(true);
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> openSubscriptionManagement() async {
    try {
      await _billingService.openSubscriptionManagement();
    } catch (e) {
      // Handle silently as this is a best-effort operation
    }
  }

  Future<void> updateProStatus(bool isActive) async {
    try {
      await _localStorage.setProSubscriptionStatus(isActive);
    } catch (e) {
      // Handle silently
    }
  }
}

/// Provider for billing notifier
final billingNotifierProvider = StateNotifierProvider<BillingNotifier, AsyncValue<void>>((ref) {
  final billingService = ref.watch(billingServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return BillingNotifier(billingService, localStorage);
});

/// Trial status enumeration
enum TrialStatus {
  available,
  active,
  expired,
}

/// Extension for trial status helpers
extension TrialStatusExtension on TrialStatus {
  bool get isAvailable => this == TrialStatus.available;
  bool get isActive => this == TrialStatus.active;
  bool get isExpired => this == TrialStatus.expired;
  
  String get displayText {
    switch (this) {
      case TrialStatus.available:
        return '7-day free trial available';
      case TrialStatus.active:
        return 'Trial active';
      case TrialStatus.expired:
        return 'Trial expired';
    }
  }
}
