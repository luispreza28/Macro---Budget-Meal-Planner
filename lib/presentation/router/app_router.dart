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
import '../pages/recipes/recipe_details_page.dart';
import '../providers/database_providers.dart';

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
  static const String recipeDetails = '/recipe/:id';

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
      path: recipeDetails,
      name: 'recipe-details',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: RecipeDetailsPage(
          recipeId: state.pathParameters['id']!,
        ),
      ),
    ),
  ];
}
