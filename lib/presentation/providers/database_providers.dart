import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/database.dart';
import '../../data/repositories/ingredient_repository_impl.dart';
import '../../data/repositories/recipe_repository_impl.dart';
// Temporarily disabled due to interface mismatches - will be fixed in Stage 6
// import '../../data/repositories/user_targets_repository_impl.dart';
import '../../data/repositories/pantry_repository_impl.dart';
// Import PlanRepository implementation
import '../../data/repositories/plan_repository_impl.dart';
// import '../../data/repositories/price_override_repository_impl.dart';
import '../../data/services/data_integrity_service.dart';
import '../../data/services/seed_data_service.dart';
import '../../data/services/plan_generation_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/recommendation_service.dart';
import '../../domain/repositories/ingredient_repository.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/repositories/user_targets_repository.dart';
import '../../domain/repositories/pantry_repository.dart';
import '../../domain/repositories/plan_repository.dart';
import '../../domain/repositories/price_override_repository.dart';
import '../../domain/repositories/shopping_list_repository.dart';
import '../../data/repositories/shopping_list_repository_prefs.dart';
import '../../data/repositories/user_targets_local_repository.dart';

/// Provider for the app database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// Provider for ingredient repository
final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return IngredientRepositoryImpl(database);
});

/// Provider for recipe repository
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return RecipeRepositoryImpl(database);
});

/// Provide a working UserTargetsRepository backed by SharedPreferences.
final userTargetsRepositoryProvider = Provider<UserTargetsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserTargetsLocalRepository(prefs);
});

/// Provider for pantry repository backed by Drift storage
final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return PantryRepositoryImpl(database);
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

/// Provider for plan repository backed by Drift storage
final planRepositoryProvider = Provider<PlanRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return PlanRepositoryImpl(database, localStorage);
});

/// Provider for price override repository - Temporarily disabled due to interface mismatch
final priceOverrideRepositoryProvider = Provider<PriceOverrideRepository>((
  ref,
) {
  throw UnimplementedError(
    'PriceOverrideRepository implementation temporarily disabled - interface mismatch',
  );
});

/// Provider for seed data service - Temporarily disabled
final seedDataServiceProvider = Provider<SeedDataService>((ref) {
  throw UnimplementedError('SeedDataService temporarily disabled');
});

/// Provider for a very simple plan generation service
final planGenerationServiceProvider = Provider<PlanGenerationService>((ref) {
  return PlanGenerationService(ref: ref);
});

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return const RecommendationService();
});

final dataIntegrityServiceProvider = Provider<DataIntegrityService>((ref) {
  final ingredientRepo = ref.watch(ingredientRepositoryProvider);
  final recipeRepo = ref.watch(recipeRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return DataIntegrityService(
    ingredientRepository: ingredientRepo,
    recipeRepository: recipeRepo,
    prefs: prefs,
  );
});

final dataIntegrityInitializationProvider = FutureProvider<void>((ref) async {
  final svc = ref.watch(dataIntegrityServiceProvider);
  await svc.healMissingIngredientsOnce();
});

/// Provider to initialize seed data on app startup
final seedDataInitializationProvider = FutureProvider<void>((ref) async {
  final seedDataService = ref.watch(seedDataServiceProvider);
  await seedDataService.initializeSeedData();
});

/// Provider for ShoppingListRepository backed by SharedPreferences
final shoppingListRepositoryProvider =
    Provider<ShoppingListRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ShoppingListRepositoryPrefs(prefs);
});
