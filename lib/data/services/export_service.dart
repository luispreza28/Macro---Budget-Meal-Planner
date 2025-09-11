import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/pantry_item.dart';

/// Service for exporting meal plans and shopping lists in various formats
class ExportService {
  /// Export shopping list as plain text (free feature)
  static String exportShoppingListAsText(List<ShoppingListItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('Shopping List');
    buffer.writeln('Generated on ${DateTime.now().toString().substring(0, 16)}');
    buffer.writeln('');

    // Group by aisle
    final groupedItems = <String, List<ShoppingListItem>>{};
    for (final item in items) {
      final aisle = item.aisle.displayName;
      groupedItems.putIfAbsent(aisle, () => []).add(item);
    }

    // Export each aisle
    for (final entry in groupedItems.entries) {
      buffer.writeln('${entry.key}:');
      for (final item in entry.value) {
        final checkbox = item.isCompleted ? '[x]' : '[ ]';
        buffer.writeln('  $checkbox ${item.name} - ${item.quantity} ${item.unit}');
        if (item.estimatedPrice > 0) {
          buffer.writeln('      \$${item.estimatedPrice.toStringAsFixed(2)}');
        }
      }
      buffer.writeln('');
    }

    // Total
    final total = items.fold<double>(0, (sum, item) => sum + item.estimatedPrice);
    if (total > 0) {
      buffer.writeln('Estimated Total: \$${total.toStringAsFixed(2)}');
    }

    return buffer.toString();
  }

  /// Export shopping list as Markdown (free feature)
  static String exportShoppingListAsMarkdown(List<ShoppingListItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('# Shopping List');
    buffer.writeln('*Generated on ${DateTime.now().toString().substring(0, 16)}*');
    buffer.writeln('');

    // Group by aisle
    final groupedItems = <String, List<ShoppingListItem>>{};
    for (final item in items) {
      final aisle = item.aisle.displayName;
      groupedItems.putIfAbsent(aisle, () => []).add(item);
    }

    // Export each aisle
    for (final entry in groupedItems.entries) {
      buffer.writeln('## ${entry.key}');
      buffer.writeln('');
      for (final item in entry.value) {
        final checkbox = item.isCompleted ? '[x]' : '[ ]';
        buffer.writeln('- $checkbox **${item.name}** - ${item.quantity} ${item.unit}');
        if (item.estimatedPrice > 0) {
          buffer.writeln('  - *\$${item.estimatedPrice.toStringAsFixed(2)}*');
        }
      }
      buffer.writeln('');
    }

    // Total
    final total = items.fold<double>(0, (sum, item) => sum + item.estimatedPrice);
    if (total > 0) {
      buffer.writeln('---');
      buffer.writeln('**Estimated Total: \$${total.toStringAsFixed(2)}**');
    }

    return buffer.toString();
  }

  /// Export shopping list as CSV (Pro feature)
  static String exportShoppingListAsCSV(List<ShoppingListItem> items) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Item,Quantity,Unit,Aisle,Estimated Price,Completed');
    
    // Data rows
    for (final item in items) {
      final row = [
        _escapeCsvField(item.name),
        item.quantity.toString(),
        item.unit,
        item.aisle.displayName,
        item.estimatedPrice.toStringAsFixed(2),
        item.isCompleted ? 'Yes' : 'No',
      ].join(',');
      buffer.writeln(row);
    }

    return buffer.toString();
  }

  /// Export meal plan as CSV (Pro feature)
  static String exportMealPlanAsCSV(Plan plan, List<Ingredient> ingredients) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Date,Meal Type,Recipe Name,Servings,Calories,Protein (g),Carbs (g),Fat (g),Estimated Cost');
    
    // Data rows
    for (int dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      final day = plan.days[dayIndex];
      final date = DateTime.now().add(Duration(days: dayIndex)).toString().substring(0, 10);
      
      for (int mealIndex = 0; mealIndex < day.meals.length; mealIndex++) {
        final meal = day.meals[mealIndex];
        final mealType = _getMealTypeName(mealIndex);
        
        // Calculate macros and cost for this meal
        final macros = _calculateMealMacros(meal, ingredients);
        final cost = _calculateMealCost(meal, ingredients);
        
        final row = [
          date,
          mealType,
          _escapeCsvField(meal.recipeId), // In real implementation, would get recipe name
          meal.servings.toString(),
          macros.kcal.toStringAsFixed(1),
          macros.proteinG.toStringAsFixed(1),
          macros.carbsG.toStringAsFixed(1),
          macros.fatG.toStringAsFixed(1),
          cost.toStringAsFixed(2),
        ].join(',');
        buffer.writeln(row);
      }
    }

    return buffer.toString();
  }

  /// Export pantry inventory as CSV (Pro feature)
  static String exportPantryAsCSV(List<PantryItem> pantryItems, List<Ingredient> ingredients) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Item,Quantity,Unit,Aisle,Price per Unit,Total Value,Added Date');
    
    // Data rows
    for (final pantryItem in pantryItems) {
      final ingredient = ingredients.firstWhere(
        (ing) => ing.id == pantryItem.ingredientId,
        orElse: () => throw StateError('Ingredient not found'),
      );
      
      final totalValue = pantryItem.qty * ingredient.pricePerUnitCents / 100;
      
      final row = [
        _escapeCsvField(ingredient.name),
        pantryItem.qty.toString(),
        pantryItem.unit.value,
        ingredient.aisle.displayName,
        (ingredient.pricePerUnitCents / 100).toStringAsFixed(2),
        totalValue.toStringAsFixed(2),
        pantryItem.addedAt.toString().substring(0, 10),
      ].join(',');
      buffer.writeln(row);
    }

    return buffer.toString();
  }

  /// Share exported content via system share dialog
  static Future<void> shareContent({
    required String content,
    required String filename,
    String? subject,
  }) async {
    try {
      // Create temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject ?? 'Macro + Budget Meal Planner Export',
      );
    } catch (e) {
      debugPrint('Error sharing content: $e');
      rethrow;
    }
  }

  /// Generate PDF content (Pro feature - placeholder implementation)
  static Future<String> generatePDFShoppingList(List<ShoppingListItem> items) async {
    // In a real implementation, this would use a PDF generation library like pdf
    // For now, return a placeholder
    throw UnimplementedError('PDF generation requires additional dependencies');
  }

  /// Generate PDF meal plan (Pro feature - placeholder implementation)
  static Future<String> generatePDFMealPlan(Plan plan, List<Ingredient> ingredients) async {
    // In a real implementation, this would use a PDF generation library like pdf
    // For now, return a placeholder
    throw UnimplementedError('PDF generation requires additional dependencies');
  }

  // Helper methods

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _getMealTypeName(int mealIndex) {
    switch (mealIndex) {
      case 0:
        return 'Breakfast';
      case 1:
        return 'Lunch';
      case 2:
        return 'Dinner';
      case 3:
        return 'Snack 1';
      case 4:
        return 'Snack 2';
      default:
        return 'Meal ${mealIndex + 1}';
    }
  }

  static MacrosPerHundred _calculateMealMacros(PlanMeal meal, List<Ingredient> ingredients) {
    // Placeholder implementation - in real app would calculate from recipe ingredients
    return const MacrosPerHundred(
      kcal: 400,
      proteinG: 25,
      carbsG: 35,
      fatG: 15,
    );
  }

  static double _calculateMealCost(PlanMeal meal, List<Ingredient> ingredients) {
    // Placeholder implementation - in real app would calculate from recipe ingredients
    return 3.50;
  }
}

/// Shopping list item for export
class ShoppingListItem {
  const ShoppingListItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.aisle,
    required this.estimatedPrice,
    this.isCompleted = false,
  });

  final String name;
  final double quantity;
  final String unit;
  final Aisle aisle;
  final double estimatedPrice;
  final bool isCompleted;
}

/// Extension for Aisle enum to get display names
extension AisleExtension on Aisle {
  String get displayName {
    switch (this) {
      case Aisle.produce:
        return 'Produce';
      case Aisle.meat:
        return 'Meat & Seafood';
      case Aisle.dairy:
        return 'Dairy & Eggs';
      case Aisle.pantry:
        return 'Pantry';
      case Aisle.frozen:
        return 'Frozen';
      case Aisle.condiments:
        return 'Condiments & Sauces';
      case Aisle.bakery:
        return 'Bakery';
      case Aisle.household:
        return 'Household';
    }
  }
}
