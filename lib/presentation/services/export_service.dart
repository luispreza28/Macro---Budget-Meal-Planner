import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/ingredient.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/pantry_item.dart';
import '../providers/plan_providers.dart';
import '../providers/recipe_providers.dart';
import '../providers/ingredient_providers.dart';
import '../providers/database_providers.dart';
import '../providers/shopping_list_providers.dart';

typedef DirectoryProvider = Future<Directory> Function();

final DirectoryProvider defaultTempDirProvider = () async {
  return getTemporaryDirectory();
};

/// Utility for exporting the weekly plan as shareable files.
class ExportService {
  ExportService(this._ref);

  final Ref _ref;

  static Future<void> sharePlanText({
    required Plan plan,
    required Map<String, Recipe> recipes,
    required Map<String, Ingredient> ingredients,
  }) async {
    final filename = _timestampedFilename(extension: 'txt');
    final body = _buildPlanText(
      plan: plan,
      recipes: recipes,
      ingredients: ingredients,
    );
    final file = await _writeTempFile(filename, body);

    await Share.shareXFiles([XFile(file.path)], text: 'Weekly meal plan');
  }

  static Future<void> sharePlanCsv({
    required Plan plan,
    required Map<String, Recipe> recipes,
    required Map<String, Ingredient> ingredients,
    DirectoryProvider? tempDirProvider,
  }) async {
    final filename = _timestampedFilename(extension: 'csv');
    final body = _buildPlanCsv(
      plan: plan,
      recipes: recipes,
      ingredients: ingredients,
    );
    final file = await _writeTempCsv(
      filename,
      body,
      tempDirProvider: tempDirProvider,
    );

    await Share.shareXFiles(
      [XFile(file.path, name: filename, mimeType: 'text/csv')],
      subject: 'Weekly meal plan (CSV)',
      text: 'Weekly meal plan (CSV)',
    );
  }

  /// Creates a ZIP containing last 7 days’ plan, shopping list, and pantry snapshot.
  /// Returns the absolute file path to the ZIP.
  Future<String> exportLast7DaysZip({
    required DateTime endInclusiveLocal,
    required String timezone,
  }) async {
    final end = DateTime(endInclusiveLocal.year, endInclusiveLocal.month, endInclusiveLocal.day);
    final start = end.subtract(const Duration(days: 6));

    if (kDebugMode) {
      // ignore: avoid_print
      print('[Export] building ZIP start=${DateFormat('yyyy-MM-dd').format(start)} end=${DateFormat('yyyy-MM-dd').format(end)} tz=$timezone');
    }

    // Load core data
    final plan = await _ref.read(currentPlanProvider.future);
    final recipes = await _ref.read(allRecipesProvider.future);
    final ingredients = await _ref.read(allIngredientsProvider.future);
    final pantryRepo = _ref.read(pantryRepositoryProvider);
    final pantryItems = await pantryRepo.getAllPantryItems();
    final shoppingGroups = await _ref.read(shoppingListItemsProvider.future);

    final recipeMap = {for (final r in recipes) r.id: r};
    final ingredientMap = {for (final i in ingredients) i.id: i};

    // Filter plan days by date window if plan available
    final filteredPlan = (plan == null)
        ? null
        : plan.copyWith(
            days: plan.days.where((d) {
              final dt = DateTime.tryParse(d.date);
              if (dt == null) return false;
              final day = DateTime(dt.year, dt.month, dt.day);
              return (day.isAfter(start) || day.isAtSameMomentAs(start)) &&
                  (day.isBefore(end) || day.isAtSameMomentAs(end));
            }).toList(),
          );

    // Build file contents (keep in memory, also write temp for logs)
    final List<_PendingFile> files = [];

    // plan_week.csv + txt
    if (filteredPlan != null && filteredPlan.days.isNotEmpty) {
      final planCsv = _buildPlanCsv(
        plan: filteredPlan,
        recipes: recipeMap,
        ingredients: ingredientMap,
      );
      final planTxt = _buildPlanText(
        plan: filteredPlan,
        recipes: recipeMap,
        ingredients: ingredientMap,
      );
      files.add(_PendingFile.csv(name: 'plan_week.csv', csv: planCsv));
      files.add(_PendingFile.text(name: 'plan_week.txt', text: planTxt));
    } else {
      // Empty placeholders with headers
      files.add(_PendingFile.csv(name: 'plan_week.csv', csv: 'day_index,day_date,meal_index,meal_label,recipe_id,recipe_name,servings,time_mins,calories_total,protein_g_total,cost_usd_total\r\n'));
      files.add(_PendingFile.text(name: 'plan_week.txt', text: 'WEEKLY MEAL PLAN\n(no entries in selected window)'));
    }

    // shopping_list_week.csv + txt
    final shoppingCsv = _buildShoppingCsv(shoppingGroups);
    final shoppingTxt = _buildShoppingText(shoppingGroups);
    files.add(_PendingFile.csv(name: 'shopping_list_week.csv', csv: shoppingCsv));
    files.add(_PendingFile.text(name: 'shopping_list_week.txt', text: shoppingTxt));

    // pantry_snapshot.csv
    final pantryCsv = _buildPantryCsv(pantryItems, ingredientMap);
    files.add(_PendingFile.csv(name: 'pantry_snapshot.csv', csv: pantryCsv));

    // Create ZIP (bytes)
    final archive = Archive();
    for (final f in files) {
      final bytes = await f.toBytes();
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Export] wrote file=${f.name} bytes=${bytes.length}');
      }
      archive.addFile(ArchiveFile(f.name, bytes.length, bytes));
    }
    final zipBytes = ZipEncoder().encode(archive) ?? Uint8List.fromList(const []);

    final label = DateFormat('yyyy-MM-dd').format(end);
    final zipName = 'macro_budget_week_$label.zip';

    if (kIsWeb) {
      // On web, return an empty path; the caller should use bytes method to download/share
      // We still log ZIP info here.
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Export] ZIP=<memory:$zipName> entries=${files.length}');
      }
      // Store bytes for optional direct sharing via XFile.fromData when called through helper.
      _lastBuiltZip = (filename: zipName, bytes: zipBytes);
      return '';
    }

    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/$zipName';
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipBytes, flush: true);

    if (kDebugMode) {
      // ignore: avoid_print
      print('[Export] ZIP=$zipPath entries=${files.length}');
    }
    return zipPath;
  }

  // Helper for web to access last-built ZIP without re-querying data
  ({String filename, List<int> bytes})? _lastBuiltZip;

  /// Builds and returns the ZIP bytes + filename, without writing to disk.
  Future<({String filename, List<int> bytes})> buildLast7DaysZipBytes({
    required DateTime endInclusiveLocal,
    required String timezone,
  }) async {
    // Reuse main method to create in-memory archive and cache it when on web
    final path = await exportLast7DaysZip(
      endInclusiveLocal: endInclusiveLocal,
      timezone: timezone,
    );
    if (_lastBuiltZip != null) return _lastBuiltZip!;

    // If not web, read from file we just wrote
    final f = File(path);
    final bytes = await f.readAsBytes();
    final filename = path.split(Platform.pathSeparator).last;
    return (filename: filename, bytes: bytes);
  }

  // -------- builders --------

  static String _buildPlanText({
    required Plan plan,
    required Map<String, Recipe> recipes,
    required Map<String, Ingredient> ingredients,
  }) {
    if (plan.days.isEmpty) {
      throw StateError('No plan to export');
    }

    final buffer = StringBuffer()
      ..writeln('WEEKLY MEAL PLAN')
      ..writeln('----------------')
      ..writeln();

    for (var dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      final day = plan.days[dayIndex];
      final parsedDate = DateTime.tryParse(day.date);
      final date = parsedDate ?? DateTime.now().add(Duration(days: dayIndex));
      final dateLabel = DateFormat('yyyy-MM-dd').format(date);
      buffer.writeln('${_friendlyDay(date, dayIndex)}  •  $dateLabel');

      var dayKcal = 0.0;
      var dayProtein = 0.0;

      for (var mealIndex = 0; mealIndex < day.meals.length; mealIndex++) {
        final meal = day.meals[mealIndex];
        final recipe = recipes[meal.recipeId];
        if (recipe == null) {
          continue;
        }

        final servings = meal.servings;
        final kcal = recipe.macrosPerServ.kcal * servings;
        final protein = recipe.macrosPerServ.proteinG * servings;
        final costCents = (recipe.costPerServCents * servings).round();

        dayKcal += kcal;
        dayProtein += protein;

        buffer.writeln(
          '  • ${_mealLabel(mealIndex, day.meals.length)} — ${recipe.name} '
          '(serv ${_trim(servings)}, ${recipe.timeMins}m, ~${_moneyFromCents(costCents)}, '
          '${kcal.toStringAsFixed(0)} kcal, ${protein.toStringAsFixed(0)}g p)',
        );
      }

      buffer
        ..writeln(
          '  Day total: ${dayKcal.toStringAsFixed(0)} kcal, ${dayProtein.toStringAsFixed(0)}g protein',
        )
        ..writeln();
    }

    final dayCount = plan.days.length;
    final totals = plan.totals;

    buffer
      ..writeln('WEEKLY TOTALS')
      ..writeln('  kcal: ${totals.kcal.toStringAsFixed(0)}')
      ..writeln('  protein: ${totals.proteinG.toStringAsFixed(0)} g')
      ..writeln('  carbs: ${totals.carbsG.toStringAsFixed(0)} g')
      ..writeln('  fat: ${totals.fatG.toStringAsFixed(0)} g')
      ..writeln('  cost: ${_moneyFromCents(totals.costCents)}')
      ..writeln()
      ..writeln('DAILY AVERAGES')
      ..writeln('  kcal: ${(totals.kcal / dayCount).toStringAsFixed(0)}')
      ..writeln(
        '  protein: ${(totals.proteinG / dayCount).toStringAsFixed(0)} g',
      )
      ..writeln('  carbs: ${(totals.carbsG / dayCount).toStringAsFixed(0)} g')
      ..writeln('  fat: ${(totals.fatG / dayCount).toStringAsFixed(0)} g')
      ..writeln(
        '  cost: ${_moneyFromCents((totals.costCents / dayCount).round())}',
      );

    return buffer.toString();
  }

  static String _buildPlanCsv({
    required Plan plan,
    required Map<String, Recipe> recipes,
    required Map<String, Ingredient> ingredients,
  }) {
    if (plan.days.isEmpty) {
      throw StateError('No plan to export');
    }

    final buffer = StringBuffer()
      ..writeln(
        'day_index,day_date,meal_index,meal_label,recipe_id,recipe_name,servings,time_mins,calories_total,protein_g_total,cost_usd_total',
      );

    for (var dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      final day = plan.days[dayIndex];
      final parsedDate = DateTime.tryParse(day.date);
      final date = parsedDate ?? DateTime.now().add(Duration(days: dayIndex));
      final dateLabel = DateFormat('yyyy-MM-dd').format(date);

      for (var mealIndex = 0; mealIndex < day.meals.length; mealIndex++) {
        final meal = day.meals[mealIndex];
        final recipe = recipes[meal.recipeId];
        if (recipe == null) {
          continue;
        }

        final servings = meal.servings;
        final calories = recipe.macrosPerServ.kcal * servings;
        final protein = recipe.macrosPerServ.proteinG * servings;
        final costUsd = (recipe.costPerServCents * servings) / 100.0;

        final fields = <String>[
          '$dayIndex',
          dateLabel,
          '$mealIndex',
          _csvEscape(_mealLabel(mealIndex, day.meals.length)),
          recipe.id,
          _csvEscape(recipe.name),
          _trim(servings),
          '${recipe.timeMins}',
          calories.toStringAsFixed(0),
          protein.toStringAsFixed(0),
          costUsd.toStringAsFixed(2),
        ];

        buffer.writeln(fields.join(','));
      }
    }

    return buffer.toString();
  }

  // -------- shopping list builders (grouped by aisle) --------

  static String _buildShoppingCsv(List<ShoppingAisleGroup> groups) {
    final buffer = StringBuffer()
      ..writeln('aisle,ingredientId,name,totalQty,unit,estimated_cost_usd,packs_needed');
    for (final g in groups) {
      for (final it in g.items) {
        final fields = <String>[
          _csvEscape(_aisleDisplay(g.aisle)),
          it.ingredient.id,
          _csvEscape(it.ingredient.name),
          it.totalQty.toStringAsFixed(2),
          it.unit.name,
          (it.estimatedCostCents / 100.0).toStringAsFixed(2),
          it.packsNeeded?.toString() ?? '',
        ];
        buffer.writeln(fields.join(','));
      }
    }
    return buffer.toString();
  }

  static String _buildShoppingText(List<ShoppingAisleGroup> groups) {
    final buffer = StringBuffer()
      ..writeln('SHOPPING LIST (last 7 days)')
      ..writeln('---------------------------')
      ..writeln();
    for (final g in groups) {
      buffer.writeln(_aisleDisplay(g.aisle) + ':');
      for (final it in g.items) {
        final price = it.estimatedCostCents > 0
            ? ' ~' + _moneyFromCents(it.estimatedCostCents)
            : '';
        final packs = it.packsNeeded != null ? ' x${it.packsNeeded}' : '';
        buffer.writeln('  • ${it.ingredient.name} — ${_trim(it.totalQty)} ${it.unit.name}$packs$price');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  static String _aisleDisplay(Aisle a) {
    switch (a) {
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

  // -------- pantry snapshot (CSV) --------

  static String _buildPantryCsv(
    List<PantryItem> pantryItems,
    Map<String, Ingredient> ingredientMap,
  ) {
    final buffer = StringBuffer()
      ..writeln('ingredientId,name,onHandQty,unit,aisle,lastVerifiedAt');
    for (final p in pantryItems) {
      final ing = ingredientMap[p.ingredientId];
      final aisle = ing != null ? _aisleDisplay(ing.aisle) : '';
      final row = [
        p.ingredientId,
        _csvEscape(ing?.name ?? ''),
        _trim(p.qty),
        p.unit.name,
        aisle,
        DateFormat('yyyy-MM-dd').format(p.addedAt),
      ].join(',');
      buffer.writeln(row);
    }
    return buffer.toString();
  }

  // -------- helpers --------

  static Future<File> _writeTempFile(String filename, String contents) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    return file.writeAsString(contents);
  }

  static Future<File> _writeTempCsv(
    String filename,
    String csvBody, {
    DirectoryProvider? tempDirProvider,
  }) async {
    final crlf = csvBody
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .join('\r\n');

    final bom = utf8.encode('\uFEFF');
    final bytes = <int>[]..addAll(bom)..addAll(utf8.encode(crlf));

    final directory = await (tempDirProvider ?? defaultTempDirProvider)();
    final file = File('${directory.path}/$filename');
    return file.writeAsBytes(bytes, flush: true);
  }

  static String _timestampedFilename({required String extension}) {
    final format = DateFormat('yyyyMMdd_HHmm');
    final now = DateTime.now();
    return 'plan_${format.format(now)}.$extension';
  }

  static String _moneyFromCents(num cents) {
    final loc = Intl.getCurrentLocale();
    final f = NumberFormat.simpleCurrency(locale: loc);
    return f.format(cents / 100.0);
  }

  static String _trim(double value) {
    final asFixed = value.toStringAsFixed(1);
    if (asFixed.endsWith('.0')) {
      return value.toStringAsFixed(0);
    }
    return asFixed;
  }

  static String _friendlyDay(DateTime date, int index) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(date.year, date.month, date.day);
    final delta = thatDay.difference(today).inDays;
    if (delta == 0 || index == 0) {
      return 'Today';
    }
    if (delta == 1 || index == 1) {
      return 'Tomorrow';
    }
    return DateFormat('EEEE').format(date);
  }

  static String _mealLabel(int mealIndex, int totalMeals) {
    if (totalMeals == 2) {
      return mealIndex == 0 ? 'Breakfast' : 'Dinner';
    }
    if (totalMeals == 3) {
      switch (mealIndex) {
        case 0:
          return 'Breakfast';
        case 1:
          return 'Lunch';
        case 2:
          return 'Dinner';
      }
    } else if (totalMeals == 4) {
      switch (mealIndex) {
        case 0:
          return 'Breakfast';
        case 1:
          return 'Lunch';
        case 2:
          return 'Dinner';
        case 3:
          return 'Snack';
      }
    } else if (totalMeals == 5) {
      switch (mealIndex) {
        case 0:
          return 'Breakfast';
        case 1:
          return 'Snack 1';
        case 2:
          return 'Lunch';
        case 3:
          return 'Snack 2';
        case 4:
          return 'Dinner';
      }
    }
    return 'Meal ${mealIndex + 1}';
  }

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}

class _PendingFile {
  _PendingFile._(this.name, this._bytesBuilder);

  factory _PendingFile.csv({required String name, required String csv}) {
    return _PendingFile._(name, () async {
      // Normalize to CRLF + BOM per existing CSV writer
      final crlf = csv
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .split('\n')
          .join('\r\n');
      final bom = utf8.encode('\uFEFF');
      return Uint8List.fromList(<int>[]..addAll(bom)..addAll(utf8.encode(crlf)));
    });
  }

  factory _PendingFile.text({required String name, required String text}) {
    return _PendingFile._(name, () async => Uint8List.fromList(utf8.encode(text)));
  }

  final String name;
  final Future<Uint8List> Function() _bytesBuilder;

  Future<Uint8List> toBytes() => _bytesBuilder();
}

/// Riverpod provider to access instance-based ExportService (for ZIP export)
final exportServiceProvider = Provider<ExportService>((ref) => ExportService(ref));
