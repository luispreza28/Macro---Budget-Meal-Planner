import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ingredient.dart' as domain;
import 'store_profile_service.dart';
import 'unit_align.dart';

final substitutionCostServiceProvider = Provider<SubstitutionCostService>((ref) => SubstitutionCostService(ref));

class SubstitutionCostService {
  SubstitutionCostService(this.ref);
  final Ref ref;

  Future<int?> deltaCentsPerServ({
    required domain.Ingredient sourceIng,
    required double sourceQty,
    required domain.Unit sourceUnit,
    required domain.Ingredient candIng,
    required double candQtyBase, // in candidate base unit
  }) async {
    try {
      final store = await ref.read(storeProfileServiceProvider).getSelected();
      final overrides = store?.priceOverrideCentsByIngredientId ?? const <String, int>{};
      final srcPPU = overrides[sourceIng.id] ?? sourceIng.pricePerUnitCents;
      final candPPU = overrides[candIng.id] ?? candIng.pricePerUnitCents;

      final srcBase = alignQty(qty: sourceQty, from: sourceUnit, to: sourceIng.unit, ing: sourceIng);
      if (srcBase == null) return null;
      final srcCost = (srcBase * srcPPU).round();
      final candCost = (candQtyBase * candPPU).round();
      return (candCost - srcCost);
    } catch (e) {
      if (kDebugMode) debugPrint('[Subs] cost delta failed: $e');
      return null;
    }
  }
}

