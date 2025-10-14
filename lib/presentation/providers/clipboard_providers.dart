import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recipe.dart';

/// Cross-screen clipboard for recipe items. Memory-only.
final recipeItemsClipboardProvider =
    StateProvider<List<RecipeItem>?>((_) => null);

