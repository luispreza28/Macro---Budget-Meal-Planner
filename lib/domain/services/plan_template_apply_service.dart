import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/plan.dart';
import '../../domain/services/plan_templates_service.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../../presentation/providers/database_providers.dart';

final planTemplateApplyServiceProvider = Provider<PlanTemplateApplyService>((ref) => PlanTemplateApplyService(ref));

class PlanTemplateApplyService {
  PlanTemplateApplyService(this.ref);
  final Ref ref;

  /// Preview: detect missing recipe/ingredient IDs vs local catalog.
  Future<TemplatePreview> preview(Map<String, dynamic> payload) async {
    final localIngs = await ref.read(allIngredientsProvider.future);
    final localRecipes = await ref.read(allRecipesProvider.future);
    final haveIng = {for (final i in localIngs) i.id: true};
    final haveRec = {for (final r in localRecipes) r.id: true};

    final tplIngs = ((payload['ingredients'] as List?) ?? const <dynamic>[]).cast<Map<String, dynamic>>();
    final tplRecipes = ((payload['recipes'] as List?) ?? const <dynamic>[]).cast<Map<String, dynamic>>();

    final missingIng = <Map<String, dynamic>>[];
    final missingRec = <Map<String, dynamic>>[];
    for (final i in tplIngs) {
      final id = i['id'] as String?;
      if (id == null) continue;
      if (!haveIng.containsKey(id)) missingIng.add(i);
    }
    for (final r in tplRecipes) {
      final id = r['id'] as String?;
      if (id == null) continue;
      if (!haveRec.containsKey(id)) missingRec.add(r);
    }

    return TemplatePreview(missingIngredients: missingIng, missingRecipes: missingRec);
  }

  /// Import: upsert missing ingredients/recipes, then optionally save a local PlanTemplate entry for reuse.
  Future<void> importAndSave({
    required Map<String, dynamic> payload,
    String? saveLocalTemplateId,
    String? templateName,
    List<String> tags = const [],
    String? coverEmoji,
    String? notes,
  }) async {
    final ingRepo = ref.read(ingredientRepositoryProvider);
    final recRepo = ref.read(recipeRepositoryProvider);

    for (final i in ((payload['ingredients'] as List?) ?? const []).cast<Map<String, dynamic>>()) {
      // minimal upsert from JSON in repo implementation
      await ingRepo.upsertFromJson(i);
    }
    for (final r in ((payload['recipes'] as List?) ?? const []).cast<Map<String, dynamic>>()) {
      await recRepo.upsertFromJson(r);
    }
    if (saveLocalTemplateId != null) {
      final t = PlanTemplate(
        id: saveLocalTemplateId,
        name: templateName ?? 'Imported Template',
        coverEmoji: coverEmoji,
        tags: tags,
        notes: notes,
        createdAt: DateTime.now(),
        days: ((payload['plan']?['days'] as List?)?.length ?? 7),
        payload: payload,
      );
      await ref.read(planTemplatesServiceProvider).upsert(t);
    }
  }

  /// Instantiate a plan from the template payload (v1 keeps dates/servings as-is).
  Future<Plan> instantiatePlan(Map<String, dynamic> payload) async {
    return Plan.fromJson((payload['plan'] as Map).cast<String, dynamic>());
  }
}

class TemplatePreview {
  final List<Map<String, dynamic>> missingIngredients;
  final List<Map<String, dynamic>> missingRecipes;
  const TemplatePreview({required this.missingIngredients, required this.missingRecipes});
}
