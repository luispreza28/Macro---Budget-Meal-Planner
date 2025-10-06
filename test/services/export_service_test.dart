import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart';
import 'package:macro_budget_meal_planner/domain/entities/plan.dart';
import 'package:macro_budget_meal_planner/domain/entities/recipe.dart';
import 'package:macro_budget_meal_planner/presentation/services/export_service.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import '../helpers/temp_dir_provider.dart';

class _FakeSharePlatform extends SharePlatform {
  List<XFile> sharedFiles = [];

  @override
  Future<void> share(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {}

  @override
  Future<ShareResult> shareWithResult(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    return const ShareResult('', ShareResultStatus.success);
  }

  @override
  Future<void> shareUri(
    Uri uri, {
    Rect? sharePositionOrigin,
  }) async {}

  @override
  Future<void> shareFiles(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {}

  @override
  Future<ShareResult> shareFilesWithResult(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    return const ShareResult('', ShareResultStatus.success);
  }

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    sharedFiles = files;
    return const ShareResult('', ShareResultStatus.success);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharePlatform originalPlatform;
  late _FakeSharePlatform fakePlatform;

  setUp(() {
    originalPlatform = SharePlatform.instance;
    fakePlatform = _FakeSharePlatform();
    SharePlatform.instance = fakePlatform;
  });

  tearDown(() {
    SharePlatform.instance = originalPlatform;
  });

  test('sharePlanCsv writes csv to injected temp dir without platform plugins', () async {
    Directory? capturedDirectory;

    Future<Directory> trackingProvider() async {
      final dir = await ioTempDirProvider();
      capturedDirectory = dir;
      return dir;
    }

    addTearDown(() async {
      if (capturedDirectory != null && await capturedDirectory!.exists()) {
        await capturedDirectory!.delete(recursive: true);
      }
    });

    final plan = Plan(
      id: 'plan-1',
      name: 'Test Plan',
      userTargetsId: 'targets-1',
      days: [
        PlanDay(
          date: '2024-01-01',
          meals: const [
            PlanMeal(recipeId: 'recipe-1', servings: 1),
          ],
        ),
      ],
      totals: const PlanTotals(
        kcal: 2000,
        proteinG: 150,
        carbsG: 200,
        fatG: 70,
        costCents: 5000,
      ),
      createdAt: DateTime.utc(2024, 1, 1),
    );

    final recipes = <String, Recipe>{
      'recipe-1': Recipe(
        id: 'recipe-1',
        name: 'Test Recipe',
        servings: 1,
        timeMins: 30,
        cuisine: null,
        dietFlags: const [],
        items: const [
          RecipeItem(
            ingredientId: 'ingredient-1',
            qty: 200,
            unit: Unit.grams,
          ),
        ],
        steps: const ['Cook'],
        macrosPerServ: const MacrosPerServing(
          kcal: 500,
          proteinG: 40,
          carbsG: 50,
          fatG: 20,
        ),
        costPerServCents: 700,
        source: RecipeSource.manual,
      ),
    };

    final ingredients = <String, Ingredient>{
      'ingredient-1': Ingredient(
        id: 'ingredient-1',
        name: 'Chicken Breast',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(
          kcal: 165,
          proteinG: 31,
          carbsG: 0,
          fatG: 3.6,
        ),
        pricePerUnitCents: 599,
        purchasePack: const PurchasePack(
          qty: 1000,
          unit: Unit.grams,
          priceCents: 599,
        ),
        aisle: Aisle.meat,
        tags: const ['protein'],
        source: IngredientSource.manual,
        lastVerifiedAt: null,
      ),
    };

    await ExportService.sharePlanCsv(
      plan: plan,
      recipes: recipes,
      ingredients: ingredients,
      tempDirProvider: trackingProvider,
    );

    expect(fakePlatform.sharedFiles, hasLength(1));

    final sharedFile = fakePlatform.sharedFiles.single;
    expect(sharedFile.name, endsWith('.csv'));
    expect(capturedDirectory, isNotNull);
    final sharedPath = sharedFile.path;
    final capturedPath = capturedDirectory!.path;
    final parentPath = File(sharedPath).parent.path;
    expect(p.equals(parentPath, capturedPath), isTrue);

    final bytes = await File(sharedFile.path).readAsBytes();
    expect(bytes.take(3).toList(), equals([0xEF, 0xBB, 0xBF]));

    final content = utf8.decode(bytes.skip(3).toList());
    expect(
      content,
      contains(
        'day_index,day_date,meal_index,meal_label,recipe_id,recipe_name,servings,time_mins,calories_total,protein_g_total,cost_usd_total',
      ),
    );
    expect(
      content,
      contains('0,2024-01-01,0,Meal 1,recipe-1,Test Recipe,1,30,500,40,7.00'),
    );
  });
}
