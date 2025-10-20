import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/services/ingredient_matcher.dart';
import '../../providers/ingredient_providers.dart';

final ingredientSuggestionsProvider = FutureProvider.family((ref, String nameGuess) async {
  final ings = await ref.read(allIngredientsProvider.future);
  return IngredientMatcher.suggest(nameGuess: nameGuess, catalog: ings, limit: 5);
});

