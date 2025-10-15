import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlp;
import 'package:html/dom.dart' as hdom;
import 'package:collection/collection.dart';

import '../entities/ingredient.dart' as domain;
import '../import/draft_recipe.dart';

final recipeImportServiceProvider =
    Provider<RecipeImportService>((ref) => RecipeImportService(ref));

class RecipeImportService {
  RecipeImportService(this.ref);
  final Ref ref;

  Future<DraftRecipe> importFromUrl(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        throw StateError('Failed to fetch url (${res.statusCode})');
      }
      final body = res.body;

      // 1) Try JSON-LD schema.org/Recipe
      final fromJsonLd = _parseJsonLd(body, url);
      if (fromJsonLd != null) {
        if (kDebugMode) print('[Import] jsonld hit');
        return fromJsonLd;
      }

      // 2) Try microdata (itemscope itemtype=Recipe)
      final fromMicro = _parseMicrodata(body, url);
      if (fromMicro != null) {
        if (kDebugMode) print('[Import] microdata hit');
        return fromMicro;
      }

      // 3) Fallback heuristics
      if (kDebugMode) print('[Import] fallback');
      return _parseHeuristic(body, url);
    } catch (e) {
      if (kDebugMode) print('[Import] error: $e');
      rethrow;
    }
  }

  DraftRecipe? _parseJsonLd(String html, String url) {
    final doc = htmlp.parse(html);
    final scripts = doc.querySelectorAll('script[type="application/ld+json"]');
    for (final s in scripts) {
      final text = s.text.trim();
      if (text.isEmpty) continue;
      dynamic json;
      try {
        json = jsonDecode(text);
      } catch (_) {
        continue;
      }

      final objs = (json is List) ? json : [json];
      for (final obj in objs) {
        if (obj is Map<String, dynamic>) {
          final type = obj['@type'];
          if (type == 'Recipe' || (type is List && type.contains('Recipe'))) {
            return _draftFromSchemaOrg(obj, url);
          }
          // sometimes graph
          if (obj['@graph'] is List) {
            for (final g in (obj['@graph'] as List)) {
              if (g is Map<String, dynamic>) {
                final t = g['@type'];
                if (t == 'Recipe' || (t is List && t.contains('Recipe'))) {
                  return _draftFromSchemaOrg(g, url);
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  DraftRecipe _draftFromSchemaOrg(Map<String, dynamic> r, String url) {
    String name = (r['name'] ?? 'Imported Recipe').toString();
    int? servings;
    final y = r['recipeYield'];
    if (y != null) {
      final s = y.toString();
      final match = RegExp(r'(\d+)').firstMatch(s);
      if (match != null) servings = int.tryParse(match.group(1)!);
    }
    int? timeMins = _parseIso8601DurationMins(
        r['totalTime'] ?? r['cookTime'] ?? r['prepTime']);

    final ingStrs = ((r['recipeIngredient'] ?? r['ingredients']) as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final stepsList = _extractSteps(r);

    final lines = ingStrs.map(_parseIngredientLine).toList();

    final flags = _inferDietFlags(r);

    return DraftRecipe(
      sourceUrl: url,
      name: name,
      servings: servings,
      timeMins: timeMins,
      ingredients: lines,
      steps: stepsList,
      dietFlags: flags,
    );
  }

  List<String> _extractSteps(Map<String, dynamic> r) {
    final inst = r['recipeInstructions'];
    if (inst is List) {
      return inst
          .map((e) {
            if (e is String) return e;
            if (e is Map<String, dynamic>) {
              if (e['@type'] == 'HowToStep') return (e['text'] ?? '').toString();
              if (e['text'] != null) return e['text'].toString();
            }
            return e.toString();
          })
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    if (inst is String) {
      return inst
          .split(RegExp(r'\r?\n'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  DraftRecipe? _parseMicrodata(String html, String url) {
    final doc = htmlp.parse(html);
    final items = doc.querySelectorAll('[itemscope][itemtype*="Recipe"]');
    if (items.isEmpty) return null;
    final el = items.first;

    String name =
        el.querySelector('[itemprop="name"]')?.text.trim() ?? 'Imported Recipe';
    int? servings;
    final yieldEl = el.querySelector('[itemprop="recipeYield"]');
    if (yieldEl != null) {
      final match = RegExp(r'(\d+)').firstMatch(yieldEl.text);
      if (match != null) servings = int.tryParse(match.group(1)!);
    }
    int? timeMins = _parseIso8601DurationMins(
        el.querySelector('[itemprop="totalTime"]')?.attributes['content'] ??
            el.querySelector('[itemprop="cookTime"]')?.attributes['content'] ??
            el.querySelector('[itemprop="prepTime"]')?.attributes['content']);

    final ingEls = el.querySelectorAll(
        '[itemprop="recipeIngredient"], [itemprop="ingredients"]');
    final lines = (ingEls.isEmpty
            ? const <DraftIngredientLine>[]
            : ingEls.map((e) => _parseIngredientLine(e.text)))
        .toList();

    final stepEls = el.querySelectorAll(
        '[itemprop="recipeInstructions"] li, [itemprop="recipeInstructions"] p');
    final steps =
        stepEls.map((e) => e.text.trim()).where((s) => s.isNotEmpty).toList();

    return DraftRecipe(
      sourceUrl: url,
      name: name,
      servings: servings,
      timeMins: timeMins,
      ingredients: lines,
      steps: steps,
      dietFlags: const [],
    );
  }

  DraftRecipe _parseHeuristic(String html, String url) {
    final doc = htmlp.parse(html);
    String title = (doc.querySelector('meta[property="og:title"]')
                ?.attributes['content'] ??
            doc.querySelector('title')?.text ??
            'Imported Recipe')
        .trim();

    final bodyText = doc.body?.text ?? '';
    final lines = _extractIngredientLinesHeuristic(doc)
        .map(_parseIngredientLine)
        .toList();
    final steps = _extractStepsHeuristic(doc, bodyText);

    return DraftRecipe(
      sourceUrl: url,
      name: title,
      servings: null,
      timeMins: null,
      ingredients: lines,
      steps: steps,
      dietFlags: const [],
    );
  }

  List<String> _extractIngredientLinesHeuristic(hdom.Document doc) {
    final selectors = [
      '.ingredient, .ingredients li, .recipe-ingredients li, .ingredients-item-name',
      '[class*="ingredient"] li',
    ];
    for (final sel in selectors) {
      final els = doc.querySelectorAll(sel);
      if (els.length >= 3) return els.map((e) => e.text.trim()).toList();
    }
    // fallback: find list near "Ingredients"
    final header = doc
        .querySelectorAll('h2, h3')
        .firstWhereOrNull((e) => e.text.toLowerCase().contains('ingredient'));
    if (header != null) {
      final ul = header.nextElementSibling;
      if (ul != null && ul.localName == 'ul') {
        return ul.children
            .map((e) => e.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  List<String> _extractStepsHeuristic(hdom.Document doc, String bodyText) {
    final selectors = [
      '.instructions li, .directions li, .method-steps li',
      '[class*="instruction"] li, [class*="direction"] li',
      'ol li',
    ];
    for (final sel in selectors) {
      final els = doc.querySelectorAll(sel);
      if (els.length >= 2) return els.map((e) => e.text.trim()).toList();
    }
    // fallback: paragraphs after "Instructions"
    final header = doc.querySelectorAll('h2, h3').firstWhereOrNull((e) {
      final t = e.text.toLowerCase();
      return t.contains('instruction') || t.contains('direction');
    });
    if (header != null) {
      final sibs = <String>[];
      var n = header.nextElementSibling;
      int count = 0;
      while (n != null && count < 12) {
        if (n.localName == 'p' && n.text.trim().isNotEmpty) {
          sibs.add(n.text.trim());
        }
        n = n.nextElementSibling;
        count++;
      }
      if (sibs.length >= 2) return sibs;
    }
    return const [];
  }

  int? _parseIso8601DurationMins(dynamic iso) {
    if (iso == null) return null;
    final s = iso.toString();
    final m = RegExp(r'P(T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)').firstMatch(s);
    if (m == null) return null;
    final h = int.tryParse(m.group(2) ?? '0') ?? 0;
    final mm = int.tryParse(m.group(3) ?? '0') ?? 0;
    final ss = int.tryParse(m.group(4) ?? '0') ?? 0;
    return h * 60 + mm + (ss > 0 ? 1 : 0);
  }

  // --- Ingredient line parser (very basic v1) ---
  DraftIngredientLine _parseIngredientLine(String raw) {
    final t = raw.trim();
    // qty (supports vulgar fractions like ½, ¼, etc.)
    final norm = t
        .replaceAll('½', ' 1/2')
        .replaceAll('¼', ' 1/4')
        .replaceAll('¾', ' 3/4')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    double? qty;
    final qtyMatch =
        RegExp(r'^(\d+(?:\s+\d+\/\d+|\.\d+|\/\d+)?)\b').firstMatch(norm);
    if (qtyMatch != null) {
      final q = qtyMatch.group(1)!.trim();
      qty = _parseQuantity(q);
    }

    // unit
    final lower = norm.toLowerCase();
    domain.Unit? unit;
    final unitMap = <String, domain.Unit>{
      'g': domain.Unit.grams,
      'gram': domain.Unit.grams,
      'grams': domain.Unit.grams,
      'ml': domain.Unit.milliliters,
      'milliliter': domain.Unit.milliliters,
      'millilitre': domain.Unit.milliliters,
      'milliliters': domain.Unit.milliliters,
      'cup': domain.Unit.milliliters,
      'cups': domain.Unit.milliliters,
      'tbsp': domain.Unit.milliliters,
      'tablespoon': domain.Unit.milliliters,
      'tablespoons': domain.Unit.milliliters,
      'tsp': domain.Unit.milliliters,
      'teaspoon': domain.Unit.milliliters,
      'teaspoons': domain.Unit.milliliters,
      'piece': domain.Unit.piece,
      'pieces': domain.Unit.piece,
      'pc': domain.Unit.piece,
      'pcs': domain.Unit.piece,
      'egg': domain.Unit.piece,
      'eggs': domain.Unit.piece,
    };
    domain.Unit? detected;
    for (final k in unitMap.keys) {
      if (RegExp('\\b$k\\b').hasMatch(lower)) {
        detected = unitMap[k];
        break;
      }
    }
    unit = detected;

    // name
    String name = norm;
    if (qtyMatch != null) {
      name = name.substring(qtyMatch.group(0)!.length).trim();
    }
    if (detected != null) {
      name = name
          .replaceFirst(
              RegExp('\\b(${unitMap.keys.map(RegExp.escape).join('|')})\\b'),
              '')
          .trim();
    }
    name = name.replaceFirst(RegExp(r'^[\-\–\—\:\,]+'), '').trim();

    // note (comma/paren tail)
    String? note;
    final comma = name.indexOf(',');
    if (comma != -1) {
      note = name.substring(comma + 1).trim();
      name = name.substring(0, comma).trim();
    }

    return DraftIngredientLine(
      rawText: raw,
      qty: qty,
      unit: unit,
      name: name,
      note: note,
    );
  }

  double _parseQuantity(String s) {
    // "1 1/2", "3/4", "1.25"
    final parts = s.split(' ');
    if (parts.length == 2 && parts[1].contains('/')) {
      final whole = double.tryParse(parts[0]) ?? 0;
      final frac = parts[1].split('/');
      final nume = double.tryParse(frac[0]) ?? 0;
      final deno = double.tryParse(frac[1]) ?? 1;
      return whole + (deno == 0 ? 0 : nume / deno);
    }
    if (s.contains('/')) {
      final frac = s.split('/');
      final nume = double.tryParse(frac[0]) ?? 0;
      final deno = double.tryParse(frac[1]) ?? 1;
      return deno == 0 ? 0 : nume / deno;
    }
    return double.tryParse(s) ?? 0;
  }

  List<String> _inferDietFlags(Map<String, dynamic> r) {
    final cats = (r['recipeCategory'] is List
            ? (r['recipeCategory'] as List)
                .map((e) => e.toString().toLowerCase())
                .toList()
            : [r['recipeCategory']?.toString().toLowerCase()])
        .whereType<String>()
        .toList();
    final cuis = (r['recipeCuisine'] is List
            ? (r['recipeCuisine'] as List)
                .map((e) => e.toString().toLowerCase())
                .toList()
            : [r['recipeCuisine']?.toString().toLowerCase()])
        .whereType<String>()
        .toList();
    final tags = <String>[...cats, ...cuis];
    final out = <String>[];
    bool has(String k) => tags.any((t) => t.contains(k));
    if (has('vegetarian') || has('veg')) out.add('veg');
    if (has('gluten') && has('free')) out.add('gf');
    if (has('dairy') && has('free')) out.add('df');
    return out;
  }
}

