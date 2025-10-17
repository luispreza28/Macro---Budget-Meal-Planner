import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/recipe.dart';
import '../../providers/recipe_pref_providers.dart';
import '../../../domain/services/recipe_features.dart';
import '../../../domain/services/pantry_utilization_service.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/taste_providers.dart';
import '../../../domain/services/variety_prefs_service.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/substitution_providers.dart';
import '../../../domain/value/substitution_score.dart';
import '../../providers/micro_providers.dart';

/// Bottom drawer for showing meal swap options
class SwapDrawer extends ConsumerStatefulWidget {
  const SwapDrawer({
    super.key,
    required this.currentRecipe,
    required this.alternatives,
    required this.onSwapSelected,
    required this.onClose,
    this.servingsForMeal = 1,
    this.errorMessage,
    this.isLoading = false,
  });

  const SwapDrawer.loading({
    super.key,
    required this.currentRecipe,
    required this.onClose,
  }) : alternatives = const [],
       onSwapSelected = _noRecipe,
       servingsForMeal = 1,
       errorMessage = null,
       isLoading = true;

  const SwapDrawer.error({
    super.key,
    required this.currentRecipe,
    required this.onClose,
    String message = 'Error',
  }) : alternatives = const [],
       onSwapSelected = _noRecipe,
       servingsForMeal = 1,
       errorMessage = message,
       isLoading = false;

  final Recipe currentRecipe;
  final List<SwapOption> alternatives;
  final void Function(Recipe newRecipe) onSwapSelected;
  final VoidCallback onClose;
  final int servingsForMeal;
  final String? errorMessage;
  final bool isLoading;

  @override
  ConsumerState<SwapDrawer> createState() => _SwapDrawerState();
}

class _SwapDrawerState extends ConsumerState<SwapDrawer> {
  bool _pantryFirst = true;
  bool _cheaperFirst = true; // new filter
  bool _closerMacros = false; // new filter
  bool _computingPantry = false;
  final Map<String, PantryUtilization> _utilCache = {};
  bool _favoritesOnly = false;
  bool _hideExcluded = true;
  bool _avoidRepetition = true; // mirrors prefs (default ON)

  @override
  void initState() {
    super.initState();
    // Mirror prefs default for a gentle alignment
    Future.microtask(() async {
      final svc = ref.read(varietyPrefsServiceProvider);
      final spread = await svc.enableProteinSpread();
      if (!mounted) return;
      setState(() => _avoidRepetition = spread);
    });
  }

  @override
  Widget build(BuildContext context) {
    final alternatives = widget.alternatives;
    final allRecipesAsync = ref.watch(allRecipesProvider);
    final tasteRulesAsync = ref.watch(tasteRulesProvider);
    final subsAsync = ref.watch(
      substitutionScoresProvider((
        currentRecipeId: widget.currentRecipe.id,
        servingsForMeal: widget.servingsForMeal,
      )),
    );

    // Precompute pantry utilization lazily for visible candidates
    Future<void> _ensurePantry() async {
      if (_computingPantry) return;
      _computingPantry = true;
      try {
        final ings = await ref.read(allIngredientsProvider.future);
        final ingById = {for (final i in ings) i.id: i};
        final svc = ref.read(pantryUtilizationServiceProvider);
        for (final opt in alternatives) {
          final id = opt.recipe.id;
          if (_utilCache.containsKey(id)) continue;
          final util = await svc.scoreRecipePantryUse(opt.recipe, ingredientsById: ingById);
          _utilCache[id] = util;
        }
        if (mounted) setState(() {});
      } catch (_) {} finally {
        _computingPantry = false;
      }
    }
    // Kick off once per build if needed
    if (_pantryFirst) { _ensurePantry(); }

    Widget content;
    if (widget.isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (widget.errorMessage != null) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text(
              widget.errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (alternatives.isEmpty) {
      content = const Center(child: Text('No alternatives available'));
    } else {
      final favAsync = ref.watch(favoriteRecipesProvider);
      final exAsync = ref.watch(excludedRecipesProvider);
      final favs = favAsync.asData?.value ?? const <String>{};
      final excluded = exAsync.asData?.value ?? const <String>{};

      List<SwapOption> filtered = alternatives.where((opt) {
        final isFav = favs.contains(opt.recipe.id);
        final isEx = excluded.contains(opt.recipe.id);
        if (_hideExcluded && isEx) return false;
        if (_favoritesOnly && !isFav) return false;
        return true;
      }).toList(growable: false);

      if (_avoidRepetition && filtered.isNotEmpty) {
        final current = widget.currentRecipe;
        final curProt = RecipeFeatures.proteinTag(current);
        final curCui = RecipeFeatures.cuisineTag(current);
        final curBucket = RecipeFeatures.prepBucket(current);
        double score(SwapOption opt) {
          double s = 0;
          if (RecipeFeatures.proteinTag(opt.recipe) == curProt) s -= 0.35;
          if (RecipeFeatures.cuisineTag(opt.recipe) == curCui) s -= 0.25;
          if (RecipeFeatures.prepBucket(opt.recipe) == curBucket) s -= 0.15;
          return s;
        }
        filtered = [...filtered]..sort((a, b) => score(b).compareTo(score(a)));
      }

      // Optionally sort by pantry coverage (desc), tiebreak by existing order
      List<SwapOption> toShow = filtered;
      if (_pantryFirst && _utilCache.isNotEmpty) {
        final order = {for (var i=0;i<filtered.length;i++) filtered[i].recipe.id: i};
        toShow = [...filtered]..sort((a,b) {
          final ca = _utilCache[a.recipe.id]?.coverageRatio ?? 0.0;
          final cb = _utilCache[b.recipe.id]?.coverageRatio ?? 0.0;
          final cmp = cb.compareTo(ca);
          if (cmp != 0) return cmp;
          return (order[a.recipe.id] ?? 0).compareTo(order[b.recipe.id] ?? 0);
        });
      }

      // If Smart Substitutions v2 available, render that list; else legacy
      final recipes = allRecipesAsync.asData?.value ?? const <Recipe>[];
      final byId = {for (final r in recipes) r.id: r};

      List<({Recipe recipe, SubstitutionScore score, double localScore})> smartRows = [];
      subsAsync.whenOrNull(data: (scores) {
        // Adjust order based on local filter weights
        for (final s in scores) {
          final r = byId[s.candidateRecipeId];
          if (r == null) continue;
          // Visibility gates
          if (_pantryFirst && s.pantryGain < 0.05) continue;
          if (_cheaperFirst && s.budgetGain < 0.05) continue;
          if (_closerMacros && s.macroGain < 0.05) continue;
          final wPantry = _pantryFirst ? 0.45 : 0.0;
          final wBudget = _cheaperFirst ? 0.35 : 0.0;
          final wMacro = _closerMacros ? 0.20 : 0.0;
          final any = (wPantry + wBudget + wMacro) > 0;
          final local = any
              ? (s.pantryGain * wPantry + s.budgetGain * wBudget + s.macroGain * wMacro)
              : s.composite;
          smartRows.add((recipe: r, score: s, localScore: local));
        }
        smartRows.sort((b, a) => a.localScore.compareTo(b.localScore));
      });

      content = smartRows.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: smartRows.length,
              itemBuilder: (context, index) {
                final row = smartRows[index];
                final r = row.recipe;
                final s = row.score;
                final isFav = favs.contains(r.id);
                final currencyFmt = NumberFormat.currency(symbol: '\$');
                final pantryPct = (s.coverageDelta * 100);
                final currentMicro = ref.watch(recipeMicroReportProvider(widget.currentRecipe.id));
                final candMicro = ref.watch(recipeMicroReportProvider(r.id));
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isFav) ...[
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                r.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                final prev = widget.currentRecipe;
                                widget.onSwapSelected(r);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Swapped to ${r.name}'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () => widget.onSwapSelected(prev),
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                const SizedBox(height: 8),
                // Taste badges (optional)
                if (tasteRulesAsync.asData?.value != null) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _tasteReasons(r, tasteRulesAsync.asData!.value)
                        .map((e) => _ReasonBadge(reason: e))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                            _ImpactChip(
                              label: '${pantryPct >= 0 ? '+' : ''}${pantryPct.toStringAsFixed(0)}% pantry',
                              isPositive: s.pantryGain > 0,
                              icon: Icons.kitchen,
                            ),
                            _ImpactChip(
                              label: s.weeklyCostDeltaCents <= 0
                                  ? '-${currencyFmt.format(s.weeklyCostDeltaCents.abs() / 100)} / wk'
                                  : '+${currencyFmt.format(s.weeklyCostDeltaCents.abs() / 100)} / wk',
                              isPositive: s.weeklyCostDeltaCents <= 0,
                              icon: Icons.attach_money,
                            ),
                            _ImpactChip(
                              label:
                                  '${s.macroDeltaPerServ.kcal >= 0 ? '+' : ''}${s.macroDeltaPerServ.kcal.toStringAsFixed(0)} kcal • '
                                  '${s.macroDeltaPerServ.proteinG >= 0 ? '+' : ''}${s.macroDeltaPerServ.proteinG.toStringAsFixed(0)}P '
                                  '${s.macroDeltaPerServ.carbsG >= 0 ? '+' : ''}${s.macroDeltaPerServ.carbsG.toStringAsFixed(0)}C '
                                  '${s.macroDeltaPerServ.fatG >= 0 ? '+' : ''}${s.macroDeltaPerServ.fatG.toStringAsFixed(0)}F',
                              isPositive: true,
                              icon: Icons.local_fire_department,
                            ),
                          ],
                        ),
                        // Micro-aware mini cues
                        Builder(builder: (context) {
                          final cur = currentMicro.asData?.value;
                          final cand = candMicro.asData?.value;
                          if (cur == null || cand == null) return const SizedBox.shrink();
                          final (_, curHints) = cur;
                          final (_, candHints) = cand;
                          final cues = <Widget>[];
                          if (curHints.highSodium && !candHints.highSodium) {
                            cues.add(const _ImpactChip(label: 'Lower sodium', isPositive: true, icon: Icons.water_drop));
                          }
                          if (curHints.highSatFat && !candHints.highSatFat) {
                            cues.add(const _ImpactChip(label: 'Lower sat fat', isPositive: true, icon: Icons.crisis_alert));
                          }
                          // Higher fiber threshold: ≥ 2g/serv improvement
                          final curFiber = cur.$0.fiberGPerServ;
                          final candFiber = cand.$0.fiberGPerServ;
                          if (candFiber - curFiber >= 2.0) {
                            cues.add(const _ImpactChip(label: 'Higher fiber', isPositive: true, icon: Icons.grass));
                          }
                          if (cues.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(spacing: 6, runSpacing: 4, children: cues),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            )
          : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: toShow.length,
        itemBuilder: (context, index) {
          final option = toShow[index];
          final isFav = favs.contains(option.recipe.id);
          final util = _utilCache[option.recipe.id];
          final rules = tasteRulesAsync.asData?.value;
          final extra = rules == null ? const <SwapReason>[] : _tasteReasons(option.recipe, rules);
          return _SwapOptionCard(
            option: option,
            isFavorite: isFav,
            onTap: () {
              widget.onSwapSelected(option.recipe);
              widget.onClose();
            },
            reasonsOverride: [...option.reasons, ...extra],
          );
        },
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Swap Meal',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Currently: ${widget.currentRecipe.name}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
              ],
            ),
          ),
          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Favorites only'),
                  selected: _favoritesOnly,
                  onSelected: (v) => setState(() => _favoritesOnly = v),
                  avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Hide excluded'),
                  selected: _hideExcluded,
                  onSelected: (v) => setState(() => _hideExcluded = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Avoid repetition'),
                  selected: _avoidRepetition,
                  onSelected: (v) => setState(() => _avoidRepetition = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pantry-first'),
                  selected: _pantryFirst,
                  onSelected: (v) => setState(() => _pantryFirst = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Cheaper'),
                  selected: _cheaperFirst,
                  onSelected: (v) => setState(() => _cheaperFirst = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Closer macros'),
                  selected: _closerMacros,
                  onSelected: (v) => setState(() => _closerMacros = v),
                ),
              ],
            ),
          ),
          // Alternatives list
          Expanded(child: content),
        ],
      ),
    );
  }

  List<SwapReason> _tasteReasons(Recipe r, TasteRules rules) {
    final out = <SwapReason>[];
    final hasBannedTag = r.dietFlags.any((t) => rules.hardBanTags.contains(t));
    final hasBannedIng = r.items.any((it) => rules.hardBanIng.contains(it.ingredientId));
    if (rules.allowRecipes.contains(r.id) && (hasBannedTag || hasBannedIng)) {
      out.add(const SwapReason(type: SwapReasonType.allowedAllergen, description: 'Allowed (allergen)'));
    }
    final likeCuisine = r.dietFlags.firstWhere(
      (t) => rules.likeTags.contains(t),
      orElse: () => '',
    );
    if (likeCuisine.isNotEmpty) {
      out.add(SwapReason(type: SwapReasonType.tasteCuisine, description: 'Match: $likeCuisine'));
    }
    final hasFavIng = r.items.any((it) => rules.likeIng.contains(it.ingredientId));
    if (hasFavIng) {
      out.add(const SwapReason(type: SwapReasonType.tasteIngredient, description: 'Fav ingredient'));
    }
    final dislikeCuisine = r.dietFlags.firstWhere(
      (t) => rules.dislikeTags.contains(t),
      orElse: () => '',
    );
    if (dislikeCuisine.isNotEmpty) {
      out.add(SwapReason(type: SwapReasonType.tasteDislike, description: 'You dislike $dislikeCuisine'));
    }
    final hasDislikedIng = r.items.any((it) => rules.dislikeIng.contains(it.ingredientId));
    if (hasDislikedIng) {
      out.add(const SwapReason(type: SwapReasonType.tasteDislike, description: 'Contains disliked'));
    }
    return out;
  }
}

class _SwapOptionCard extends StatelessWidget {

  const _SwapOptionCard({required this.option, required this.onTap, this.isFavorite = false, this.pantryUtil, this.reasonsOverride});

  final SwapOption option;
  final VoidCallback onTap;
  final bool isFavorite;
  final PantryUtilization? pantryUtil;
  final List<SwapReason>? reasonsOverride;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe name and basic info
              Row(
                children: [
                  if (isFavorite) ...[
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      option.recipe.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${option.recipe.timeMins} min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Reason badges
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (reasonsOverride ?? option.reasons)
                    .map((reason) => _ReasonBadge(reason: reason))
                    .toList(),
              ),

              const SizedBox(height: 12),

              // Impact summary
              Row(
                children: [
                  if (option.costDeltaCents != 0) ...[
                    _ImpactChip(
                      label: option.costDeltaCents > 0
                          ? '+\$${(option.costDeltaCents / 100).toStringAsFixed(2)}'
                          : '-\$${(-option.costDeltaCents / 100).toStringAsFixed(2)}',
                      isPositive: option.costDeltaCents < 0,
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (option.proteinDeltaG != 0) ...[
                    _ImpactChip(
                      label:
                          '${option.proteinDeltaG > 0 ? '+' : ''}${option.proteinDeltaG.toStringAsFixed(0)}g protein',
                      isPositive: option.proteinDeltaG > 0,
                      icon: Icons.fitness_center,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (option.kcalDelta != 0) ...[
                    _ImpactChip(
                      label:
                          '${option.kcalDelta > 0 ? '+' : ''}${option.kcalDelta.toStringAsFixed(0)} cal',
                      isPositive:
                          option.kcalDelta.abs() <
                          50, // Small calorie changes are good
                      icon: Icons.local_fire_department,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonBadge extends StatelessWidget {
  const _ReasonBadge({required this.reason});

  final SwapReason reason;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (reason.type) {
      case SwapReasonType.cheaper:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.savings;
        break;
      case SwapReasonType.moreExpensive:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.price_change;
        break;
      case SwapReasonType.higherProtein:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.fitness_center;
        break;
      case SwapReasonType.lowerProtein:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.fitness_center;
        break;
      case SwapReasonType.fasterPrep:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.timer;
        break;
      case SwapReasonType.pantryItem:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.kitchen;
        break;
      case SwapReasonType.betterMacros:
        backgroundColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple;
        icon = Icons.analytics;
        break;
      case SwapReasonType.higherCalories:
        backgroundColor = Colors.deepOrange.withOpacity(0.1);
        textColor = Colors.deepOrange;
        icon = Icons.local_fire_department;
        break;
      case SwapReasonType.lowerCalories:
        backgroundColor = Colors.teal.withOpacity(0.1);
        textColor = Colors.teal;
        icon = Icons.ac_unit;
        break;
      case SwapReasonType.tasteCuisine:
        backgroundColor = Colors.indigo.withOpacity(0.1);
        textColor = Colors.indigo;
        icon = Icons.local_dining;
        break;
      case SwapReasonType.tasteIngredient:
        backgroundColor = Colors.indigo.withOpacity(0.1);
        textColor = Colors.indigo;
        icon = Icons.restaurant;
        break;
      case SwapReasonType.tasteDislike:
        backgroundColor = Colors.brown.withOpacity(0.1);
        textColor = Colors.brown;
        icon = Icons.thumb_down_alt_outlined;
        break;
      case SwapReasonType.allowedAllergen:
        backgroundColor = Colors.amber.withOpacity(0.2);
        textColor = Colors.amber.shade900;
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            reason.description,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  const _ImpactChip({
    required this.label,
    required this.isPositive,
    required this.icon,
  });

  final String label;
  final bool isPositive;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Data classes for swap functionality
class SwapOption {
  const SwapOption({
    required this.recipe,
    required this.reasons,
    required this.costDeltaCents,
    required this.proteinDeltaG,
    required this.kcalDelta,
  });

  final Recipe recipe;
  final List<SwapReason> reasons;
  final int costDeltaCents; // Cost difference in cents
  final double proteinDeltaG; // Protein difference in grams
  final double kcalDelta; // Calorie difference
}

class SwapReason {
  const SwapReason({required this.type, required this.description});

  final SwapReasonType type;
  final String description;
}

enum SwapReasonType {
  cheaper,
  moreExpensive,
  higherProtein,
  lowerProtein,
  fasterPrep,
  pantryItem,
  betterMacros,
  higherCalories,
  lowerCalories,
  tasteCuisine,
  tasteIngredient,
  tasteDislike,
  allowedAllergen,
}

void _noRecipe(Recipe _) {}













