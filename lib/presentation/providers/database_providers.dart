import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/database.dart';
import '../../data/repositories/ingredient_repository_impl.dart';
import '../../data/repositories/recipe_repository_impl.dart';
// Temporarily disabled due to interface mismatches - will be fixed in Stage 6
// import '../../data/repositories/user_targets_repository_impl.dart';
// import '../../data/repositories/pantry_repository_impl.dart';
// import '../../data/repositories/plan_repository_impl.dart';
// import '../../data/repositories/price_override_repository_impl.dart';
import '../../data/services/seed_data_service.dart';
import '../../data/services/plan_generation_service.dart';
import '../../data/repositories/mock_plan_repository.dart';
import '../../domain/repositories/ingredient_repository.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/repositories/user_targets_repository.dart';
import '../../domain/repositories/pantry_repository.dart';
import '../../domain/repositories/plan_repository.dart';
import '../../domain/repositories/price_override_repository.dart';
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

/// Provider for pantry repository - Temporarily disabled due to interface mismatch
final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  throw UnimplementedError(
      'PantryRepository implementation temporarily disabled - interface mismatch');
});

/// Provider for plan repository - now backed by an in-memory mock
final planRepositoryProvider = Provider<PlanRepository>((ref) {
  final repo = MockPlanRepository();
  ref.onDispose(() {
    // Close stream controllers when provider is disposed (typically never in app lifetime)
    repo.dispose();
  });
  return repo;
});

/// Provider for price override repository - Temporarily disabled due to interface mismatch
final priceOverrideRepositoryProvider = Provider<PriceOverrideRepository>((ref) {
  throw UnimplementedError(
      'PriceOverrideRepository implementation temporarily disabled - interface mismatch');
});

/// Provider for seed data service - Temporarily disabled
final seedDataServiceProvider = Provider<SeedDataService>((ref) {
  throw UnimplementedError('SeedDataService temporarily disabled');
});

/// Provider for a very simple plan generation service
final planGenerationServiceProvider = Provider<PlanGenerationService>((ref) {
  return PlanGenerationService();
});

/// Provider to initialize seed data on app startup
final seedDataInitializationProvider = FutureProvider<void>((ref) async {
  final seedDataService = ref.watch(seedDataServiceProvider);
  await seedDataService.initializeSeedData();
});
