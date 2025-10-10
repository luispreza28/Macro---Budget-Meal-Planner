import '../../domain/entities/ingredient.dart';

/// Minimal seed patch for specific ingredient IDs referenced in debug flows.
/// These entries ensure non-zero macros/costs so recipe totals compute correctly.
List<Ingredient> seedPatchIngredients() {
  return [
    // Chicken breast raw (grams)
    Ingredient(
      id: 'ing_chicken_breast_raw',
      name: 'Chicken Breast (Raw)',
      unit: Unit.grams,
      macrosPer100g: const MacrosPerHundred(
        kcal: 165,
        proteinG: 31.0,
        carbsG: 0.0,
        fatG: 3.6,
      ),
      pricePerUnitCents: 1, // fallback per-gram price
      purchasePack: const PurchasePack(qty: 1000, unit: Unit.grams, priceCents: 900),
      aisle: Aisle.meat,
      tags: const ['high_protein', 'lean'],
      source: IngredientSource.seed,
    ),

    // Rice cooked (grams)
    Ingredient(
      id: 'ing_rice_cooked',
      name: 'Rice (Cooked)',
      unit: Unit.grams,
      macrosPer100g: const MacrosPerHundred(
        kcal: 130,
        proteinG: 2.7,
        carbsG: 28.0,
        fatG: 0.3,
      ),
      pricePerUnitCents: 1,
      purchasePack: const PurchasePack(qty: 1000, unit: Unit.grams, priceCents: 300),
      aisle: Aisle.pantry,
      tags: const ['carbs', 'bulk'],
      source: IngredientSource.seed,
    ),

    // Olive oil (milliliters base). Treat macrosPerHundred as per-100 ml for simplicity.
    Ingredient(
      id: 'ing_olive_oil',
      name: 'Olive Oil',
      unit: Unit.milliliters,
      macrosPer100g: const MacrosPerHundred(
        kcal: 884,
        proteinG: 0,
        carbsG: 0,
        fatG: 100,
      ),
      pricePerUnitCents: 1,
      purchasePack: const PurchasePack(qty: 500, unit: Unit.milliliters, priceCents: 500),
      aisle: Aisle.condiments,
      tags: const ['healthy_fat'],
      source: IngredientSource.seed,
    ),

    // Salt & pepper (grams) — macros zero but small price to avoid $0 totals.
    Ingredient(
      id: 'ing_salt_pepper',
      name: 'Salt & Pepper',
      unit: Unit.grams,
      macrosPer100g: const MacrosPerHundred(
        kcal: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
      ),
      pricePerUnitCents: 1,
      purchasePack: const PurchasePack(qty: 100, unit: Unit.grams, priceCents: 50),
      aisle: Aisle.condiments,
      tags: const ['seasoning'],
      source: IngredientSource.seed,
    ),
  ];
}

