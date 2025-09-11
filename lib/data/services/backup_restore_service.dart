import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/ingredient.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/user_targets.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/pantry_item.dart';
import '../../domain/entities/price_override.dart';
import '../../domain/repositories/ingredient_repository.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/repositories/user_targets_repository.dart';
import '../../domain/repositories/plan_repository.dart';
import '../../domain/repositories/pantry_repository.dart';
import '../../domain/repositories/price_override_repository.dart';
import '../services/local_storage_service.dart';

/// Service for backing up and restoring user data
class BackupRestoreService {
  const BackupRestoreService({
    required this.ingredientRepository,
    required this.recipeRepository,
    required this.userTargetsRepository,
    required this.planRepository,
    required this.pantryRepository,
    required this.priceOverrideRepository,
    required this.localStorageService,
  });

  final IngredientRepository ingredientRepository;
  final RecipeRepository recipeRepository;
  final UserTargetsRepository userTargetsRepository;
  final PlanRepository planRepository;
  final PantryRepository pantryRepository;
  final PriceOverrideRepository priceOverrideRepository;
  final LocalStorageService localStorageService;

  /// Create a complete backup of user data
  Future<Map<String, dynamic>> createBackup() async {
    final backup = <String, dynamic>{};

    // Backup user targets
    final userTargets = await userTargetsRepository.getAllUserTargets();
    backup['user_targets'] = userTargets.map((t) => t.toJson()).toList();

    // Backup plans
    final plans = await planRepository.getAllPlans();
    backup['plans'] = plans.map((p) => p.toJson()).toList();

    // Backup pantry items
    final pantryItems = await pantryRepository.getAllPantryItems();
    backup['pantry_items'] = pantryItems.map((p) => p.toJson()).toList();

    // Backup price overrides
    final priceOverrides = await priceOverrideRepository.getAllPriceOverrides();
    backup['price_overrides'] = priceOverrides.map((p) => p.toJson()).toList();

    // Backup custom recipes (user-created only)
    final allRecipes = await recipeRepository.getAllRecipes();
    final customRecipes = allRecipes.where((r) => r.source == RecipeSource.manual).toList();
    backup['custom_recipes'] = customRecipes.map((r) => r.toJson()).toList();

    // Backup custom ingredients (user-created only)
    final allIngredients = await ingredientRepository.getAllIngredients();
    final customIngredients = allIngredients.where((i) => i.source == IngredientSource.manual).toList();
    backup['custom_ingredients'] = customIngredients.map((i) => i.toJson()).toList();

    // Backup user preferences
    backup['preferences'] = localStorageService.exportUserPreferences();

    // Add metadata
    backup['backup_version'] = 1;
    backup['created_at'] = DateTime.now().toIso8601String();
    backup['app_version'] = '1.0.0'; // Would be dynamic in production

    return backup;
  }

  /// Restore user data from backup
  Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    // Validate backup format
    if (!_validateBackupFormat(backup)) {
      throw ArgumentError('Invalid backup format');
    }

    try {
      // Clear existing user data (but keep seed data)
      await _clearUserData();

      // Restore user targets
      if (backup.containsKey('user_targets')) {
        final userTargetsList = backup['user_targets'] as List;
        for (final targetJson in userTargetsList) {
          final target = UserTargets.fromJson(targetJson);
          await userTargetsRepository.saveUserTargets(target);
        }
      }

      // Restore plans
      if (backup.containsKey('plans')) {
        final plansList = backup['plans'] as List;
        for (final planJson in plansList) {
          final plan = Plan.fromJson(planJson);
          await planRepository.savePlan(plan);
        }
      }

      // Restore pantry items
      if (backup.containsKey('pantry_items')) {
        final pantryItemsList = backup['pantry_items'] as List;
        final pantryItems = pantryItemsList
            .map((json) => PantryItem.fromJson(json))
            .toList();
        await pantryRepository.bulkInsertPantryItems(pantryItems);
      }

      // Restore price overrides
      if (backup.containsKey('price_overrides')) {
        final priceOverridesList = backup['price_overrides'] as List;
        final priceOverrides = priceOverridesList
            .map((json) => PriceOverride.fromJson(json))
            .toList();
        await priceOverrideRepository.bulkInsertPriceOverrides(priceOverrides);
      }

      // Restore custom recipes
      if (backup.containsKey('custom_recipes')) {
        final recipesList = backup['custom_recipes'] as List;
        final recipes = recipesList
            .map((json) => Recipe.fromJson(json))
            .toList();
        await recipeRepository.bulkInsertRecipes(recipes);
      }

      // Restore custom ingredients
      if (backup.containsKey('custom_ingredients')) {
        final ingredientsList = backup['custom_ingredients'] as List;
        final ingredients = ingredientsList
            .map((json) => Ingredient.fromJson(json))
            .toList();
        await ingredientRepository.bulkInsertIngredients(ingredients);
      }

      // Restore user preferences
      if (backup.containsKey('preferences')) {
        final preferences = backup['preferences'] as Map<String, dynamic>;
        await localStorageService.importUserPreferences(preferences);
      }

    } catch (e) {
      // If restore fails, we should ideally restore from a backup
      // For now, just rethrow the error
      rethrow;
    }
  }

  /// Export backup to file
  Future<File> exportBackupToFile() async {
    final backup = await createBackup();
    final backupJson = jsonEncode(backup);
    
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'macro_budget_backup_$timestamp.json';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(backupJson);
    return file;
  }

  /// Import backup from file
  Future<void> importBackupFromFile(File file) async {
    if (!await file.exists()) {
      throw ArgumentError('Backup file does not exist');
    }
    
    final backupJson = await file.readAsString();
    final backup = jsonDecode(backupJson) as Map<String, dynamic>;
    
    await restoreFromBackup(backup);
  }

  /// Get backup file size
  Future<int> getBackupSize() async {
    final backup = await createBackup();
    final backupJson = jsonEncode(backup);
    return backupJson.length;
  }

  /// Validate backup format
  bool _validateBackupFormat(Map<String, dynamic> backup) {
    // Check required fields
    if (!backup.containsKey('backup_version') || 
        !backup.containsKey('created_at')) {
      return false;
    }

    // Check version compatibility
    final version = backup['backup_version'] as int?;
    if (version == null || version > 1) {
      return false;
    }

    return true;
  }

  /// Clear user data (keep seed data)
  Future<void> _clearUserData() async {
    // Clear pantry
    await pantryRepository.clearPantry();
    
    // Clear price overrides
    await priceOverrideRepository.clearAllPriceOverrides();
    
    // Clear plans
    final plans = await planRepository.getAllPlans();
    for (final plan in plans) {
      await planRepository.deletePlan(plan.id);
    }

    // Clear user targets
    final targets = await userTargetsRepository.getAllUserTargets();
    for (final target in targets) {
      await userTargetsRepository.deleteUserTargets(target.id);
    }

    // Clear custom recipes (keep seed recipes)
    final recipes = await recipeRepository.getAllRecipes();
    final customRecipes = recipes.where((r) => r.source == RecipeSource.manual);
    for (final recipe in customRecipes) {
      await recipeRepository.deleteRecipe(recipe.id);
    }

    // Clear custom ingredients (keep seed ingredients)
    final ingredients = await ingredientRepository.getAllIngredients();
    final customIngredients = ingredients.where((i) => i.source == IngredientSource.manual);
    for (final ingredient in customIngredients) {
      await ingredientRepository.deleteIngredient(ingredient.id);
    }

    // Clear user preferences
    await localStorageService.clearUserData();
  }

  /// Create automatic backup (called periodically)
  Future<void> createAutomaticBackup() async {
    try {
      final backupFile = await exportBackupToFile();
      
      // Store backup location in preferences
      await localStorageService.setJsonData('last_backup', {
        'path': backupFile.path,
        'created_at': DateTime.now().toIso8601String(),
        'size': await backupFile.length(),
      });
      
      // Clean up old automatic backups (keep only last 5)
      await _cleanupOldBackups();
      
    } catch (e) {
      // Log error but don't throw - automatic backup shouldn't crash the app
    }
  }

  /// Clean up old backup files
  Future<void> _cleanupOldBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .where((f) => f.path.contains('macro_budget_backup_'))
          .toList();
      
      // Sort by creation time (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      // Delete all but the 5 most recent
      if (files.length > 5) {
        for (int i = 5; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      // Handle cleanup errors silently
    }
  }

  /// Get backup history
  Future<List<Map<String, dynamic>>> getBackupHistory() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync()
        .whereType<File>()
        .where((f) => f.path.contains('macro_budget_backup_'))
        .toList();
    
    final backups = <Map<String, dynamic>>[];
    
    for (final file in files) {
      final stat = file.statSync();
      backups.add({
        'path': file.path,
        'created_at': stat.modified.toIso8601String(),
        'size': stat.size,
      });
    }
    
    // Sort by creation time (newest first)
    backups.sort((a, b) => 
        DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    
    return backups;
  }
}
