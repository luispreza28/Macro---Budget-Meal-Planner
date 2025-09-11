import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/database.dart';
import '../../data/repositories/ingredient_repository_impl.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../data/repositories/user_targets_repository_impl.dart';
// (Still TODO if/when you add these impls)
// import '../../data/repositories/pantry_repository_impl.dart';
// import '../../data/repositories/plan_repository_impl.dart';
// import '../../data/repositories/price_override_repository_impl.dart';
import '../../data/services/seed_data_service.dart';
import '../../domain/repositories/ingredient_repository.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/repositories/user_targets_repository.dart';
import '../../domain/repositories/pantry_repository.dart';
import '../../domain/repositories/plan_repository.dart';
import '../../domain/repositories/price_override_repository.dart';

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

/// ✅ Provider for user targets repository (wired to concrete impl)
final userTargetsRepositoryProvider = Provider<UserTargetsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserTargetsRepositoryImpl(db, prefs);
});

/// Provider for pantry repository - still disabled until impl is ready
final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  throw UnimplementedError('PantryRepository implementation temporarily disabled - interface mismatch');
});

/// Provider for plan repository - still disabled until impl is ready
final planRepositoryProvider = Provider<PlanRepository>((ref) {
  throw UnimplementedError('PlanRepository implementation temporarily disabled - interface mismatch');
});

/// Provider for price override repository - still disabled until impl is ready
final priceOverrideRepositoryProvider = Provider<PriceOverrideRepository>((ref) {
  throw UnimplementedError('PriceOverrideRepository implementation temporarily disabled - interface mismatch');
});

/// Provider for seed data service - still disabled
final seedDataServiceProvider = Provider<SeedDataService>((ref) {
  throw UnimplementedError('SeedDataService temporarily disabled');
});

/// Provider to initialize seed data on app startup
final seedDataInitializationProvider = FutureProvider<void>((ref) async {
  final seedDataService = ref.watch(seedDataServiceProvider);
  await seedDataService.initializeSeedData();
});
