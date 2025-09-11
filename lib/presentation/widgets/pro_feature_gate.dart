import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/billing_providers.dart';
import '../providers/analytics_providers.dart';
import 'paywall_widget.dart';

/// Widget that gates Pro features and shows paywall when needed
class ProFeatureGate extends ConsumerWidget {
  const ProFeatureGate({
    Key? key,
    required this.child,
    this.fallback,
    this.featureName,
    this.showPaywall = true,
    this.onProRequired,
  }) : super(key: key);

  /// The widget to show when user has Pro access
  final Widget child;
  
  /// Widget to show when user doesn't have Pro (if showPaywall is false)
  final Widget? fallback;
  
  /// Name of the feature being gated (for analytics/highlighting)
  final String? featureName;
  
  /// Whether to show paywall when Pro is required
  final bool showPaywall;
  
  /// Callback when Pro is required but user doesn't have it
  final VoidCallback? onProRequired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proStatusAsync = ref.watch(proStatusProvider);
    
    return proStatusAsync.when(
      data: (isPro) {
        if (isPro) {
          // Track Pro feature access
          if (featureName != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(analyticsNotifierProvider.notifier).trackProFeatureAccessed(
                feature: featureName!,
              );
            });
          }
          return child;
        } else {
          // Track Pro feature blocked
          if (featureName != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(analyticsNotifierProvider.notifier).trackProFeatureBlocked(
                feature: featureName!,
                showedPaywall: showPaywall,
              );
            });
          }
          
          if (onProRequired != null) {
            onProRequired!();
          }
          
          if (showPaywall) {
            return _buildProRequiredPrompt(context, ref);
          } else if (fallback != null) {
            return fallback!;
          } else {
            return const SizedBox.shrink();
          }
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => fallback ?? const SizedBox.shrink(),
    );
  }

  Widget _buildProRequiredPrompt(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Pro Feature',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _getFeatureDescription(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Maybe Later'),
              ),
              
              ElevatedButton.icon(
                onPressed: () => _showPaywall(context),
                icon: const Icon(Icons.upgrade),
                label: const Text('Upgrade to Pro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFeatureDescription() {
    switch (featureName) {
      case 'pantry':
        return 'Save money by using ingredients you already have with Pantry-First planning.';
      case 'plans':
        return 'Create unlimited meal plans and save multiple presets for different goals.';
      case 'recipes':
        return 'Access our full library of 100+ recipes optimized for macro and budget goals.';
      case 'export':
        return 'Export your shopping lists as CSV or PDF files for easy sharing and printing.';
      case 'history':
        return 'Keep track of your meal swaps and see what works best for your goals.';
      case 'presets':
        return 'Save multiple target presets for cutting, bulking, and maintenance phases.';
      default:
        return 'This feature requires a Pro subscription to unlock its full potential.';
    }
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: PaywallWidget(
          highlightFeature: featureName,
          onSubscribed: () {
            Navigator.of(context).pop();
            // The UI will automatically update due to provider changes
          },
        ),
      ),
    );
  }
}

/// Simple Pro badge widget
class ProBadge extends StatelessWidget {
  const ProBadge({
    Key? key,
    this.size = 16,
  }) : super(key: key);

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.5,
        vertical: size * 0.25,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.5),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: size * 0.75,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Widget that shows Pro status indicator
class ProStatusIndicator extends ConsumerWidget {
  const ProStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proStatusAsync = ref.watch(proStatusProvider);
    final theme = Theme.of(context);
    
    return proStatusAsync.when(
      data: (isPro) {
        if (isPro) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium,
                color: theme.colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Pro',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        } else {
          return TextButton.icon(
            onPressed: () => _showPaywall(context),
            icon: const Icon(Icons.upgrade, size: 16),
            label: const Text('Upgrade'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }
      },
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: const PaywallWidget(),
      ),
    );
  }
}
