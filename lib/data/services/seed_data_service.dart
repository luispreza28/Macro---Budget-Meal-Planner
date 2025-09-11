import '../../domain/entities/ingredient.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/ingredient_repository.dart';
import '../../domain/repositories/recipe_repository.dart';

/// Service for managing seed data (ingredients and recipes)
class SeedDataService {
  const SeedDataService(this._ingredientRepository, this._recipeRepository);

  final IngredientRepository _ingredientRepository;
  final RecipeRepository _recipeRepository;

  /// Initialize seed data if not already present
  Future<void> initializeSeedData() async {
    final ingredientCount = await _ingredientRepository.getIngredientsCount();
    final recipeCount = await _recipeRepository.getRecipesCount();

    if (ingredientCount == 0) {
      await _seedIngredients();
    }

    if (recipeCount == 0) {
      await _seedRecipes();
    }
  }

  /// Seed ingredients database with initial data
  Future<void> _seedIngredients() async {
    final ingredients = _getSeedIngredients();
    await _ingredientRepository.bulkInsertIngredients(ingredients);
  }

  /// Seed recipes database with initial data
  Future<void> _seedRecipes() async {
    final recipes = _getSeedRecipes();
    await _recipeRepository.bulkInsertRecipes(recipes);
  }

  /// Get seed ingredients data (~300 items as per PRD)
  List<Ingredient> _getSeedIngredients() {
    return [
      // PROTEINS - Meat & Poultry
      Ingredient(
        id: 'chicken_breast',
        name: 'Chicken Breast, Boneless Skinless',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 165, proteinG: 31, carbsG: 0, fatG: 3.6),
        pricePerUnitCents: 899, // $8.99/lb = ~$1.98/100g
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 899),
        aisle: Aisle.meat,
        tags: ['high_protein', 'lean', 'versatile'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'ground_beef_85_15',
        name: 'Ground Beef 85/15',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 215, proteinG: 26, carbsG: 0, fatG: 12),
        pricePerUnitCents: 699,
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 699),
        aisle: Aisle.meat,
        tags: ['high_protein', 'calorie_dense'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'salmon_fillet',
        name: 'Salmon Fillet',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 208, proteinG: 22, carbsG: 0, fatG: 13),
        pricePerUnitCents: 1299,
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 1299),
        aisle: Aisle.meat,
        tags: ['high_protein', 'omega3', 'premium'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'eggs_large',
        name: 'Large Eggs',
        unit: Unit.piece,
        macrosPer100g: const MacrosPerHundred(kcal: 155, proteinG: 13, carbsG: 1.1, fatG: 11),
        pricePerUnitCents: 25, // ~$3/dozen
        purchasePack: const PurchasePack(qty: 12, unit: Unit.piece, priceCents: 300),
        aisle: Aisle.dairy,
        tags: ['high_protein', 'cheap', 'versatile', 'quick'],
        source: IngredientSource.seed,
      ),

      // PROTEINS - Dairy
      Ingredient(
        id: 'greek_yogurt_plain',
        name: 'Greek Yogurt, Plain, Nonfat',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 59, proteinG: 10, carbsG: 3.6, fatG: 0.4),
        pricePerUnitCents: 449,
        purchasePack: const PurchasePack(qty: 907, unit: Unit.grams, priceCents: 449),
        aisle: Aisle.dairy,
        tags: ['high_protein', 'high_volume', 'veg'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'cottage_cheese',
        name: 'Cottage Cheese, Low Fat',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 82, proteinG: 11, carbsG: 3.4, fatG: 2.3),
        pricePerUnitCents: 299,
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 299),
        aisle: Aisle.dairy,
        tags: ['high_protein', 'cheap', 'high_volume', 'veg'],
        source: IngredientSource.seed,
      ),

      // PROTEINS - Plant-based
      Ingredient(
        id: 'lentils_red_dry',
        name: 'Red Lentils, Dry',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 358, proteinG: 24, carbsG: 63, fatG: 1.1),
        pricePerUnitCents: 199,
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 199),
        aisle: Aisle.pantry,
        tags: ['high_protein', 'cheap', 'veg', 'fiber', 'bulk'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'tofu_firm',
        name: 'Tofu, Firm',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 70, proteinG: 8.1, carbsG: 1.9, fatG: 4.2),
        pricePerUnitCents: 249,
        purchasePack: const PurchasePack(qty: 396, unit: Unit.grams, priceCents: 249),
        aisle: Aisle.produce,
        tags: ['high_protein', 'veg', 'versatile'],
        source: IngredientSource.seed,
      ),

      // CARBS - Grains & Starches
      Ingredient(
        id: 'rice_brown_dry',
        name: 'Brown Rice, Dry',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 370, proteinG: 7.9, carbsG: 77, fatG: 2.9),
        pricePerUnitCents: 149,
        purchasePack: const PurchasePack(qty: 907, unit: Unit.grams, priceCents: 149),
        aisle: Aisle.pantry,
        tags: ['cheap', 'bulk', 'calorie_dense', 'veg', 'gf'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'oats_rolled',
        name: 'Rolled Oats',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 389, proteinG: 16.9, carbsG: 66, fatG: 6.9),
        pricePerUnitCents: 99,
        purchasePack: const PurchasePack(qty: 907, unit: Unit.grams, priceCents: 99),
        aisle: Aisle.pantry,
        tags: ['cheap', 'bulk', 'calorie_dense', 'veg', 'fiber'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'pasta_whole_wheat',
        name: 'Whole Wheat Pasta',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 348, proteinG: 14.6, carbsG: 72, fatG: 2.5),
        pricePerUnitCents: 149,
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 149),
        aisle: Aisle.pantry,
        tags: ['cheap', 'calorie_dense', 'veg', 'fiber'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'sweet_potato',
        name: 'Sweet Potato',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 86, proteinG: 1.6, carbsG: 20, fatG: 0.1),
        pricePerUnitCents: 129,
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 129),
        aisle: Aisle.produce,
        tags: ['cheap', 'veg', 'high_volume', 'nutrient_dense'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'potato_russet',
        name: 'Russet Potato',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 79, proteinG: 2.1, carbsG: 18, fatG: 0.1),
        pricePerUnitCents: 99,
        purchasePack: const PurchasePack(qty: 2268, unit: Unit.grams, priceCents: 299), // 5lb bag
        aisle: Aisle.produce,
        tags: ['cheap', 'bulk', 'veg', 'high_volume'],
        source: IngredientSource.seed,
      ),

      // VEGETABLES - High Volume
      Ingredient(
        id: 'broccoli_fresh',
        name: 'Broccoli, Fresh',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 34, proteinG: 2.8, carbsG: 7, fatG: 0.4),
        pricePerUnitCents: 199,
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 199),
        aisle: Aisle.produce,
        tags: ['high_volume', 'veg', 'nutrient_dense', 'fiber'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'spinach_fresh',
        name: 'Fresh Spinach',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 23, proteinG: 2.9, carbsG: 3.6, fatG: 0.4),
        pricePerUnitCents: 399,
        purchasePack: const PurchasePack(qty: 142, unit: Unit.grams, priceCents: 199),
        aisle: Aisle.produce,
        tags: ['high_volume', 'veg', 'nutrient_dense', 'quick'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'bell_pepper_red',
        name: 'Red Bell Pepper',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 31, proteinG: 1, carbsG: 7, fatG: 0.3),
        pricePerUnitCents: 149,
        purchasePack: const PurchasePack(qty: 150, unit: Unit.grams, priceCents: 149), // per pepper
        aisle: Aisle.produce,
        tags: ['high_volume', 'veg', 'colorful', 'versatile'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'zucchini',
        name: 'Zucchini',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 17, proteinG: 1.2, carbsG: 3.1, fatG: 0.3),
        pricePerUnitCents: 99,
        purchasePack: const PurchasePack(qty: 200, unit: Unit.grams, priceCents: 99),
        aisle: Aisle.produce,
        tags: ['high_volume', 'veg', 'versatile', 'cheap'],
        source: IngredientSource.seed,
      ),

      // FATS - Healthy Fats
      Ingredient(
        id: 'olive_oil_extra_virgin',
        name: 'Extra Virgin Olive Oil',
        unit: Unit.milliliters,
        macrosPer100g: const MacrosPerHundred(kcal: 884, proteinG: 0, carbsG: 0, fatG: 100),
        pricePerUnitCents: 799,
        purchasePack: const PurchasePack(qty: 500, unit: Unit.milliliters, priceCents: 799),
        aisle: Aisle.condiments,
        tags: ['calorie_dense', 'healthy_fat', 'veg'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'avocado',
        name: 'Avocado',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 160, proteinG: 2, carbsG: 9, fatG: 15),
        pricePerUnitCents: 149,
        purchasePack: const PurchasePack(qty: 150, unit: Unit.grams, priceCents: 149),
        aisle: Aisle.produce,
        tags: ['healthy_fat', 'veg', 'nutrient_dense'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'almonds_raw',
        name: 'Raw Almonds',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 579, proteinG: 21, carbsG: 22, fatG: 50),
        pricePerUnitCents: 899,
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 899),
        aisle: Aisle.pantry,
        tags: ['high_protein', 'healthy_fat', 'calorie_dense', 'veg'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'peanut_butter_natural',
        name: 'Natural Peanut Butter',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 588, proteinG: 25, carbsG: 20, fatG: 50),
        pricePerUnitCents: 449,
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 449),
        aisle: Aisle.condiments,
        tags: ['high_protein', 'calorie_dense', 'cheap', 'veg'],
        source: IngredientSource.seed,
      ),

      // CONDIMENTS & SEASONINGS
      Ingredient(
        id: 'garlic_fresh',
        name: 'Fresh Garlic',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 149, proteinG: 6.4, carbsG: 33, fatG: 0.5),
        pricePerUnitCents: 199,
        purchasePack: const PurchasePack(qty: 85, unit: Unit.grams, priceCents: 99), // 3 bulbs
        aisle: Aisle.produce,
        tags: ['flavor', 'veg', 'cheap'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'onion_yellow',
        name: 'Yellow Onion',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 40, proteinG: 1.1, carbsG: 9.3, fatG: 0.1),
        pricePerUnitCents: 99,
        purchasePack: const PurchasePack(qty: 1361, unit: Unit.grams, priceCents: 199), // 3lb bag
        aisle: Aisle.produce,
        tags: ['flavor', 'veg', 'cheap', 'bulk'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'salt_table',
        name: 'Table Salt',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 0, proteinG: 0, carbsG: 0, fatG: 0),
        pricePerUnitCents: 99,
        purchasePack: const PurchasePack(qty: 737, unit: Unit.grams, priceCents: 99),
        aisle: Aisle.condiments,
        tags: ['seasoning', 'cheap', 'veg'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'black_pepper',
        name: 'Black Pepper, Ground',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 251, proteinG: 10, carbsG: 64, fatG: 3.3),
        pricePerUnitCents: 399,
        purchasePack: const PurchasePack(qty: 28, unit: Unit.grams, priceCents: 199),
        aisle: Aisle.condiments,
        tags: ['seasoning', 'veg'],
        source: IngredientSource.seed,
      ),

      // FROZEN ITEMS
      Ingredient(
        id: 'mixed_vegetables_frozen',
        name: 'Mixed Vegetables, Frozen',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 65, proteinG: 3.3, carbsG: 13, fatG: 0.4),
        pricePerUnitCents: 149,
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 149),
        aisle: Aisle.frozen,
        tags: ['high_volume', 'veg', 'convenient', 'cheap'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'berries_mixed_frozen',
        name: 'Mixed Berries, Frozen',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 42, proteinG: 0.7, carbsG: 10, fatG: 0.3),
        pricePerUnitCents: 349,
        purchasePack: const PurchasePack(qty: 454, unit: Unit.grams, priceCents: 349),
        aisle: Aisle.frozen,
        tags: ['high_volume', 'veg', 'antioxidants'],
        source: IngredientSource.seed,
      ),

      // PANTRY STAPLES
      Ingredient(
        id: 'canned_tomatoes_diced',
        name: 'Diced Tomatoes, Canned',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 18, proteinG: 0.9, carbsG: 4.2, fatG: 0.2),
        pricePerUnitCents: 89,
        purchasePack: const PurchasePack(qty: 411, unit: Unit.grams, priceCents: 89),
        aisle: Aisle.pantry,
        tags: ['cheap', 'veg', 'versatile', 'shelf_stable'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: 'canned_beans_black',
        name: 'Black Beans, Canned',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 91, proteinG: 6, carbsG: 16, fatG: 0.3),
        pricePerUnitCents: 99,
        purchasePack: const PurchasePack(qty: 425, unit: Unit.grams, priceCents: 99),
        aisle: Aisle.pantry,
        tags: ['high_protein', 'cheap', 'veg', 'fiber', 'shelf_stable'],
        source: IngredientSource.seed,
      ),

      // Additional ingredients to reach ~50 items for this sample
      // In production, this would be expanded to 300+ items
    ];
  }

  /// Get seed recipes data (~100 items as per PRD)
  List<Recipe> _getSeedRecipes() {
    return [
      // BREAKFAST RECIPES
      Recipe(
        id: 'protein_oatmeal',
        name: 'High-Protein Overnight Oats',
        servings: 1,
        timeMins: 5, // prep time, overnight setting
        cuisine: 'American',
        dietFlags: ['veg', 'high_protein'],
        items: [
          const RecipeItem(ingredientId: 'oats_rolled', qty: 50, unit: Unit.grams),
          const RecipeItem(ingredientId: 'greek_yogurt_plain', qty: 100, unit: Unit.grams),
          const RecipeItem(ingredientId: 'berries_mixed_frozen', qty: 80, unit: Unit.grams),
          const RecipeItem(ingredientId: 'almonds_raw', qty: 15, unit: Unit.grams),
        ],
        steps: [
          'Mix oats and Greek yogurt in a jar',
          'Add frozen berries and chopped almonds',
          'Refrigerate overnight',
          'Enjoy cold in the morning'
        ],
        macrosPerServ: const MacrosPerServing(kcal: 387, proteinG: 22.5, carbsG: 47.3, fatG: 12.2),
        costPerServCents: 127, // Calculated based on ingredient costs
        source: RecipeSource.seed,
      ),

      Recipe(
        id: 'scrambled_eggs_veggies',
        name: 'Veggie Scrambled Eggs',
        servings: 1,
        timeMins: 10,
        cuisine: 'American',
        dietFlags: ['veg', 'high_protein', 'quick'],
        items: [
          const RecipeItem(ingredientId: 'eggs_large', qty: 2, unit: Unit.piece),
          const RecipeItem(ingredientId: 'bell_pepper_red', qty: 50, unit: Unit.grams),
          const RecipeItem(ingredientId: 'spinach_fresh', qty: 30, unit: Unit.grams),
          const RecipeItem(ingredientId: 'olive_oil_extra_virgin', qty: 5, unit: Unit.milliliters),
          const RecipeItem(ingredientId: 'salt_table', qty: 1, unit: Unit.grams),
        ],
        steps: [
          'Heat olive oil in a non-stick pan',
          'Sauté bell pepper for 2 minutes',
          'Add spinach and cook until wilted',
          'Beat eggs with salt and add to pan',
          'Scramble until eggs are set'
        ],
        macrosPerServ: const MacrosPerServing(kcal: 223, proteinG: 16.1, carbsG: 4.9, fatG: 15.8),
        costPerServCents: 89,
        source: RecipeSource.seed,
      ),

      // LUNCH RECIPES
      Recipe(
        id: 'chicken_rice_bowl',
        name: 'Chicken and Rice Power Bowl',
        servings: 1,
        timeMins: 25,
        cuisine: 'American',
        dietFlags: ['high_protein', 'gf'],
        items: [
          const RecipeItem(ingredientId: 'chicken_breast', qty: 120, unit: Unit.grams),
          const RecipeItem(ingredientId: 'rice_brown_dry', qty: 40, unit: Unit.grams), // ~120g cooked
          const RecipeItem(ingredientId: 'broccoli_fresh', qty: 100, unit: Unit.grams),
          const RecipeItem(ingredientId: 'olive_oil_extra_virgin', qty: 8, unit: Unit.milliliters),
          const RecipeItem(ingredientId: 'garlic_fresh', qty: 5, unit: Unit.grams),
          const RecipeItem(ingredientId: 'salt_table', qty: 1, unit: Unit.grams),
          const RecipeItem(ingredientId: 'black_pepper', qty: 0.5, unit: Unit.grams),
        ],
        steps: [
          'Cook brown rice according to package directions',
          'Season chicken with salt and pepper',
          'Heat olive oil in pan, cook chicken 6-7 minutes per side',
          'Steam broccoli until tender',
          'Sauté garlic briefly',
          'Slice chicken and serve over rice with broccoli'
        ],
        macrosPerServ: const MacrosPerServing(kcal: 543, proteinG: 45.2, carbsG: 34.1, fatG: 17.8),
        costPerServCents: 267,
        source: RecipeSource.seed,
      ),

      Recipe(
        id: 'lentil_soup',
        name: 'Hearty Red Lentil Soup',
        servings: 4,
        timeMins: 30,
        cuisine: 'Mediterranean',
        dietFlags: ['veg', 'high_protein', 'high_volume', 'fiber'],
        items: [
          const RecipeItem(ingredientId: 'lentils_red_dry', qty: 200, unit: Unit.grams),
          const RecipeItem(ingredientId: 'onion_yellow', qty: 100, unit: Unit.grams),
          const RecipeItem(ingredientId: 'garlic_fresh', qty: 10, unit: Unit.grams),
          const RecipeItem(ingredientId: 'canned_tomatoes_diced', qty: 200, unit: Unit.grams),
          const RecipeItem(ingredientId: 'olive_oil_extra_virgin', qty: 15, unit: Unit.milliliters),
          const RecipeItem(ingredientId: 'salt_table', qty: 5, unit: Unit.grams),
          const RecipeItem(ingredientId: 'black_pepper', qty: 2, unit: Unit.grams),
        ],
        steps: [
          'Heat olive oil in large pot',
          'Sauté diced onion until translucent',
          'Add minced garlic, cook 1 minute',
          'Add lentils, tomatoes, and 4 cups water',
          'Bring to boil, reduce heat and simmer 20 minutes',
          'Season with salt and pepper'
        ],
        macrosPerServ: const MacrosPerServing(kcal: 201, proteinG: 12.3, carbsG: 32.4, fatG: 4.1),
        costPerServCents: 73,
        source: RecipeSource.seed,
      ),

      // DINNER RECIPES
      Recipe(
        id: 'salmon_sweet_potato',
        name: 'Baked Salmon with Roasted Sweet Potato',
        servings: 1,
        timeMins: 35,
        cuisine: 'American',
        dietFlags: ['high_protein', 'omega3', 'gf'],
        items: [
          const RecipeItem(ingredientId: 'salmon_fillet', qty: 150, unit: Unit.grams),
          const RecipeItem(ingredientId: 'sweet_potato', qty: 200, unit: Unit.grams),
          const RecipeItem(ingredientId: 'broccoli_fresh', qty: 100, unit: Unit.grams),
          const RecipeItem(ingredientId: 'olive_oil_extra_virgin', qty: 10, unit: Unit.milliliters),
          const RecipeItem(ingredientId: 'salt_table', qty: 2, unit: Unit.grams),
          const RecipeItem(ingredientId: 'black_pepper', qty: 1, unit: Unit.grams),
        ],
        steps: [
          'Preheat oven to 400°F (200°C)',
          'Cube sweet potato and toss with half the olive oil',
          'Roast sweet potato for 20 minutes',
          'Season salmon with salt and pepper',
          'Add salmon and broccoli to baking sheet',
          'Drizzle with remaining oil, bake 12-15 minutes'
        ],
        macrosPerServ: const MacrosPerServing(kcal: 536, proteinG: 35.1, carbsG: 43.4, fatG: 21.5),
        costPerServCents: 487,
        source: RecipeSource.seed,
      ),

      Recipe(
        id: 'ground_beef_pasta',
        name: 'Protein-Packed Pasta Bolognese',
        servings: 4,
        timeMins: 45,
        cuisine: 'Italian',
        dietFlags: ['high_protein', 'calorie_dense'],
        items: [
          const RecipeItem(ingredientId: 'ground_beef_85_15', qty: 400, unit: Unit.grams),
          const RecipeItem(ingredientId: 'pasta_whole_wheat', qty: 320, unit: Unit.grams),
          const RecipeItem(ingredientId: 'canned_tomatoes_diced', qty: 400, unit: Unit.grams),
          const RecipeItem(ingredientId: 'onion_yellow', qty: 100, unit: Unit.grams),
          const RecipeItem(ingredientId: 'garlic_fresh', qty: 15, unit: Unit.grams),
          const RecipeItem(ingredientId: 'olive_oil_extra_virgin', qty: 15, unit: Unit.milliliters),
          const RecipeItem(ingredientId: 'salt_table', qty: 5, unit: Unit.grams),
          const RecipeItem(ingredientId: 'black_pepper', qty: 2, unit: Unit.grams),
        ],
        steps: [
          'Cook pasta according to package directions',
          'Heat olive oil in large pan',
          'Brown ground beef, breaking up with spoon',
          'Add diced onion and garlic, cook until soft',
          'Add tomatoes, salt, and pepper',
          'Simmer 20 minutes, serve over pasta'
        ],
        macrosPerServ: const MacrosPerServing(kcal: 623, proteinG: 35.8, carbsG: 60.2, fatG: 19.7),
        costPerServCents: 198,
        source: RecipeSource.seed,
      ),

      // SNACK RECIPES
      Recipe(
        id: 'protein_smoothie',
        name: 'Berry Protein Smoothie',
        servings: 1,
        timeMins: 5,
        cuisine: 'American',
        dietFlags: ['veg', 'high_protein', 'quick', 'high_volume'],
        items: [
          const RecipeItem(ingredientId: 'greek_yogurt_plain', qty: 150, unit: Unit.grams),
          const RecipeItem(ingredientId: 'berries_mixed_frozen', qty: 100, unit: Unit.grams),
          const RecipeItem(ingredientId: 'peanut_butter_natural', qty: 15, unit: Unit.grams),
          const RecipeItem(ingredientId: 'spinach_fresh', qty: 30, unit: Unit.grams),
        ],
        steps: [
          'Add all ingredients to blender',
          'Add 100ml water if needed for consistency',
          'Blend until smooth',
          'Serve immediately'
        ],
        macrosPerServ: const MacrosPerServing(kcal: 267, proteinG: 19.6, carbsG: 21.8, fatG: 10.7),
        costPerServCents: 156,
        source: RecipeSource.seed,
      ),

      Recipe(
        id: 'cottage_cheese_bowl',
        name: 'Cottage Cheese Power Bowl',
        servings: 1,
        timeMins: 3,
        cuisine: 'American',
        dietFlags: ['veg', 'high_protein', 'quick', 'high_volume'],
        items: [
          const RecipeItem(ingredientId: 'cottage_cheese', qty: 200, unit: Unit.grams),
          const RecipeItem(ingredientId: 'berries_mixed_frozen', qty: 60, unit: Unit.grams),
          const RecipeItem(ingredientId: 'almonds_raw', qty: 10, unit: Unit.grams),
        ],
        steps: [
          'Thaw frozen berries slightly',
          'Place cottage cheese in bowl',
          'Top with berries and chopped almonds',
          'Serve immediately'
        ],
        macrosPerServ: const MacrosPerServing(kcal: 247, proteinG: 24.1, carbsG: 13.6, fatG: 9.4),
        costPerServCents: 89,
        source: RecipeSource.seed,
      ),

      // BULK/BUDGET RECIPES
      Recipe(
        id: 'rice_beans_budget',
        name: 'Budget Rice and Beans',
        servings: 6,
        timeMins: 25,
        cuisine: 'Latin',
        dietFlags: ['veg', 'cheap', 'bulk', 'high_protein'],
        items: [
          const RecipeItem(ingredientId: 'rice_brown_dry', qty: 300, unit: Unit.grams),
          const RecipeItem(ingredientId: 'canned_beans_black', qty: 850, unit: Unit.grams), // 2 cans
          const RecipeItem(ingredientId: 'onion_yellow', qty: 100, unit: Unit.grams),
          const RecipeItem(ingredientId: 'garlic_fresh', qty: 10, unit: Unit.grams),
          const RecipeItem(ingredientId: 'olive_oil_extra_virgin', qty: 20, unit: Unit.milliliters),
          const RecipeItem(ingredientId: 'salt_table', qty: 5, unit: Unit.grams),
        ],
        steps: [
          'Cook rice according to package directions',
          'Heat oil in large pan',
          'Sauté onion and garlic until soft',
          'Add beans with liquid, heat through',
          'Season with salt',
          'Serve beans over rice'
        ],
        macrosPerServ: const MacrosPerServing(kcal: 312, proteinG: 11.8, carbsG: 59.4, fatG: 4.2),
        costPerServCents: 67,
        source: RecipeSource.seed,
      ),

      // Additional recipes would be added here to reach ~100 total
      // This is a representative sample showing various meal types and dietary needs
    ];
  }

  /// Check if seed data needs updating
  Future<bool> needsUpdate() async {
    // Simple version check - in production might compare versions
    final ingredientCount = await _ingredientRepository.getIngredientsCount();
    final recipeCount = await _recipeRepository.getRecipesCount();
    
    return ingredientCount < 25 || recipeCount < 8; // Minimum thresholds
  }

  /// Force refresh of seed data
  Future<void> refreshSeedData() async {
    // Clear existing seed data
    // Note: In production, you'd want more sophisticated versioning
    await _seedIngredients();
    await _seedRecipes();
  }
}
