import '../../domain/entities/recipe.dart';
import '../../presentation/widgets/plan_widgets/swap_drawer.dart';

/// Service that maps candidate recipes into swap options for the UI.
class RecommendationService {
  const RecommendationService();

  /// Convert a list of candidate recipes into UI-ready swap options.
  List<SwapOption> toSwapOptions({
    required Recipe current,
    required List<Recipe> candidates,
  }) {
    return candidates
        .where((recipe) => recipe.id != current.id)
        .take(8)
        .map((recipe) {
          final kcalDelta =
              recipe.macrosPerServ.kcal - current.macrosPerServ.kcal;
          final proteinDelta =
              recipe.macrosPerServ.proteinG - current.macrosPerServ.proteinG;
          final costDeltaCents =
              recipe.costPerServCents - current.costPerServCents;

          final kcalDeltaRounded = kcalDelta.round();
          final proteinDeltaRounded = proteinDelta.round();

          final reasons = <SwapReason>[];
          if (costDeltaCents < 0) {
            reasons.add(
              SwapReason(
                type: SwapReasonType.cheaper,
                description:
                    'Save \$${(costDeltaCents.abs() / 100).toStringAsFixed(2)} / serving',
              ),
            );
          } else if (costDeltaCents > 0) {
            reasons.add(
              SwapReason(
                type: SwapReasonType.moreExpensive,
                description:
                    '+\$${(costDeltaCents / 100).toStringAsFixed(2)} / serving',
              ),
            );
          }
          if (proteinDeltaRounded > 0) {
            reasons.add(
              SwapReason(
                type: SwapReasonType.higherProtein,
                description: '+${proteinDeltaRounded}g protein',
              ),
            );
          } else if (proteinDeltaRounded < 0) {
            reasons.add(
              SwapReason(
                type: SwapReasonType.lowerProtein,
                description: '${proteinDeltaRounded}g protein',
              ),
            );
          }
          if (kcalDeltaRounded != 0) {
            reasons.add(
              SwapReason(
                type: kcalDeltaRounded > 0
                    ? SwapReasonType.higherCalories
                    : SwapReasonType.lowerCalories,
                description:
                    '${kcalDeltaRounded > 0 ? '+' : ''}$kcalDeltaRounded kcal',
              ),
            );
          }

          return SwapOption(
            recipe: recipe,
            reasons: reasons,
            costDeltaCents: costDeltaCents,
            proteinDeltaG: proteinDelta,
            kcalDelta: kcalDelta,
          );
        })
        .toList(growable: false);
  }
}
