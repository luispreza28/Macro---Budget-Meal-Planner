import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/user_targets_providers.dart';
import '../../providers/billing_providers.dart';
import '../../../data/services/billing_service.dart';
import '../../router/app_router.dart';
import '../../widgets/paywall_widget.dart';

/// Comprehensive settings page with all user preferences and app configuration
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _dynamicTypeEnabled = true;
  bool _highContrastEnabled = false;
  String _selectedUnits = 'metric';
  String _selectedCurrency = 'USD';

  @override
  Widget build(BuildContext context) {
    final userTargetsAsync = ref.watch(currentUserTargetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop() ? const BackButton() : null,
      ),
      body: ListView(
        children: [
          // User Profile Section
          userTargetsAsync.when(
            loading: () => const _LoadingSection(),
            error: (error, stack) => _ErrorSection(error: error.toString()),
            data: (targets) => _UserProfileSection(targets: targets),
          ),

          const SizedBox(height: 16),

          // App Preferences Section
          _buildSectionHeader('App Preferences'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme'),
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() => _darkModeEnabled = value);
                    _showFeatureNotImplemented();
                  },
                  secondary: const Icon(Icons.dark_mode),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Units'),
                  subtitle: Text(_selectedUnits == 'metric' ? 'Metric (kg, cm)' : 'Imperial (lbs, ft)'),
                  trailing: DropdownButton<String>(
                    value: _selectedUnits,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'metric', child: Text('Metric')),
                      DropdownMenuItem(value: 'imperial', child: Text('Imperial')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedUnits = value);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Currency'),
                  subtitle: Text(_selectedCurrency),
                  trailing: DropdownButton<String>(
                    value: _selectedCurrency,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                      DropdownMenuItem(value: 'CAD', child: Text('CAD (\$)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCurrency = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Accessibility Section
          _buildSectionHeader('Accessibility'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dynamic Type'),
                  subtitle: const Text('Respect system font size'),
                  value: _dynamicTypeEnabled,
                  onChanged: (value) {
                    setState(() => _dynamicTypeEnabled = value);
                  },
                  secondary: const Icon(Icons.text_fields),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('High Contrast'),
                  subtitle: const Text('Increase color contrast'),
                  value: _highContrastEnabled,
                  onChanged: (value) {
                    setState(() => _highContrastEnabled = value);
                    _showFeatureNotImplemented();
                  },
                  secondary: const Icon(Icons.contrast),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Meal reminders and updates'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _showFeatureNotImplemented();
                  },
                  secondary: const Icon(Icons.notifications),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Meal Reminders'),
                  subtitle: const Text('Set reminder times'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showFeatureNotImplemented,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pro Features Section
          _buildProFeaturesSection(),

          const SizedBox(height: 16),

          // Data & Privacy Section
          _buildSectionHeader('Data & Privacy'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data'),
                  subtitle: const Text('Download your meal plans and data'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _exportUserData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Reset app to initial state'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showClearDataDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // About Section
          _buildSectionHeader('About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('Version'),
                  subtitle: Text('1.0.0 (Build 1)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openPrivacyPolicy,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openTermsOfService,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openSupport,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Reset to onboarding button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _resetToOnboarding,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Setup'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showFeatureNotImplemented() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature will be available in a future update'),
      ),
    );
  }

  Widget _buildProFeaturesSection() {
    final proStatusAsync = ref.watch(proStatusProvider);
    final subscriptionInfoAsync = ref.watch(subscriptionInfoProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Pro Features'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: proStatusAsync.when(
            data: (isPro) => Column(
              children: [
                if (isPro) ...[
                  // Current subscription info
                  subscriptionInfoAsync.when(
                    data: (subscriptionInfo) => _buildSubscriptionInfoTile(subscriptionInfo),
                    loading: () => const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading subscription info...'),
                    ),
                    error: (error, stack) => ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: const Text('Error loading subscription'),
                      subtitle: Text(error.toString()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Manage Subscription'),
                    subtitle: const Text('Change plan or cancel subscription'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _openSubscriptionManagement,
                  ),
                ] else ...[
                  // Upgrade to Pro
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.workspace_premium, color: Colors.white),
                    ),
                    title: const Text('Upgrade to Pro'),
                    subtitle: const Text('Unlock all features with 7-day free trial'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showPaywall,
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Purchases'),
                  subtitle: const Text('Restore previous Pro purchase'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _restorePurchases,
                ),
              ],
            ),
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading Pro status...'),
            ),
            error: (error, stack) => ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: const Text('Error loading Pro status'),
              subtitle: Text(error.toString()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionInfoTile(SubscriptionInfo? subscriptionInfo) {
    if (subscriptionInfo == null) {
      return const ListTile(
        leading: Icon(Icons.workspace_premium, color: Colors.amber),
        title: Text('Pro Active'),
        subtitle: Text('Subscription details unavailable'),
      );
    }

    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber, Colors.orange],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.workspace_premium, color: Colors.white),
      ),
      title: Text('Pro ${subscriptionInfo.isMonthly ? 'Monthly' : 'Annual'}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${subscriptionInfo.price}/mo'),
          if (subscriptionInfo.isInTrial)
            Text(
              'Trial active',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  void _showPaywall() {
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

  Future<void> _restorePurchases() async {
    final billingNotifier = ref.read(billingNotifierProvider.notifier);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restoring purchases...')),
    );
    
    try {
      await billingNotifier.restorePurchases();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchases restored successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore purchases: $e')),
      );
    }
  }

  Future<void> _openSubscriptionManagement() async {
    final billingNotifier = ref.read(billingNotifierProvider.notifier);
    await billingNotifier.openSubscriptionManagement();
  }

  void _exportUserData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export will be available in Stage 5'),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your meal plans, pantry items, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    // TODO: Implement data clearing in Stage 5
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data clearing functionality will be implemented in Stage 5'),
      ),
    );
  }

  void _resetToOnboarding() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Setup'),
        content: const Text(
          'This will take you back to the initial setup process. Your data will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRouter.onboarding);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy policy link will be available in production'),
      ),
    );
  }

  void _openTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms of service link will be available in production'),
      ),
    );
  }

  void _openSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support contact will be available in production'),
      ),
    );
  }
}

class _UserProfileSection extends StatelessWidget {
  const _UserProfileSection({required this.targets});

  final dynamic targets;

  @override
  Widget build(BuildContext context) {
    if (targets == null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No Profile Setup'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => context.go(AppRouter.onboarding),
                child: const Text('Complete Setup'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Your Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(AppRouter.onboarding),
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileItem(
              label: 'Daily Calories',
              value: '${targets.kcal.toStringAsFixed(0)} kcal',
            ),
            _ProfileItem(
              label: 'Protein Target',
              value: '${targets.proteinG.toStringAsFixed(0)}g',
            ),
            if (targets.budgetCents != null)
              _ProfileItem(
                label: 'Weekly Budget',
                value: '\$${(targets.budgetCents! / 100).toStringAsFixed(2)}',
              ),
            _ProfileItem(
              label: 'Meals per Day',
              value: '${targets.mealsPerDay}',
            ),
            _ProfileItem(
              label: 'Planning Mode',
              value: targets.planningMode.displayName,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading profile: $error'),
          ],
        ),
      ),
    );
  }
}
