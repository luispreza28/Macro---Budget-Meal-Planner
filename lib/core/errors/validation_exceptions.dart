/// Base class for validation exceptions
abstract class ValidationException implements Exception {
  const ValidationException(this.message);
  
  final String message;
  
  @override
  String toString() => 'ValidationException: $message';
}

/// Exception thrown when ingredient data is invalid
class IngredientValidationException extends ValidationException {
  const IngredientValidationException(super.message);
}

/// Exception thrown when recipe data is invalid
class RecipeValidationException extends ValidationException {
  const RecipeValidationException(super.message);
}

/// Exception thrown when user targets data is invalid
class UserTargetsValidationException extends ValidationException {
  const UserTargetsValidationException(super.message);
}

/// Exception thrown when plan data is invalid
class PlanValidationException extends ValidationException {
  const PlanValidationException(super.message);
}

/// Exception thrown when pantry item data is invalid
class PantryItemValidationException extends ValidationException {
  const PantryItemValidationException(super.message);
}

/// Exception thrown when price override data is invalid
class PriceOverrideValidationException extends ValidationException {
  const PriceOverrideValidationException(super.message);
}
