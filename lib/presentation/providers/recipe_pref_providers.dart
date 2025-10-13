import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/recipe_prefs_service.dart';

final favoriteRecipesProvider = FutureProvider<Set<String>>((ref) async {
  final svc = ref.read(recipePrefsServiceProvider);
  return svc.getFavorites();
});

final excludedRecipesProvider = FutureProvider<Set<String>>((ref) async {
  final svc = ref.read(recipePrefsServiceProvider);
  return svc.getExcluded();
});

/// For a single recipe quick lookup
final isFavoriteProvider = FutureProvider.family<bool, String>((ref, recipeId) async {
  final svc = ref.read(recipePrefsServiceProvider);
  return svc.isFavorite(recipeId);
});

final isExcludedProvider = FutureProvider.family<bool, String>((ref, recipeId) async {
  final svc = ref.read(recipePrefsServiceProvider);
  return svc.isExcluded(recipeId);
});

