import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/user_targets_providers.dart';
import '../../../l10n/l10n.dart';
import '../../providers/billing_providers.dart';
import '../../../data/services/billing_service.dart';
import '../../router/app_router.dart';
import '../../widgets/paywall_widget.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/database_providers.dart';
import '../../../domain/entities/ingredient.dart';
import '../../../domain/services/variety_prefs_service.dart';
import '../../../domain/services/reminder_prefs_service.dart';
import '../../../domain/services/reminder_scheduler.dart';
import '../../providers/diet_allergen_providers.dart';
import '../../../domain/services/diet_allergen_prefs_service.dart';
import '../../widgets/tag_selector.dart';

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

  // Reminders prefs
  bool _loadingReminders = true;
  bool _shopEnabled = true;
  int _shopDay = DateTime.monday; // 1..7 (Mon=1)
  TimeOfDay _shopTime = const TimeOfDay(hour: 9, minute: 0);

  bool _prepEnabled = false;
  TimeOfDay _prepTime = const TimeOfDay(hour: 18, minute: 0);

  bool _replenishEnabled = true;
  TimeOfDay _replenishTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadVarietyPrefs();
    _loadReminderPrefs();
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

  Future<void> _loadReminderPrefs() async {
    final svc = ref.read(reminderPrefsServiceProvider);
    final shopE = await svc.shopEnabled();
    final shopD = await svc.shopDay();
    final shopT = await svc.shopTime();
    final prepE = await svc.prepEnabled();
    final prepT = await svc.prepTime();
    final repE = await svc.replenishEnabled();
    final repT = await svc.replenishTime();
    if (!mounted) return;
    setState(() {
      _shopEnabled = shopE;
      _shopDay = shopD;
      _shopTime = shopT;
      _prepEnabled = prepE;
      _prepTime = prepT;
      _replenishEnabled = repE;
      _replenishTime = repT;
      _loadingReminders = false;
    });
  }

  Future<void> _rescheduleReminders() async {
    await ref.read(reminderSchedulerProvider).rescheduleAll();
  }

  String _weekdayLabel(int weekday) {
    const names = <int, String>{
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };
    return names[weekday] ?? 'Mon';
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    return showTimePicker(context: context, initialTime: initial);
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
        title: Text(AppLocalizations.of(context)?.settingsTitle ?? 'Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Localization & Units quick entry
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context)?.localizationTitle ?? 'Language, Region & Units'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRouter.localizationUnits),
            ),
          ),
          // User Profile Section
          userTargetsAsync.when(
            loading: () => const _LoadingSection(),
            error: (error, stack) => _ErrorSection(error: error.toString() ),
            data: (targets) => _UserProfileSection(targets: targets),
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

          // Diet & Allergens
          _buildSectionHeader('Diet & Allergens'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer(
                builder: (context, ref, _) {
                  final dietAsync = ref.watch(dietFlagsPrefProvider);
                  final allergensAsync = ref.watch(allergensPrefProvider);
                  final strictAsync = ref.watch(strictModePrefProvider);

                  final diet = dietAsync.asData?.value ?? const <String>[];
                  final allergens = allergensAsync.asData?.value ?? const <String>[];
                  final strict = strictAsync.asData?.value ?? true;

                  // Common diet flags aligned with onboarding
                  const dietOptions = <String, String>{
                    'vegetarian': 'Vegetarian',
                    'vegan': 'Vegan',
                    'gluten_free': 'Gluten Free',
                    'dairy_free': 'Dairy Free',
                    'keto': 'Keto',
                    'paleo': 'Paleo',
                    'low_sodium': 'Low Sodium',
                    'nut_free': 'Nut Free',
                  };

                  // Standard allergen keys
                  const stdAllergens = <String, String>{
                    'peanut': 'Peanut',
                    'tree_nut': 'Tree Nuts',
                    'milk': 'Milk',
                    'egg': 'Egg',
                    'fish': 'Fish',
                    'shellfish': 'Shellfish',
                    'soy': 'Soy',
                    'wheat': 'Wheat',
                    'sesame': 'Sesame',
                  };

                  final svc = ref.read(dietAllergenPrefsServiceProvider);

                  Future<void> _saveDiet(Set<String> flags) async {
                    await svc.setDietFlags(flags.toList());
                    ref.invalidate(dietFlagsPrefProvider);
                    // Downstream updates
                    ref.invalidate(allRecipesProvider);
                    ref.invalidate(shoppingListItemsProvider);
                  }

                  Future<void> _saveAllergens(Set<String> ids) async {
                    await svc.setAllergens(ids.toList());
                    ref.invalidate(allergensPrefProvider);
                    // Downstream updates
                    ref.invalidate(shoppingListItemsProvider);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Diet flags
                      TagSelector(
                        title: 'Diet flags',
                        options: dietOptions,
                        selectedOptions: diet.toSet(),
                        onChanged: (v) => _saveDiet(v),
                      ),
                      const SizedBox(height: 16),
                      // Allergens chips + free-text
                      Text('Allergens', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: stdAllergens.entries.map((e) {
                          final selected = allergens.contains(e.key);
                          return FilterChip(
                            label: Text(e.value),
                            selected: selected,
                            onSelected: (sel) {
                              final next = allergens.toSet();
                              if (sel) next.add(e.key); else next.remove(e.key);
                              _saveAllergens(next);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      _OtherAllergensField(
                        initial: allergens.where((a) => !stdAllergens.keys.contains(a)).join(', '),
                        onSubmitted: (other) {
                          final tokens = other
                              .split(',')
                              .map((s) => s.trim().toLowerCase())
                              .where((s) => s.isNotEmpty)
                              .toSet();
                          final union = {...allergens.where((a) => stdAllergens.keys.contains(a)), ...tokens};
                          _saveAllergens(union);
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        title: const Text('Strict mode'),
                        subtitle: const Text('Exclude conflicts in generation & swaps'),
                        value: strict,
                        onChanged: (v) async {
                          await svc.setStrictMode(v);
                          ref.invalidate(strictModePrefProvider);
                        },
                      ),
                      if (strict)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Text(
                            'Will be excluded in plan generation & swaps.',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                    ],
                  );
                },
              ),
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
                      DropdownMenuItem(value: 'EUR', child: Text('EUR (â‚¬)')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP (Â£)')),
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
            child: ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: const Text('Accessibility Settings'),
              subtitle: const Text('Text size, contrast, motion, haptics'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRouter.accessibilitySettings),
            ),
          ),
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

          // Support & Feedback
          _buildSectionHeader('Support'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Report a problem'),
                  subtitle: const Text('Send feedback with diagnostics'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/feedback/new'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.outbox_outlined),
                  title: const Text('Feedback Outbox'),
                  subtitle: const Text('View or delete saved drafts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/feedback/outbox'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Reminders Section
          _buildSectionHeader('Reminders'),
          if (_loadingReminders)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Shopping Day
                  SwitchListTile(
                    title: const Text('Shopping Day'),
                    subtitle: const Text('Weekly reminder for your shop'),
                    value: _shopEnabled,
                    onChanged: (v) async {
                      setState(() => _shopEnabled = v);
                      final svc = ref.read(reminderPrefsServiceProvider);
                      await svc.setShopEnabled(v);
                      await _rescheduleReminders();
                    },
                    secondary: const Icon(Icons.shopping_bag_outlined),
                  ),
                  if (_shopEnabled) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text('Day'),
                          const SizedBox(width: 16),
                          DropdownButton<int>(
                            value: _shopDay,
                            items: const [
                              DropdownMenuItem(
                                  value: DateTime.monday, child: Text('Mon')),
                              DropdownMenuItem(
                                  value: DateTime.tuesday, child: Text('Tue')),
                              DropdownMenuItem(
                                  value: DateTime.wednesday,
                                  child: Text('Wed')),
                              DropdownMenuItem(
                                  value: DateTime.thursday, child: Text('Thu')),
                              DropdownMenuItem(
                                  value: DateTime.friday, child: Text('Fri')),
                              DropdownMenuItem(
                                  value: DateTime.saturday, child: Text('Sat')),
                              DropdownMenuItem(
                                  value: DateTime.sunday, child: Text('Sun')),
                            ],
                            onChanged: (val) async {
                              if (val == null) return;
                              setState(() => _shopDay = val);
                              final svc = ref.read(reminderPrefsServiceProvider);
                              await svc.setShopDay(val);
                              await _rescheduleReminders();
                            },
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await _pickTime(_shopTime);
                              if (picked == null) return;
                              setState(() => _shopTime = picked);
                              final svc =
                                  ref.read(reminderPrefsServiceProvider);
                              await svc.setShopTime(picked);
                              await _rescheduleReminders();
                            },
                            icon: const Icon(Icons.schedule),
                            label: Text(
                                '${_shopTime.hour.toString().padLeft(2, '0')}:${_shopTime.minute.toString().padLeft(2, '0')}'),
                          )
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 1),

                  // Meal Prep
                  SwitchListTile(
                    title: const Text('Meal Prep'),
                    subtitle:
                        const Text('Daily reminder (e.g., 6:00 PM)'),
                    value: _prepEnabled,
                    onChanged: (v) async {
                      setState(() => _prepEnabled = v);
                      final svc = ref.read(reminderPrefsServiceProvider);
                      await svc.setPrepEnabled(v);
                      await _rescheduleReminders();
                    },
                    secondary: const Icon(Icons.restaurant_menu_outlined),
                  ),
                  if (_prepEnabled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            final picked = await _pickTime(_prepTime);
                            if (picked == null) return;
                            setState(() => _prepTime = picked);
                            final svc =
                                ref.read(reminderPrefsServiceProvider);
                            await svc.setPrepTime(picked);
                            await _rescheduleReminders();
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text(
                              '${_prepTime.hour.toString().padLeft(2, '0')}:${_prepTime.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ),

                  const Divider(height: 1),

                  // Replenish Pantry
                  SwitchListTile(
                    title: const Text('Replenish Pantry'),
                    subtitle:
                        const Text('Nudge to restock after shopping'),
                    value: _replenishEnabled,
                    onChanged: (v) async {
                      setState(() => _replenishEnabled = v);
                      final svc = ref.read(reminderPrefsServiceProvider);
                      await svc.setReplenishEnabled(v);
                      await _rescheduleReminders();
                    },
                    secondary: const Icon(Icons.inventory_2_outlined),
                  ),
                  if (_replenishEnabled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            final picked =
                                await _pickTime(_replenishTime);
                            if (picked == null) return;
                            setState(() => _replenishTime = picked);
                            final svc =
                                ref.read(reminderPrefsServiceProvider);
                            await svc.setReplenishTime(picked);
                            await _rescheduleReminders();
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text(
                              '${_replenishTime.hour.toString().padLeft(2, '0')}:${_replenishTime.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Pro Features Section
          _buildProFeaturesSection(),

          const SizedBox(height: 16),

          
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Telemetry & Diagnostics'),
                  subtitle: const Text('Control crash reporting, analytics, and logs'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.go(AppRouter.telemetrySettings),
                ),
                const Divider(height: 1),
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

class _OtherAllergensField extends StatefulWidget {
  const _OtherAllergensField({required this.initial, required this.onSubmitted});
  final String initial;
  final ValueChanged<String> onSubmitted;

  @override
  State<_OtherAllergensField> createState() => _OtherAllergensFieldState();
}

class _OtherAllergensFieldState extends State<_OtherAllergensField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(covariant _OtherAllergensField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial && _controller.text != widget.initial) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        labelText: 'Otherâ€¦',
        hintText: 'comma-separated (e.g., cilantro, mushrooms)',
        prefixIcon: Icon(Icons.warning_amber_outlined),
      ),
      onSubmitted: widget.onSubmitted,
    );
  }
}

