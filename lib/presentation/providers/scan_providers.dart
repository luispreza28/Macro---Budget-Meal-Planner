import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/services/scan_queue_service.dart';
import '../../domain/services/sku_mapping_service.dart';
import '../../domain/services/scan_processor_service.dart';
import '../providers/database_providers.dart';
import '../providers/ingredient_providers.dart';
import '../../domain/value/shortfall_item.dart';
import '../../domain/entities/ingredient.dart' as ing;
import '../providers/plan_providers.dart';
import '../providers/store_providers.dart';

final scanQueueProvider = FutureProvider<List<ScanItem>>((ref) async {
  return ref.read(scanQueueServiceProvider).list();
});

final enqueueScanProvider =
    FutureProvider.family<bool, (String ean, {String? storeId})>((ref, arg) async {
  final (ean, storeId) = arg;
  final item = ScanItem(
    id: const Uuid().v4(),
    ean: ean,
    createdAt: DateTime.now(),
    storeId: storeId,
    status: ScanStatus.pending.name,
  );
  await ref.read(scanQueueServiceProvider).add(item);
  ref.invalidate(scanQueueProvider);
  return true;
});

final linkScanToIngredientProvider =
    FutureProvider.family<bool, (String scanId, String ingredientId)>((ref, arg) async {
  final (scanId, ingId) = arg;
  final all = await ref.read(scanQueueServiceProvider).list();
  final it = all.firstWhere((x) => x.id == scanId);
  await ref.read(scanQueueServiceProvider).upsert(it.copyWith(ingredientId: ingId));
  await ref.read(skuMappingServiceProvider).put(it.ean, ingId);
  ref.invalidate(scanQueueProvider);
  return true;
});

final updateScanPriceProvider = FutureProvider.family<
    bool,
    (String scanId, {int? priceCents, double? packQty, String? packUnit, String? storeId})>((ref, arg) async {
  final (scanId, {priceCents, packQty, packUnit, storeId}) = arg;
  final all = await ref.read(scanQueueServiceProvider).list();
  final it = all.firstWhere((x) => x.id == scanId);
  await ref.read(scanQueueServiceProvider).upsert(
        it.copyWith(
          priceCents: priceCents ?? it.priceCents,
          packQty: packQty ?? it.packQty,
          packUnit: packUnit ?? it.packUnit,
          storeId: storeId ?? it.storeId,
        ),
      );
  ref.invalidate(scanQueueProvider);
  return true;
});

final processScanQueueProvider = FutureProvider<bool>((ref) async {
  await ref.read(scanProcessorServiceProvider).processAll();
  ref.invalidate(scanQueueProvider);
  return true;
});

/// Add to Shopping extras from a scan item (reason: Scanned)
final addScanToShoppingProvider =
    FutureProvider.family<bool, String>((ref, scanId) async {
  final queue = await ref.read(scanQueueServiceProvider).list();
  final it = queue.firstWhere((e) => e.id == scanId);
  final ingId = it.ingredientId;
  if (ingId == null) return false;

  final ingMeta = await ref.read(ingredientByIdProvider(ingId).future);
  if (ingMeta == null) return false;
  final plan = ref.read(currentPlanProvider).value;

  final qty = (it.packQty ?? 0) > 0 ? it.packQty! : 1.0;
  final unit = _unitFromString(it.packUnit) ?? ingMeta.unit;

  final item = ShortfallItem(
    ingredientId: ingMeta.id,
    name: ingMeta.name,
    missingQty: qty,
    unit: unit,
    aisle: ingMeta.aisle,
    reason: 'Scanned',
  );
  final repo = ref.read(shoppingListRepositoryProvider);
  await repo.addShortfalls([item], planId: plan?.id);

  // trigger recompute of shopping list groups
  ref.invalidate(shoppingListItemsProvider);
  return true;
});

ing.Unit? _unitFromString(String? s) {
  if (s == null) return null;
  for (final u in ing.Unit.values) {
    if (u.name == s || u.value == s) return u;
  }
  return null;
}

