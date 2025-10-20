import 'dart:math';

class LineParseResult {
  final String title;
  final int? servingsHint;
  final List<ParsedLine> ingredients;
  final List<String> steps;
  const LineParseResult({required this.title, this.servingsHint, required this.ingredients, required this.steps});
}

class ParsedLine {
  final String raw;
  final double? qty;
  final String? unitToken; // 'g','ml','oz','lb','cup','tbsp','tsp','pc' etc.
  final String nameGuess;
  final double confidence;
  const ParsedLine({required this.raw, this.qty, this.unitToken, required this.nameGuess, this.confidence = 0.7});
}

class IngredientLineParser {
  static final _qty = RegExp(r'^\s*(\d+(?:[.,]\d+)?|\d+/\d+)\b');
  static final _unit = RegExp(r'\b(g|gram|grams|ml|milliliter|milliliters|oz|ounce|ounces|lb|pound|cup|cups|tbsp|tsp|teaspoon|tablespoon|pc|piece|pieces)\b', caseSensitive: false);
  static final _servings = RegExp(r'\b(serves|servings|makes)\s+(\d+)\b', caseSensitive: false);

  static LineParseResult parse(String fullText) {
    final lines = fullText.split('\n').map((l)=>l.trim()).where((l)=>l.isNotEmpty).toList();
    final title = lines.isNotEmpty ? lines.first : 'Imported Recipe';
    int? servings;
    for (final l in lines.take(10)) {
      final m = _servings.firstMatch(l);
      if (m != null) { servings = int.tryParse(m.group(2)!); break; }
    }

    final stopIdx = lines.indexWhere((l)=> RegExp(r'^(directions|instructions|method)\b', caseSensitive: false).hasMatch(l));
    final ingLines = lines.sublist(1, stopIdx == -1 ? min(lines.length, 40) : stopIdx)
                          .where((l)=> l.length < 120 && RegExp(r'[a-zA-Z]').hasMatch(l))
                          .toList();

    final parsed = <ParsedLine>[];
    for (final raw in ingLines) {
      final q = _qty.firstMatch(raw);
      double? qty;
      if (q != null) {
        final s = q.group(1)!.replaceAll(',', '.');
        qty = s.contains('/') ? _frac(s) : double.tryParse(s);
      }
      String? unit;
      final u = _unit.firstMatch(raw);
      if (u != null) unit = (u.group(1) ?? '').toLowerCase();
      final name = raw.replaceFirst(_qty, '').replaceFirst(_unit, '').replaceAll(RegExp(r'^\W+'), '').trim();
      final conf = (qty != null ? 0.8 : 0.6) + (unit != null ? 0.1 : 0);
      parsed.add(ParsedLine(raw: raw, qty: qty, unitToken: unit, nameGuess: name, confidence: conf.clamp(0.0, 1.0)));
    }

    final steps = (stopIdx == -1) ? <String>[] : lines.sublist(stopIdx + 1);

    return LineParseResult(title: title, servingsHint: servings, ingredients: parsed, steps: steps);
  }

  static double _frac(String s) {
    final parts = s.split('/');
    final a = double.tryParse(parts[0]) ?? 0;
    final b = double.tryParse(parts[1]) ?? 1;
    return a / b;
  }
}

