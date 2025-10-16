import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'leftovers_inventory_service.dart';
import 'leftovers_overlay_service.dart';

final leftoversSchedulerServiceProvider =
    Provider<LeftoversSchedulerService>((ref) => LeftoversSchedulerService(ref));

class LeftoversSchedulerService {
  LeftoversSchedulerService(this.ref);
  final Ref ref;
  static const _tag = '[LeftoverSched]';

  /// Compute leftover placements for current week, respecting expiry and spacing.
  ///
  /// Rules v1:
  /// - Only schedule portions whose `expiresAt` falls within this week window (or next 2 days of next week if enabled).
  /// - Fill empty meal slots first. If none, suggest replacing the least-diverse slot but mark as unconfirmed.
  /// - Spacing: avoid scheduling the same recipe in two consecutive meal slots (min gap 1 meal).
  /// - Servings: place 1 serving per placement; multiple servings create multiple placements across different days/slots when possible.
  Future<List<LeftoverPlacement>> plan({
    required String planId,
    required DateTime weekStart, // start of the week shown (00:00)
    required List<List<MealSlot>> basePlanSlots, // [7][n] with recipeId or null
    required bool allowCrossWeekGrace, // if true, allow expires up to weekStart+8/9 days
  }) async {
    final inv = await ref.read(leftoversInventoryServiceProvider).list();
    final start = weekStart;
    final end = start.add(const Duration(days: 7));
    final graceEnd = allowCrossWeekGrace ? end.add(const Duration(days: 2)) : end;

    // Candidate portions that need scheduling within window and have servings
    final candidates = inv
        .where((p) => p.servingsRemaining > 0 && p.expiresAt.isBefore(graceEnd))
        .toList()
      ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt)); // schedule urgent first

    final placements = <LeftoverPlacement>[];

    bool isSlotFree(int day, int meal) => basePlanSlots[day][meal].recipeId == null;
    bool violatesSpacing(int day, int meal, String recipeId) {
      // check immediate previous/next slots for same recipe (in base plan or already placed leftovers)
      final neighbors = <String>[];
      if (meal - 1 >= 0) neighbors.add(basePlanSlots[day][meal - 1].recipeId ?? '');
      if (meal + 1 < basePlanSlots[day].length) {
        neighbors.add(basePlanSlots[day][meal + 1].recipeId ?? '');
      }
      for (final pl in placements) {
        if (pl.dayIndex == day && (pl.mealIndex == meal - 1 || pl.mealIndex == meal + 1)) {
          neighbors.add(pl.recipeId);
        }
      }
      return neighbors.contains(recipeId);
    }

    for (final p in candidates) {
      int remaining = p.servingsRemaining;
      // pass 1: try free slots before expiry, across the week window
      for (int day = 0; day < 7 && remaining > 0; day++) {
        final dayDate = start.add(Duration(days: day));
        if (dayDate.isAfter(p.expiresAt)) break;

        for (int meal = 0; meal < basePlanSlots[day].length && remaining > 0; meal++) {
          if (!isSlotFree(day, meal)) continue;
          if (violatesSpacing(day, meal, p.recipeId)) continue;
          placements.add(LeftoverPlacement(
            portionId: p.id,
            recipeId: p.recipeId,
            dayIndex: day,
            mealIndex: meal,
            servings: 1,
            confirmed: true,
          ));
          remaining--;
        }
      }

      // pass 2: suggest replacements (unconfirmed)
      for (int day = 0; day < 7 && remaining > 0; day++) {
        final dayDate = start.add(Duration(days: day));
        if (dayDate.isAfter(p.expiresAt)) break;
        int? pick;
        for (int meal = basePlanSlots[day].length - 1; meal >= 0; meal--) {
          if (violatesSpacing(day, meal, p.recipeId)) continue;
          pick = meal;
          break;
        }
        if (pick != null) {
          placements.add(LeftoverPlacement(
            portionId: p.id,
            recipeId: p.recipeId,
            dayIndex: day,
            mealIndex: pick,
            servings: 1,
            confirmed: false,
          ));
          remaining--;
        }
      }
    }

    if (kDebugMode) {
      debugPrint('$_tag planned ${placements.length} placements for ${candidates.length} portions');
    }
    return placements;
  }
}

// Simple meal slot facade for scheduling; adapt to your plan model.
class MealSlot {
  final String? recipeId; // null means empty slot
  const MealSlot(this.recipeId);
}

