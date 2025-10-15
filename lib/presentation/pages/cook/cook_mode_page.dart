import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/plan.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/entities/ingredient.dart' as domain;
import '../../../domain/services/meal_log_service.dart';
import '../../../domain/services/pantry_deduct_service.dart';
import '../../providers/plan_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/pantry_providers.dart';
import '../../providers/shortfall_providers.dart';
import '../../providers/insights_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/meal_log_providers.dart';
import '../../providers/prepared_providers.dart';
import '../../../domain/services/prepared_inventory_service.dart';
import 'package:intl/intl.dart';

class CookModePage extends ConsumerStatefulWidget {
  const CookModePage({super.key, required this.planMealId});
  final String planMealId; // expected format: d{day}-m{meal}

  @override
  ConsumerState<CookModePage> createState() => _CookModePageState();
}

class _CookModePageState extends ConsumerState<CookModePage> {
  int _servingsCooked = 1;
  bool _processing = false;
  final Map<int, bool> _checked = {};
  final Map<int, _StepTimer> _timers = {};

  ({int day, int meal})? _parseSlot(String s) {
    // slotKey used elsewhere: 'd{day}-m{meal}'
    try {
      final dIdx = s.indexOf('d');
      final mIdx = s.indexOf('-m');
      if (dIdx != 0 || mIdx <= 1) return null;
      final day = int.parse(s.substring(1, mIdx));
      final meal = int.parse(s.substring(mIdx + 2));
      return (day: day, meal: meal);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = _parseSlot(widget.planMealId);
    final planAsync = ref.watch(currentPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cook Mode'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load plan: $e')),
        data: (plan) {
          if (plan == null) {
            return const Center(child: Text('No active plan'));
          }
          if (slot == null) {
            return const Center(child: Text('Invalid meal slot'));
          }
          if (plan.days.isEmpty || slot.day >= plan.days.length) {
            return const Center(child: Text('Meal slot not found'));
          }
          final day = plan.days[slot.day];
          if (slot.meal >= day.meals.length) {
            return const Center(child: Text('Meal slot not found'));
          }
          final meal = day.meals[slot.meal];
          final servingsForMeal = meal.servings.round().clamp(1, 999);
          _servingsCooked = _servingsCooked.clamp(1, servingsForMeal);

          final recipeAsync = ref.watch(recipeByIdProvider(meal.recipeId));
          final ingredientsAsync = ref.watch(allIngredientsProvider);

          return recipeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load recipe: $e')),
            data: (recipe) {
              if (recipe == null) {
                return const Center(child: Text('Recipe not found'));
              }

              return ingredientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load ingredients: $e')),
                data: (ings) {
                  final byId = {for (final i in ings) i.id: i};
                  return _buildBody(context, plan: plan, recipe: recipe, servingsMax: servingsForMeal, ingredientsById: byId);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required Plan plan,
    required Recipe recipe,
    required int servingsMax,
    required Map<String, domain.Ingredient> ingredientsById,
  }) {
    return SafeArea(
      child: Column(
        children: [
          _header(context, recipe: recipe, servingsMax: servingsMax),
          const Divider(height: 1),
          Expanded(child: _stepsList(context, recipe: recipe)),
          const Divider(height: 1),
          _footer(context, recipe: recipe, ingredientsById: ingredientsById),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, {required Recipe recipe, required int servingsMax}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recipe.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                  const SizedBox(width: 6),
                  DropdownButton<int>(
                    value: _servingsCooked.clamp(1, servingsMax),
                    onChanged: (v) => setState(() => _servingsCooked = (v ?? 1).clamp(1, servingsMax)),
                    items: [for (var i = 1; i <= servingsMax; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('${recipe.timeMins} min', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 12),
              if (recipe.dietFlags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: recipe.dietFlags.take(3).map((f) => Chip(label: Text(f), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepsList(BuildContext context, {required Recipe recipe}) {
    final steps = recipe.steps.isEmpty
        ? [
            'Gather ingredients',
            'Prep ingredients',
            'Cook according to method',
          ]
        : recipe.steps;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: steps.length,
      separatorBuilder: (_, __) => const Divider(height: 12),
      itemBuilder: (ctx, i) {
        final done = _checked[i] ?? false;
        final t = _timers[i];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: done,
              onChanged: (v) => setState(() => _checked[i] = v ?? false),
            ),
            Expanded(
              child: Text(
                steps[i],
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            _timerChip(i, t),
          ],
        );
      },
    );
  }

  Widget _timerChip(int index, _StepTimer? t) {
    if (t == null) {
      return OutlinedButton.icon(
        onPressed: () => _pickTimer(index),
        icon: const Icon(Icons.timer_outlined, size: 18),
        label: const Text('Timer'),
      );
    }
    final remaining = t.remaining;
    final mm = (remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (remaining % 60).toString().padLeft(2, '0');
    final color = remaining > 0 ? Colors.orange : Colors.green;
    return InputChip(
      avatar: Icon(remaining > 0 ? Icons.timer : Icons.check, color: color, size: 18),
      label: Text('$mm:$ss'),
      onDeleted: () => setState(() => _cancelTimer(index)),
      onPressed: () => setState(() => _toggleTimer(index)),
    );
  }

  Future<void> _pickTimer(int index) async {
    final seconds = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) => _TimerPickerSheet(),
    );
    if (seconds == null || seconds <= 0) return;
    setState(() {
      _timers[index]?.cancel();
      _timers[index] = _StepTimer(seconds: seconds, onTick: () => setState(() {}));
    });
  }

  void _toggleTimer(int index) {
    final t = _timers[index];
    if (t == null) return;
    t.toggle();
  }

  void _cancelTimer(int index) {
    _timers[index]?.cancel();
    _timers.remove(index);
  }

  Widget _footer(BuildContext context, {
    required Recipe recipe,
    required Map<String, domain.Ingredient> ingredientsById,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _processing ? null : () => context.pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _processing ? null : () => _onMarkCooked(context, recipe, ingredientsById),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark Cooked'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMarkCooked(BuildContext context, Recipe recipe, Map<String, domain.Ingredient> ingredientsById) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      if (recipe.items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No ingredients to deduct')));
        }
        return;
      }
      final svc = ref.read(pantryDeductServiceProvider);
      final deltas = await svc.deductForCook(
        recipe: recipe,
        servingsCooked: _servingsCooked,
        ingredientsById: ingredientsById,
      );
      if (deltas.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing deducted (unit mismatch or zero)')));
        }
        return;
      }

      final entry = MealLogEntry(
        id: const Uuid().v4(),
        recipeId: recipe.id,
        cookedAt: DateTime.now(),
        servingsCooked: _servingsCooked,
      );
      await ref.read(mealLogServiceProvider).append(entry);

      if (!mounted) return;

      // Invalidate interested providers: pantry + meal log + shortfalls + insights
      ref.invalidate(allPantryItemsProvider);
      ref.invalidate(mealLogProvider);
      // Any per-meal shortfall consumers will recompute on-demand
      ref.invalidate(insightsPantryProvider);
      ref.invalidate(insightsBudgetProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pantry deducted for ${deltas.length} ingredients'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                // Add back same amounts
                final list = deltas.entries
                    .map((e) => (ingredientId: e.key, qty: e.value, unit: ingredientsById[e.key]!.unit))
                    .toList();
                await ref.read(pantryRepositoryProvider).addOnHandDeltas(list);
                await ref.read(mealLogServiceProvider).remove(entry.id);
                ref.invalidate(allPantryItemsProvider);
                ref.invalidate(mealLogProvider);
                ref.invalidate(insightsPantryProvider);
                ref.invalidate(insightsBudgetProvider);
              } catch (e) {
                if (kDebugMode) debugPrint('[CookMode] Undo failed: $e');
              }
            },
          ),
        ),
      );
      if (kDebugMode) debugPrint('[CookMode] Deducted and logged cook event');

      // After marking cooked, ask how many servings were eaten now and save leftovers
      if (!mounted) return;
      final ate = await showModalBottomSheet<_PostCookResult>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _PostCookSheet(
          maxServings: _servingsCooked,
        ),
      );
      if (ate != null) {
        final left = (_servingsCooked - ate.servingsAteNow).clamp(0, _servingsCooked);
        if (left > 0) {
          final expires = ate.expiresAt;
          final storage = ate.storage;
          await ref.read(preparedInventoryServiceProvider).add(
                recipe.id,
                PreparedEntry(
                  servings: left,
                  madeAt: DateTime.now(),
                  expiresAt: expires,
                  storage: storage,
                ),
              );
          ref.invalidate(preparedServingsProvider(recipe.id));
          ref.invalidate(preparedEntriesProvider(recipe.id));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved $left leftover servings'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await ref.read(preparedInventoryServiceProvider).consume(recipe.id, left);
                  ref.invalidate(preparedServingsProvider(recipe.id));
                  ref.invalidate(preparedEntriesProvider(recipe.id));
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }
}

class _StepTimer {
  _StepTimer({required int seconds, required this.onTick})
      : _remaining = seconds,
        _seconds = seconds {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running) return;
      if (_remaining <= 0) return;
      _remaining -= 1;
      onTick();
    });
  }
  final void Function() onTick;
  late Timer _timer;
  int _remaining;
  final int _seconds;
  bool _running = true;

  int get remaining => _remaining;
  bool get isRunning => _running && _remaining > 0;

  void toggle() {
    if (_remaining <= 0) return;
    _running = !_running;
  }

  void cancel() {
    _timer.cancel();
  }
}

class _TimerPickerSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<({String label, int seconds})> options = const [
      (label: '30 sec', seconds: 30),
      (label: '2 min', seconds: 120),
      (label: '5 min', seconds: 300),
      (label: '10 min', seconds: 600),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start a timer', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: options
                  .map((o) => OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(o.seconds),
                        child: Text(o.label),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Post-cook leftovers sheet ----------

class _PostCookResult {
  _PostCookResult({required this.servingsAteNow, required this.storage, required this.expiresAt});
  final int servingsAteNow;
  final Storage storage;
  final DateTime? expiresAt;
}

class _PostCookSheet extends StatefulWidget {
  const _PostCookSheet({required this.maxServings});
  final int maxServings;
  @override
  State<_PostCookSheet> createState() => _PostCookSheetState();
}

class _PostCookSheetState extends State<_PostCookSheet> {
  int _ate = 0; // can be 0..max
  Storage _storage = Storage.fridge;
  DateTime? _expiry;

  @override
  void initState() {
    super.initState();
    _storage = Storage.fridge;
    _expiry = DateTime.now().add(const Duration(days: 3));
  }

  @override
  Widget build(BuildContext context) {
    final left = (widget.maxServings - _ate).clamp(0, widget.maxServings);
    final df = DateFormat.yMMMd();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How many servings did you eat now?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(onPressed: () => setState(() => _ate = (_ate - 1).clamp(0, widget.maxServings)), icon: const Icon(Icons.remove_circle_outline)),
                Text('$_ate / ${widget.maxServings}', style: Theme.of(context).textTheme.titleLarge),
                IconButton(onPressed: () => setState(() => _ate = (_ate + 1).clamp(0, widget.maxServings)), icon: const Icon(Icons.add_circle_outline)),
                const Spacer(),
                Text('Leftovers: $left', style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text('Storage', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Fridge (+3d)'),
                  selected: _storage == Storage.fridge,
                  onSelected: (_) => setState(() {
                    _storage = Storage.fridge;
                    _expiry = DateTime.now().add(const Duration(days: 3));
                  }),
                ),
                ChoiceChip(
                  label: const Text('Freezer (+30d)'),
                  selected: _storage == Storage.freezer,
                  onSelected: (_) => setState(() {
                    _storage = Storage.freezer;
                    _expiry = DateTime.now().add(const Duration(days: 30));
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Expiry: ', style: Theme.of(context).textTheme.bodyMedium),
                Text(_expiry == null ? 'None' : df.format(_expiry!), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                      initialDate: _expiry ?? now.add(const Duration(days: 3)),
                    );
                    if (picked != null) setState(() => _expiry = picked);
                  },
                  child: const Text('Pick date'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _expiry = null),
                  child: const Text('No expiry'),
                )
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_PostCookResult(servingsAteNow: _ate, storage: _storage, expiresAt: _expiry)),
                child: const Text('Save'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
