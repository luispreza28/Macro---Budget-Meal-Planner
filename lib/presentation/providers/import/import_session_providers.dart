import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ImportSession {
  final String id;
  final String? title;
  final int? servingsHint;
  final List<String> ocrPages; // raw text per page
  final List<ParsedIngredient> ingredients; // after parse
  final List<String> steps; // optional
  final bool parsingDone;
  const ImportSession({
    required this.id,
    this.title,
    this.servingsHint,
    this.ocrPages = const [],
    this.ingredients = const [],
    this.steps = const [],
    this.parsingDone = false,
  });
  ImportSession copyWith({
    String? title, int? servingsHint, List<String>? ocrPages,
    List<ParsedIngredient>? ingredients, List<String>? steps, bool? parsingDone,
  }) => ImportSession(
    id: id,
    title: title ?? this.title,
    servingsHint: servingsHint ?? this.servingsHint,
    ocrPages: ocrPages ?? this.ocrPages,
    ingredients: ingredients ?? this.ingredients,
    steps: steps ?? this.steps,
    parsingDone: parsingDone ?? this.parsingDone,
  );
}

class ParsedIngredient {
  final String raw;           // original line
  final double? qty;
  final String? unitToken;    // as seen ("g","ml","cup","oz","lb","pc",etc.)
  final String nameGuess;     // stripped text
  final double confidence;    // 0..1 parse confidence
  const ParsedIngredient({
    required this.raw,
    required this.qty,
    required this.unitToken,
    required this.nameGuess,
    this.confidence = 0.7,
  });
}

final importSessionProvider = StateNotifierProvider<ImportSessionNotifier, ImportSession>((ref){
  return ImportSessionNotifier();
});

class ImportSessionNotifier extends StateNotifier<ImportSession> {
  ImportSessionNotifier(): super(ImportSession(id: const Uuid().v4()));
  void reset() => state = ImportSession(id: const Uuid().v4());
  void setOCR(List<String> pages) => state = state.copyWith(ocrPages: pages);
  void setParse({String? title, int? servings, List<ParsedIngredient>? ings, List<String>? steps}) {
    state = state.copyWith(title: title, servingsHint: servings, ingredients: ings, steps: steps, parsingDone: true);
  }
}

