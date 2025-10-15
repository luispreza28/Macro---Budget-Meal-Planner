import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/import/draft_recipe.dart';

/// Holds the current draft recipe during the import flow
final draftRecipeProvider = StateProvider<DraftRecipe?>((_) => null);

