import 'dart:math' as math;

import '../entities/ingredient.dart';
import '../entities/recipe.dart';
import '../entities/plan.dart';
import '../entities/pantry_item.dart';
import '../entities/price_override.dart';

/// Shopping list item with purchase pack information
class ShoppingListItem {
  const ShoppingListItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.requiredQty,
    required this.requiredUnit,
    required this.purchasePacks,
    required this.totalCostCents,
    required this.leftoverQty,
    required this.leftoverUnit,
    required this.aisle,
  });

  /// Reference to ingredient ID
  final String ingredientId;
  
  /// Display name of the ingredient
  final String ingredientName;
  
  /// Total quantity needed for the plan
  final double requiredQty;
  
  /// Unit for the required quantity
  final Unit requiredUnit;
  
  /// Number of purchase packs needed
  final int purchasePacks;
  
  /// Total cost for all purchase packs
  final int totalCostCents;
  
  /// Leftover quantity after purchase
  final double leftoverQty;
  
  /// Unit for leftover quantity
  final Unit leftoverUnit;
  
  /// Aisle category for shopping organization
  final Aisle aisle;

  /// Get formatted cost string
  String get costString {
    final dollars = totalCostCents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  /// Get formatted leftover string
  String get leftoverString {
    if (leftoverQty <= 0) return 'No leftovers';
    return '${leftoverQty.toStringAsFixed(1)}${requiredUnit.value} leftover';
  }

  /// Get purchase description
  String get purchaseDescription {
    return '$purchasePacks pack${purchasePacks > 1 ? 's' : ''}';
  }
}

/// Grouped shopping list by aisle
class GroupedShoppingList {
  const GroupedShoppingList({
    required this.itemsByAisle,
    required this.totalCostCents,
  });

  /// Items grouped by aisle
  final Map<Aisle, List<ShoppingListItem>> itemsByAisle;
  
  /// Total estimated cost for all items
  final int totalCostCents;

  /// Get all items as a flat list
  List<ShoppingListItem> get allItems {
    return itemsByAisle.values.expand((items) => items).toList();
  }

  /// Get formatted total cost string
  String get totalCostString {
    final dollars = totalCostCents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  /// Get aisle order for shopping efficiency
  List<Aisle> get aisleOrder {
    return [
      Aisle.produce,
      Aisle.meat,
      Aisle.dairy,
      Aisle.frozen,
      Aisle.pantry,
      Aisle.condiments,
      Aisle.bakery,
      Aisle.household,
    ].where((aisle) => itemsByAisle.containsKey(aisle)).toList();
  }
}

/// Cost calculation result with detailed breakdown
class CostCalculationResult {
  const CostCalculationResult({
    required this.totalCostCents,
    required this.ingredientCosts,
    required this.pantrySavings,
    required this.priceOverridesSavings,
  });

  /// Total cost in cents
  final int totalCostCents;
  
  /// Cost breakdown by ingredient
  final Map<String, int> ingredientCosts;
  
  /// Savings from using pantry items
  final int pantrySavings;
  
  /// Savings from price overrides
  final int priceOverridesSavings;

  /// Get net cost after savings
  int get netCostCents => totalCostCents - pantrySavings - priceOverridesSavings;

  /// Get formatted total cost string
  String get totalCostString {
    final dollars = totalCostCents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  /// Get formatted net cost string
  String get netCostString {
    final dollars = netCostCents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  /// Get formatted savings string
  String get savingsString {
    final totalSavings = pantrySavings + priceOverridesSavings;
    if (totalSavings <= 0) return '';
    final dollars = totalSavings / 100;
    return 'Save \$${dollars.toStringAsFixed(2)}';
  }
}

/// Service for calculating costs and generating shopping lists
class CostCalculator {
  CostCalculator();

  /// Calculate total cost for a recipe with specific servings
  int calculateRecipeCost({
    required Recipe recipe,
    required double servings,
    required List<Ingredient> ingredients,
    List<PriceOverride> priceOverrides = const [],
  }) {
    int totalCost = 0;
    final priceOverrideMap = {for (var po in priceOverrides) po.ingredientId: po};

    for (final item in recipe.items) {
      final ingredient = ingredients.firstWhere(
        (ing) => ing.id == item.ingredientId,
        orElse: () => throw ArgumentError(
          'Ingredient ${item.ingredientId} not found for recipe ${recipe.id}',
        ),
      );

      final requiredQty = item.qty * servings;
      
      // Use price override if available
      if (priceOverrideMap.containsKey(item.ingredientId)) {
        final override = priceOverrideMap[item.ingredientId]!;
        totalCost += _calculateCostWithOverride(
          quantity: requiredQty,
          unit: item.unit,
          override: override,
        );
      } else {
        totalCost += ingredient.calculateCost(requiredQty, item.unit);
      }
    }

    return totalCost;
  }

  /// Calculate total cost for a plan
  CostCalculationResult calculatePlanCost({
    required Plan plan,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    List<PantryItem> pantryItems = const [],
    List<PriceOverride> priceOverrides = const [],
  }) {
    int totalCost = 0;
    int pantrySavings = 0;
    int priceOverridesSavings = 0;
    final ingredientCosts = <String, int>{};

    final pantryMap = {for (var item in pantryItems) item.ingredientId: item};
    final priceOverrideMap = {for (var po in priceOverrides) po.ingredientId: po};

    // Aggregate all ingredients needed for the plan
    final aggregatedIngredients = _aggregateIngredients(plan, recipes);

    for (final entry in aggregatedIngredients.entries) {
      final ingredientId = entry.key;
      final totalQty = entry.value['qty'] as double;
      final unit = entry.value['unit'] as Unit;

      final ingredient = ingredients.firstWhere((ing) => ing.id == ingredientId);
      
      // Calculate base cost
      int baseCost;
      if (priceOverrideMap.containsKey(ingredientId)) {
        final override = priceOverrideMap[ingredientId]!;
        baseCost = _calculateCostWithOverride(
          quantity: totalQty,
          unit: unit,
          override: override,
        );
        
        // Calculate savings from override
        final originalCost = ingredient.calculateCost(totalQty, unit);
        priceOverridesSavings += math.max(0, originalCost - baseCost);
      } else {
        baseCost = ingredient.calculateCost(totalQty, unit);
      }

      // Apply pantry deduction
      int finalCost = baseCost;
      if (pantryMap.containsKey(ingredientId)) {
        final pantryItem = pantryMap[ingredientId]!;
        if (pantryItem.hasEnoughFor(totalQty, unit)) {
          // Entire quantity available in pantry
          pantrySavings += baseCost;
          finalCost = 0;
        } else if (pantryItem.qty > 0) {
          // Partial quantity available in pantry
          final pantryValue = ingredient.calculateCost(pantryItem.qty, pantryItem.unit);
          pantrySavings += pantryValue;
          finalCost = math.max(0, baseCost - pantryValue);
        }
      }

      totalCost += finalCost;
      ingredientCosts[ingredientId] = finalCost;
    }

    return CostCalculationResult(
      totalCostCents: totalCost,
      ingredientCosts: ingredientCosts,
      pantrySavings: pantrySavings,
      priceOverridesSavings: priceOverridesSavings,
    );
  }

  /// Generate shopping list with pack rounding
  GroupedShoppingList generateShoppingList({
    required Plan plan,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    List<PantryItem> pantryItems = const [],
    List<PriceOverride> priceOverrides = const [],
  }) {
    final pantryMap = {for (var item in pantryItems) item.ingredientId: item};
    final priceOverrideMap = {for (var po in priceOverrides) po.ingredientId: po};

    // Aggregate ingredients and subtract pantry
    final aggregatedIngredients = _aggregateIngredients(plan, recipes);
    final shoppingItems = <ShoppingListItem>[];
    int totalCost = 0;

    for (final entry in aggregatedIngredients.entries) {
      final ingredientId = entry.key;
      final requiredQty = entry.value['qty'] as double;
      final unit = entry.value['unit'] as Unit;

      final ingredient = ingredients.firstWhere((ing) => ing.id == ingredientId);
      
      // Subtract pantry quantity
      double netQty = requiredQty;
      if (pantryMap.containsKey(ingredientId)) {
        final pantryItem = pantryMap[ingredientId]!;
        if (pantryItem.unit == unit) {
          netQty = math.max(0, requiredQty - pantryItem.qty);
        }
      }

      // Skip if nothing needed after pantry deduction
      if (netQty <= 0) continue;

      // Calculate purchase packs needed
      final packInfo = _calculatePurchasePacks(
        ingredient: ingredient,
        requiredQty: netQty,
        requiredUnit: unit,
        priceOverride: priceOverrideMap[ingredientId],
      );

      if (packInfo != null) {
        shoppingItems.add(packInfo);
        totalCost += packInfo.totalCostCents;
      }
    }

    // Group by aisle
    final itemsByAisle = <Aisle, List<ShoppingListItem>>{};
    for (final item in shoppingItems) {
      itemsByAisle.putIfAbsent(item.aisle, () => []).add(item);
    }

    return GroupedShoppingList(
      itemsByAisle: itemsByAisle,
      totalCostCents: totalCost,
    );
  }

  /// Calculate cost efficiency (cents per 1000 kcal)
  double calculateCostEfficiency({
    required int costCents,
    required double kcal,
  }) {
    if (kcal <= 0) return double.infinity;
    return (costCents * 1000) / kcal;
  }

  /// Calculate budget utilization percentage
  double calculateBudgetUtilization({
    required int actualCostCents,
    required int budgetCents,
  }) {
    if (budgetCents <= 0) return 0;
    return (actualCostCents / budgetCents) * 100;
  }

  /// Calculate cost per serving for a recipe
  double calculateCostPerServing({
    required Recipe recipe,
    required List<Ingredient> ingredients,
    List<PriceOverride> priceOverrides = const [],
  }) {
    final totalCost = calculateRecipeCost(
      recipe: recipe,
      servings: 1.0,
      ingredients: ingredients,
      priceOverrides: priceOverrides,
    );
    return totalCost / 100.0; // Convert cents to dollars
  }

  /// Update shopping list item cost with user edit
  GroupedShoppingList updateItemCost({
    required GroupedShoppingList shoppingList,
    required String ingredientId,
    required int newCostCents,
  }) {
    final updatedItemsByAisle = <Aisle, List<ShoppingListItem>>{};
    int totalCostDelta = 0;

    for (final entry in shoppingList.itemsByAisle.entries) {
      final aisle = entry.key;
      final items = entry.value;
      final updatedItems = <ShoppingListItem>[];

      for (final item in items) {
        if (item.ingredientId == ingredientId) {
          totalCostDelta += newCostCents - item.totalCostCents;
          updatedItems.add(ShoppingListItem(
            ingredientId: item.ingredientId,
            ingredientName: item.ingredientName,
            requiredQty: item.requiredQty,
            requiredUnit: item.requiredUnit,
            purchasePacks: item.purchasePacks,
            totalCostCents: newCostCents,
            leftoverQty: item.leftoverQty,
            leftoverUnit: item.leftoverUnit,
            aisle: item.aisle,
          ));
        } else {
          updatedItems.add(item);
        }
      }

      updatedItemsByAisle[aisle] = updatedItems;
    }

    return GroupedShoppingList(
      itemsByAisle: updatedItemsByAisle,
      totalCostCents: shoppingList.totalCostCents + totalCostDelta,
    );
  }

  /// Aggregate all ingredients needed for a plan
  Map<String, Map<String, dynamic>> _aggregateIngredients(
    Plan plan,
    List<Recipe> recipes,
  ) {
    final aggregated = <String, Map<String, dynamic>>{};

    for (final day in plan.days) {
      for (final meal in day.meals) {
        final recipe = recipes.firstWhere((r) => r.id == meal.recipeId);
        
        for (final item in recipe.items) {
          final totalQty = item.qty * meal.servings;
          
          if (aggregated.containsKey(item.ingredientId)) {
            // Add to existing quantity (assuming same unit)
            final existing = aggregated[item.ingredientId]!;
            if (existing['unit'] == item.unit) {
              existing['qty'] = existing['qty'] + totalQty;
            }
          } else {
            aggregated[item.ingredientId] = {
              'qty': totalQty,
              'unit': item.unit,
            };
          }
        }
      }
    }

    return aggregated;
  }

  /// Calculate purchase packs needed for an ingredient
  ShoppingListItem? _calculatePurchasePacks({
    required Ingredient ingredient,
    required double requiredQty,
    required Unit requiredUnit,
    PriceOverride? priceOverride,
  }) {
    // Use price override pack info if available
    final packQty = priceOverride?.purchasePack?.qty ?? ingredient.purchasePack.qty;
    final packUnit = priceOverride?.purchasePack?.unit ?? ingredient.purchasePack.unit;
    final packPrice = priceOverride?.purchasePack?.priceCents ?? 
                     ingredient.purchasePack.priceCents ?? 
                     ingredient.pricePerUnitCents;

    // Convert required quantity to pack units (simplified - assumes same unit)
    if (requiredUnit != packUnit) {
      // In a full implementation, would need unit conversion
      return null;
    }

    // Calculate packs needed (round up)
    final packsNeeded = (requiredQty / packQty).ceil();
    final totalPackQty = packsNeeded * packQty;
    final leftoverQty = totalPackQty - requiredQty;

    return ShoppingListItem(
      ingredientId: ingredient.id,
      ingredientName: ingredient.name,
      requiredQty: requiredQty,
      requiredUnit: requiredUnit,
      purchasePacks: packsNeeded,
      totalCostCents: packsNeeded * packPrice,
      leftoverQty: leftoverQty,
      leftoverUnit: packUnit,
      aisle: ingredient.aisle,
    );
  }

  /// Calculate cost using price override
  int _calculateCostWithOverride({
    required double quantity,
    required Unit unit,
    required PriceOverride override,
  }) {
    // Use override price per unit
    return (quantity * override.pricePerUnitCents / 100).round();
  }
}
