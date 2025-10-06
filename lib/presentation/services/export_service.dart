import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/ingredient.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';

typedef DirectoryProvider = Future<Directory> Function();

final DirectoryProvider defaultTempDirProvider = () async {
  return getTemporaryDirectory();
};

/// Utility for exporting the weekly plan as shareable files.
class ExportService {
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
    return '\$${(cents / 100).toStringAsFixed(2)}';
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
