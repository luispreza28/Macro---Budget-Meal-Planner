import '../errors/validation_exceptions.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/user_targets.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/pantry_item.dart';
import '../../domain/entities/price_override.dart';

/// Utility class for data validation
class Validators {
  Validators._();

  /// Validate ingredient data
  static void validateIngredient(Ingredient ingredient) {
    if (ingredient.id.isEmpty) {
      throw const IngredientValidationException('Ingredient ID cannot be empty');
    }
    
    if (ingredient.name.isEmpty) {
      throw const IngredientValidationException('Ingredient name cannot be empty');
    }
    
    if (ingredient.macrosPer100g.kcal < 0) {
      throw const IngredientValidationException('Calories cannot be negative');
    }
    
    if (ingredient.macrosPer100g.proteinG < 0) {
      throw const IngredientValidationException('Protein cannot be negative');
    }
    
    if (ingredient.macrosPer100g.carbsG < 0) {
      throw const IngredientValidationException('Carbohydrates cannot be negative');
    }
    
    if (ingredient.macrosPer100g.fatG < 0) {
      throw const IngredientValidationException('Fat cannot be negative');
    }
    
    if (ingredient.pricePerUnitCents < 0) {
      throw const IngredientValidationException('Price cannot be negative');
    }
    
    if (ingredient.purchasePack.qty <= 0) {
      throw const IngredientValidationException('Purchase pack quantity must be positive');
    }
  }

  /// Validate recipe data
  static void validateRecipe(Recipe recipe) {
    if (recipe.id.isEmpty) {
      throw const RecipeValidationException('Recipe ID cannot be empty');
    }
    
    if (recipe.name.isEmpty) {
      throw const RecipeValidationException('Recipe name cannot be empty');
    }
    
    if (recipe.servings <= 0) {
      throw const RecipeValidationException('Servings must be positive');
    }
    
    if (recipe.timeMins < 0) {
      throw const RecipeValidationException('Time cannot be negative');
    }
    
    if (recipe.items.isEmpty) {
      throw const RecipeValidationException('Recipe must have at least one ingredient');
    }
    
    if (recipe.steps.isEmpty) {
      throw const RecipeValidationException('Recipe must have at least one step');
    }
    
    if (recipe.macrosPerServ.kcal < 0) {
      throw const RecipeValidationException('Recipe calories cannot be negative');
    }
    
    if (recipe.costPerServCents < 0) {
      throw const RecipeValidationException('Recipe cost cannot be negative');
    }
    
    // Validate recipe items
    for (final item in recipe.items) {
      if (item.ingredientId.isEmpty) {
        throw const RecipeValidationException('Recipe item ingredient ID cannot be empty');
      }
      
      if (item.qty <= 0) {
        throw const RecipeValidationException('Recipe item quantity must be positive');
      }
    }
  }

  /// Validate user targets data
  static void validateUserTargets(UserTargets targets) {
    if (targets.id.isEmpty) {
      throw const UserTargetsValidationException('User targets ID cannot be empty');
    }
    
    if (targets.kcal <= 0) {
      throw const UserTargetsValidationException('Daily calories must be positive');
    }
    
    if (targets.proteinG < 0) {
      throw const UserTargetsValidationException('Protein target cannot be negative');
    }
    
    if (targets.carbsG < 0) {
      throw const UserTargetsValidationException('Carbohydrate target cannot be negative');
    }
    
    if (targets.fatG <= 0) {
      throw const UserTargetsValidationException('Fat target must be positive');
    }
    
    if (targets.budgetCents != null && targets.budgetCents! <= 0) {
      throw const UserTargetsValidationException('Budget must be positive if set');
    }
    
    if (targets.mealsPerDay < 2 || targets.mealsPerDay > 5) {
      throw const UserTargetsValidationException('Meals per day must be between 2 and 5');
    }
    
    if (targets.timeCapMins != null && targets.timeCapMins! <= 0) {
      throw const UserTargetsValidationException('Time cap must be positive if set');
    }
    
    // Validate macro distribution makes sense
    final totalMacroCalories = targets.totalMacroCalories;
    final caloriesDifference = (targets.kcal - totalMacroCalories).abs();
    if (caloriesDifference > targets.kcal * 0.1) { // 10% tolerance
      throw const UserTargetsValidationException('Macro targets do not match calorie target');
    }
  }

  /// Validate plan data
  static void validatePlan(Plan plan) {
    if (plan.id.isEmpty) {
      throw const PlanValidationException('Plan ID cannot be empty');
    }
    
    if (plan.name.isEmpty) {
      throw const PlanValidationException('Plan name cannot be empty');
    }
    
    if (plan.userTargetsId.isEmpty) {
      throw const PlanValidationException('Plan must reference user targets');
    }
    
    if (plan.days.isEmpty) {
      throw const PlanValidationException('Plan must have at least one day');
    }
    
    if (plan.totals.kcal < 0) {
      throw const PlanValidationException('Plan total calories cannot be negative');
    }
    
    if (plan.totals.costCents < 0) {
      throw const PlanValidationException('Plan total cost cannot be negative');
    }
    
    // Validate each day
    for (final day in plan.days) {
      if (day.date.isEmpty) {
        throw const PlanValidationException('Plan day must have a date');
      }
      
      if (day.meals.isEmpty) {
        throw const PlanValidationException('Plan day must have at least one meal');
      }
      
      // Validate each meal
      for (final meal in day.meals) {
        if (meal.recipeId.isEmpty) {
          throw const PlanValidationException('Plan meal must reference a recipe');
        }
        
        if (meal.servings <= 0) {
          throw const PlanValidationException('Plan meal servings must be positive');
        }
      }
    }
  }

  /// Validate pantry item data
  static void validatePantryItem(PantryItem item) {
    if (item.id.isEmpty) {
      throw const PantryItemValidationException('Pantry item ID cannot be empty');
    }
    
    if (item.ingredientId.isEmpty) {
      throw const PantryItemValidationException('Pantry item must reference an ingredient');
    }
    
    if (item.qty < 0) {
      throw const PantryItemValidationException('Pantry item quantity cannot be negative');
    }
  }

  /// Validate price override data
  static void validatePriceOverride(PriceOverride override) {
    if (override.id.isEmpty) {
      throw const PriceOverrideValidationException('Price override ID cannot be empty');
    }
    
    if (override.ingredientId.isEmpty) {
      throw const PriceOverrideValidationException('Price override must reference an ingredient');
    }
    
    if (override.pricePerUnitCents < 0) {
      throw const PriceOverrideValidationException('Price override cannot be negative');
    }
    
    if (override.purchasePack != null) {
      if (override.purchasePack!.qty <= 0) {
        throw const PriceOverrideValidationException('Purchase pack quantity must be positive');
      }
      
      if (override.purchasePack!.priceCents != null && 
          override.purchasePack!.priceCents! < 0) {
        throw const PriceOverrideValidationException('Purchase pack price cannot be negative');
      }
    }
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    // At least 8 characters, contains letter and number
    return password.length >= 8 && 
           RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password);
  }

  /// Validate positive number
  static bool isPositiveNumber(double value) {
    return value > 0 && value.isFinite;
  }

  /// Validate non-negative number
  static bool isNonNegativeNumber(double value) {
    return value >= 0 && value.isFinite;
  }

  /// Validate string is not empty
  static bool isNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }

  /// Validate string length
  static bool isValidLength(String value, {int? minLength, int? maxLength}) {
    final length = value.length;
    
    if (minLength != null && length < minLength) return false;
    if (maxLength != null && length > maxLength) return false;
    
    return true;
  }

  /// Validate number range
  static bool isInRange(double value, {double? min, double? max}) {
    if (min != null && value < min) return false;
    if (max != null && value > max) return false;
    
    return true;
  }
}
