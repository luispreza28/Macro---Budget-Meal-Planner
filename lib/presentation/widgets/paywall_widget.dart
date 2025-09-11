import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/app_constants.dart';
import '../providers/billing_providers.dart';
import '../../data/services/billing_service.dart';
import '../providers/analytics_providers.dart';

/// Paywall widget for displaying Pro features and subscription options
class PaywallWidget extends ConsumerWidget {
  const PaywallWidget({
    Key? key,
    this.onSubscribed,
    this.showCloseButton = true,
    this.highlightFeature,
  }) : super(key: key);

  final VoidCallback? onSubscribed;
  final bool showCloseButton;
  final String? highlightFeature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Track paywall view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsNotifierProvider.notifier).trackPaywallViewed(
        highlightFeature: highlightFeature,
      );
    });
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.1),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showCloseButton)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Header
              Text(
                'Upgrade to Pro',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Unlock all features and take control of your meal planning',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Feature comparison
              Expanded(
                child: _buildFeatureComparison(context, theme),
              ),
              
              const SizedBox(height: 24),
              
              // Subscription options
              _buildSubscriptionOptions(context, ref),
              
              const SizedBox(height: 16),
              
              // Trial info
              _buildTrialInfo(context, ref, theme),
              
              const SizedBox(height: 16),
              
              // Restore purchases button
              TextButton(
                onPressed: () => _restorePurchases(ref),
                child: const Text('Restore Purchases'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context, ThemeData theme) {
    final features = [
      _FeatureItem(
        title: 'Active Plans',
        free: '1 plan',
        pro: 'Unlimited',
        isHighlighted: highlightFeature == 'plans',
      ),
      _FeatureItem(
        title: 'Recipe Library',
        free: '20 recipes',
        pro: '100+ recipes',
        isHighlighted: highlightFeature == 'recipes',
      ),
      _FeatureItem(
        title: 'Pantry-First Planning',
        free: '✗',
        pro: '✓',
        isHighlighted: highlightFeature == 'pantry',
      ),
      _FeatureItem(
        title: 'Swap History',
        free: '✗',
        pro: '✓',
        isHighlighted: highlightFeature == 'history',
      ),
      _FeatureItem(
        title: 'Export CSV/PDF',
        free: '✗',
        pro: '✓',
        isHighlighted: highlightFeature == 'export',
      ),
      _FeatureItem(
        title: 'Multiple Presets',
        free: '1 preset',
        pro: 'Unlimited',
        isHighlighted: highlightFeature == 'presets',
      ),
      _FeatureItem(
        title: 'Priority Support',
        free: '✗',
        pro: '✓',
        isHighlighted: highlightFeature == 'support',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Feature',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Free',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Pro',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Feature rows
            Expanded(
              child: ListView.separated(
                itemCount: features.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return Container(
                    decoration: feature.isHighlighted
                        ? BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            feature.title,
                            style: TextStyle(
                              fontWeight: feature.isHighlighted 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            feature.free,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            feature.pro,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionOptions(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final productsAsync = ref.watch(productsProvider);
        // Note: billingState available for purchase state management if needed
        // final billingState = ref.watch(billingStateProvider);
        
        return productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return const SizedBox.shrink();
            }
            
            final monthlyProduct = products.firstWhere(
              (p) => p.id == BillingService.monthlySubscriptionId,
              orElse: () => products.first,
            );
            
            final annualProduct = products.firstWhere(
              (p) => p.id == BillingService.annualSubscriptionId,
              orElse: () => products.first,
            );
            
            return Column(
              children: [
                // Annual option (recommended)
                _buildSubscriptionOption(
                  context: context,
                  ref: ref,
                  product: annualProduct,
                  isRecommended: true,
                  savings: '50% off',
                ),
                
                const SizedBox(height: 12),
                
                // Monthly option
                _buildSubscriptionOption(
                  context: context,
                  ref: ref,
                  product: monthlyProduct,
                  isRecommended: false,
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Text(
            'Unable to load subscription options',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionOption({
    required BuildContext context,
    required WidgetRef ref,
    required ProductDetails product,
    required bool isRecommended,
    String? savings,
  }) {
    final theme = Theme.of(context);
    final isAnnual = product.id == BillingService.annualSubscriptionId;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isRecommended 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline,
          width: isRecommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          if (isRecommended)
            Positioned(
              top: -1,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAnnual ? 'Annual Plan' : 'Monthly Plan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (savings != null)
                          Text(
                            savings,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          product.price,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isAnnual ? 'per year' : 'per month',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _purchaseProduct(ref, product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecommended 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.secondary,
                      foregroundColor: isRecommended 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Start ${AppConstants.trialDays}-Day Free Trial',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialInfo(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            'Start your ${AppConstants.trialDays}-day free trial. Cancel anytime during the trial period and you won\'t be charged.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseProduct(WidgetRef ref, ProductDetails product) async {
    final billingNotifier = ref.read(billingNotifierProvider.notifier);
    final analyticsNotifier = ref.read(analyticsNotifierProvider.notifier);
    
    // Track purchase attempt
    await analyticsNotifier.trackSubscriptionPurchaseAttempt(
      productId: product.id,
      isAnnual: product.id == BillingService.annualSubscriptionId,
    );
    
    final success = await billingNotifier.purchaseProduct(product);
    
    if (success) {
      // Track purchase success
      await analyticsNotifier.trackSubscriptionPurchaseSuccess(
        productId: product.id,
        isAnnual: product.id == BillingService.annualSubscriptionId,
        wasTrial: true, // Assuming trial for now
      );
      
      if (onSubscribed != null) {
        onSubscribed!();
      }
    }
  }

  Future<void> _restorePurchases(WidgetRef ref) async {
    final billingNotifier = ref.read(billingNotifierProvider.notifier);
    await billingNotifier.restorePurchases();
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.title,
    required this.free,
    required this.pro,
    this.isHighlighted = false,
  });

  final String title;
  final String free;
  final String pro;
  final bool isHighlighted;
}
