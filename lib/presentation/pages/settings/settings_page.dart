import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/user_targets_providers.dart';
import '../../providers/billing_providers.dart';
import '../../../data/services/billing_service.dart';
import '../../router/app_router.dart';
import '../../widgets/paywall_widget.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/database_providers.dart';
import '../../../domain/entities/ingredient.dart';
import '../../../domain/services/variety_prefs_service.dart';
import '../../providers/nutrition_lookup_providers.dart';
import '../../../domain/services/nutrition_lookup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Variety & Repetition prefs
  bool _loadingVariety = true;
  int _maxRepeatsPerWeek = 1; // 1..2
  bool _enableProteinSpread = true;
  bool _enableCuisineRotation = true;
  bool _enablePrepMix = true;
  int _historyLookbackPlans = 2; // 0..4

  // Nutrition APIs local state
  final TextEditingController _fdcKeyCtrl = TextEditingController();
  String _offRegion = 'world';
  bool _loadingNutritionPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadVarietyPrefs();
    _loadNutritionPrefs();
  }

  Future<void> _loadVarietyPrefs() async {
    final svc = ref.read(varietyPrefsServiceProvider);
    final maxRep = await svc.maxRepeatsPerWeek();
    final prot = await svc.enableProteinSpread();
    final cui = await svc.enableCuisineRotation();
    final prep = await svc.enablePrepMix();
    final hist = await svc.historyLookbackPlans();
    if (!mounted) return;
    setState(() {
      _maxRepeatsPerWeek = maxRep;
      _enableProteinSpread = prot;
      _enableCuisineRotation = cui;
      _enablePrepMix = prep;
      _historyLookbackPlans = hist;
      _loadingVariety = false;
    });
  }

  Future<void> _loadNutritionPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final key = sp.getString('settings.api.fdc.key') ?? '';
    final region = sp.getString('settings.api.off.region') ?? 'world';
    final lastSrc = sp.getString('nutrition.last_source');
    setState(() {
      _fdcKeyCtrl.text = key;
      _offRegion = region;
      _loadingNutritionPrefs = false;
    });
    if (lastSrc != null && (lastSrc == 'fdc' || lastSrc == 'off')) {
      ref.read(nutritionSearchSourceProvider.notifier).state = lastSrc;
    }
    // Preload recent queries list
    final raw = sp.getString('nutrition.recent_queries.v1');
    if (raw != null && raw.startsWith('[')) {
      final body = raw.substring(1, raw.length - 1);
      final xs = body.isEmpty ? <String>[] : body.split(',').map((e) => e.replaceAll('"', '').trim()).where((e) => e.isNotEmpty).toList();
      ref.read(recentNutritionQueriesProvider.notifier).state = xs.take(10).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userTargetsAsync = ref.watch(currentUserTargetsProvider);

    return Scaffold(
      appBar: AppBar(
        // NEW: Always show a back button (works whether we can pop or not)
        leading: Builder(
          builder: (context) {
            if (context.canPop()) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => context.pop(),
              );
            }
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Home',
              onPressed: () => context.go(AppRouter.home),
            );
          },
        ),
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // User Profile Section
          userTargetsAsync.when(
            loading: () => const _LoadingSection(),
            error: (error, stack) => _ErrorSection(error: error.toString() ),
            data: (targets) => _UserProfileSection(targets: targets),
          ),

          const SizedBox(height: 16),

          // Nutrition APIs section
          _buildSectionHeader('Nutrition APIs'),
          _NutritionApisCard(),

          const SizedBox(height: 16),

          // Taste & Allergens
          _buildSectionHeader('Taste & Allergens'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.local_dining_outlined),
                  title: const Text('Taste & Allergens'),
                  subtitle: const Text('Likes, dislikes, bans, cuisines'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRouter.tasteSettings),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Shopping section
          _buildSectionHeader('Shopping'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.store_mall_directory_outlined),
                  title: const Text('Store Profiles'),
                  subtitle: const Text('Manage stores and aisle order'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRouter.storeProfiles),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.kitchen),
                  title: const Text('Batch Cook Planner'),
                  subtitle: const Text('Plan batch sessions, shopping, cook, labels'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRouter.batch),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Variety & Repetition Section
          _buildSectionHeader('Variety & Repetition'),
          if (_loadingVariety)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.repeat),
                    title: const Text('Max repeats per week'),
                    subtitle: Text('Same recipe up to ${_maxRepeatsPerWeek}x'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        const Text('1'),
                        Expanded(
                          child: Slider(
                            value: _maxRepeatsPerWeek.toDouble(),
                            min: 1,
                            max: 2,
                            divisions: 1,
                            label: '$_maxRepeatsPerWeek',
                            onChanged: (v) async {
                              final n = v.round();
                              setState(() => _maxRepeatsPerWeek = n);
                              await ref.read(varietyPrefsServiceProvider).setMaxRepeatsPerWeek(n);
                            },
                          ),
                        ),
                        const Text('2'),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Spread proteins'),
                    subtitle: const Text('Avoid streaks of the same protein'),
                    value: _enableProteinSpread,
                    onChanged: (v) async {
                      setState(() => _enableProteinSpread = v);
                      await ref.read(varietyPrefsServiceProvider).setEnableProteinSpread(v);
                    },
                    secondary: const Icon(Icons.restaurant),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Rotate cuisines'),
                    subtitle: const Text('Avoid same cuisine back-to-back'),
                    value: _enableCuisineRotation,
                    onChanged: (v) async {
                      setState(() => _enableCuisineRotation = v);
                      await ref.read(varietyPrefsServiceProvider).setEnableCuisineRotation(v);
                    },
                    secondary: const Icon(Icons.public),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Mix prep times'),
                    subtitle: const Text('Include quick meals and avoid all long'),
                    value: _enablePrepMix,
                    onChanged: (v) async {
                      setState(() => _enablePrepMix = v);
                      await ref.read(varietyPrefsServiceProvider).setEnablePrepMix(v);
                    },
                    secondary: const Icon(Icons.timer),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Look back window (plans)'),
                    subtitle: Text(_historyLookbackPlans == 0 ? 'Off' : 'Last $_historyLookbackPlans plan(s)'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        const Text('0'),
                        Expanded(
                          child: Slider(
                            value: _historyLookbackPlans.toDouble(),
                            min: 0,
                            max: 4,
                            divisions: 4,
                            label: '$_historyLookbackPlans',
                            onChanged: (v) async {
                              final n = v.round();
                              setState(() => _historyLookbackPlans = n);
                              await ref.read(varietyPrefsServiceProvider).setHistoryLookbackPlans(n);
                            },
                          ),
                        ),
                        const Text('4'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // DEV utilities
          _buildSectionHeader('DEV'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.science),
              label: const Text('Patch sample ingredient nutrition/prices'),
              onPressed: _seedSampleNutrition,
            ),
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

  Future<void> _seedSampleNutrition() async {
    final repo = ref.read(ingredientRepositoryProvider);
    try {
      await repo.upsertNutritionAndPrice(
        id: 'ing_chicken_breast_raw',
        unit: Unit.grams,
        per100: const NutritionPer100(kcal: 165, proteinG: 31, carbsG: 0, fatG: 3.6),
        pricePerUnitCents: 1,
        packQty: 1000,
        packPriceCents: 1000,
      );

      await repo.upsertNutritionAndPrice(
        id: 'ing_rice_cooked',
        unit: Unit.grams,
        per100: const NutritionPer100(kcal: 130, proteinG: 2.7, carbsG: 28, fatG: 0.3),
        pricePerUnitCents: 0,
        packQty: 2000,
        packPriceCents: 400,
      );

      await repo.upsertNutritionAndPrice(
        id: 'ing_olive_oil',
        unit: Unit.grams,
        per100: const NutritionPer100(kcal: 884, proteinG: 0, carbsG: 0, fatG: 100),
        packQty: 500,
        packPriceCents: 700,
      );

      await repo.upsertNutritionAndPrice(
        id: 'ing_salt_pepper',
        unit: Unit.grams,
        per100: const NutritionPer100(kcal: 0, proteinG: 0, carbsG: 0, fatG: 0),
        packQty: 100,
        packPriceCents: 200,
      );

      // Invalidate providers so UI refreshes
      ref.invalidate(allIngredientsProvider);
      ref.invalidate(allRecipesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample nutrition seeded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to seed: $e')),
        );
      }
    }
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

class _NutritionApisCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NutritionApisCard> createState() => _NutritionApisCardState();
}

class _NutritionApisCardState extends ConsumerState<_NutritionApisCard> {
  final TextEditingController _fdcKeyCtrl = TextEditingController();
  bool _loaded = false;
  String _offRegion = 'world';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    _fdcKeyCtrl.text = sp.getString('settings.api.fdc.key') ?? '';
    _offRegion = sp.getString('settings.api.off.region') ?? 'world';
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _fdcKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final src = ref.watch(nutritionSearchSourceProvider);
    final recent = ref.watch(recentNutritionQueriesProvider);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, size: 22),
                const SizedBox(width: 8),
                Text('Nutrition APIs', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fdcKeyCtrl,
              decoration: const InputDecoration(
                labelText: 'FDC API Key',
                helperText: 'Required for USDA FDC lookups',
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  await ref.read(nutritionLookupServiceProvider).saveFdcKey(_fdcKeyCtrl.text.trim());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FDC key saved')));
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Key'),
              ),
            ),
            const Divider(height: 24),
            Text('Default Source', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'fdc', label: Text('FDC')),
                ButtonSegment(value: 'off', label: Text('OFF')),
              ],
              selected: {src},
              onSelectionChanged: (s) async {
                final v = s.first;
                ref.read(nutritionSearchSourceProvider.notifier).state = v;
                final sp = await SharedPreferences.getInstance();
                await sp.setString('nutrition.last_source', v);
              },
            ),
            const SizedBox(height: 16),
            Text('OpenFoodFacts Region', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _loaded ? _offRegion : 'world',
              items: const [
                DropdownMenuItem(value: 'world', child: Text('Global (world)')),
                DropdownMenuItem(value: 'us', child: Text('United States (us)')),
                DropdownMenuItem(value: 'uk', child: Text('United Kingdom (uk)')),
                DropdownMenuItem(value: 'de', child: Text('Germany (de)')),
                DropdownMenuItem(value: 'fr', child: Text('France (fr)')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _offRegion = v);
                final sp = await SharedPreferences.getInstance();
                await sp.setString('settings.api.off.region', v);
              },
            ),
            const Divider(height: 24),
            Row(
              children: [
                Text('Recent lookups', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: recent.isEmpty
                      ? null
                      : () async {
                          ref.read(recentNutritionQueriesProvider.notifier).state = const [];
                          final sp = await SharedPreferences.getInstance();
                          await sp.remove('nutrition.recent_queries.v1');
                        },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            if (recent.isEmpty)
              Text('No lookups yet', style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in recent)
                    InputChip(
                      label: Text(q),
                      onPressed: null,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
