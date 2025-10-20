import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/onboarding/onboarding_page.dart';
import '../pages/home/home_page.dart';
import '../pages/plan/plan_page.dart';
import '../pages/shopping/shopping_list_page.dart';
import '../pages/pantry/pantry_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/settings/accessibility_page.dart';
import '../pages/settings/telemetry_settings_page.dart';
import '../pages/settings/store_profiles_page.dart';
import '../pages/settings/localization_units_page.dart';
import '../pages/recipes/recipe_details_page.dart';
import '../pages/import/recipe_import_page.dart';
import '../pages/cook/cook_mode_page.dart';
import '../pages/insights/weekly_insights_page.dart';
import '../pages/scan/barcode_scan_page.dart';
import '../pages/scanner/batch_scanner_page.dart';
import '../pages/scanner/scan_queue_page.dart';
import '../providers/database_providers.dart';
import '../pages/feedback/feedback_form_page.dart';
import '../pages/feedback/diagnostics_preview_page.dart';
import '../pages/feedback/feedback_outbox_page.dart';
import '../pages/offline/queued_actions_page.dart';

/// SharedPreferences flag for onboarding completion (v1)
const kOnboardingDone = 'onboarding.done.v1';

/// Provider for the app router configuration
final appRouterProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  // Gate only the default start; deep links remain unaffected.
  final bool doneNew = prefs.getBool(kOnboardingDone) ?? false;
  final bool doneLegacy = prefs.getBool('onboarding_completed') ?? false;
  final initial = (doneNew || doneLegacy)
      ? AppRouter.home
      : AppRouter.onboarding;

  return GoRouter(
    initialLocation: initial,
    debugLogDiagnostics: true,
    routes: AppRouter._routes,
  );
});

/// App router configuration using go_router
class AppRouter {
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String plan = '/plan';
  static const String shoppingList = '/shopping-list';
  static const String pantry = '/pantry';
  static const String settings = '/settings';
  static const String accessibilitySettings = '/settings/accessibility';

  static const String telemetrySettings = '/settings/telemetry';
  static const String localizationUnits = '/settings/localization';
  static const String storeProfiles = '/settings/store-profiles';
  static const String recipeDetails = '/recipe/:id';
  static const String importRecipe = '/import/recipe';
  static const String cook = '/cook/:recipeId';
  static const String insights = '/insights';
  static const String scan = '/scan';
  static const String scannerBatch = '/scanner/batch';
  static const String scannerQueue = '/scanner/queue';
  static const String feedbackNew = '/feedback/new';
  static const String feedbackPreview = '/feedback/preview';
  static const String feedbackOutbox = '/feedback/outbox';
  static const String offlineQueued = '/offline/queued';

  static final List<GoRoute> _routes = [
    GoRoute(
      path: onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const OnboardingPage(),
      ),
    ),
    GoRoute(
      path: home,
      name: 'home',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const HomePage(),
      ),
    ),
    GoRoute(
      path: plan,
      name: 'plan',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const PlanPage(),
      ),
    ),
    GoRoute(
      path: shoppingList,
      name: 'shopping-list',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const ShoppingListPage(),
      ),
    ),
    GoRoute(
      path: pantry,
      name: 'pantry',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const PantryPage(),
      ),
    ),
    GoRoute(
      path: settings,
      name: 'settings',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const SettingsPage(),
      ),
    ),
    GoRoute(
      path: accessibilitySettings,
      name: 'settings-accessibility',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const AccessibilityPage(),
      ),
    ),
    GoRoute(
      path: localizationUnits,
      name: 'localization-units',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const LocalizationUnitsPage(),
      ),
    ),
    GoRoute(
      path: storeProfiles,
      name: 'store-profiles',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const StoreProfilesPage(),
      ),
    ),
    GoRoute(
      path: recipeDetails,
      name: 'recipe-details',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: RecipeDetailsPage(
          recipeId: state.pathParameters['id']!,
          initialDraft: state.extra is Object ? state.extra as dynamic : null,
        ),
      ),
    ),
    GoRoute(
      path: importRecipe,
      name: 'import-recipe',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const RecipeImportPage(),
      ),
    ),
    GoRoute(
      path: insights,
      name: 'insights',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const WeeklyInsightsPage(),
      ),
    ),
    GoRoute(
      path: scan,
      name: 'scan',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const BarcodeScanPage(),
      ),
    ),
    GoRoute(
      path: cook,
      name: 'cook',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: CookModePage(
          recipeId: state.pathParameters['recipeId']!,
        ),
      ),
    ),
    GoRoute(
      path: scannerBatch,
      name: 'scanner-batch',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const BatchScannerPage(),
      ),
    ),
    GoRoute(
      path: scannerQueue,
      name: 'scanner-queue',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const ScanQueuePage(),
      ),
    ),
    GoRoute(
      path: telemetrySettings,
      name: 'telemetry-settings',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const TelemetrySettingsPage(),
      ),
    ),
    GoRoute(
      path: feedbackNew,
      name: 'feedback-new',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const FeedbackFormPage(),
      ),
    ),
    GoRoute(
      path: feedbackPreview,
      name: 'feedback-preview',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: DiagnosticsPreviewPage(
          draft: (state.extra) as dynamic,
        ),
      ),
    ),
    GoRoute(
      path: feedbackOutbox,
      name: 'feedback-outbox',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const FeedbackOutboxPage(),
      ),
    ),
    GoRoute(
      path: offlineQueued,
      name: 'offline-queued',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const QueuedActionsPage(),
      ),
    ),
  ];
}




