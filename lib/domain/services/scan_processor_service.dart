import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../../presentation/providers/ingredient_providers.dart';
import '../../domain/entities/ingredient.dart' as domain;
import 'scan_queue_service.dart';
import 'sku_mapping_service.dart';
import 'price_history_service.dart';
import 'offline_center.dart';

final scanProcessorServiceProvider =
    Provider<ScanProcessorService>((ref) => ScanProcessorService(ref));

class ScanProcessorService {
  ScanProcessorService(this.ref);
  final Ref ref;

  /// Attempt to resolve all pending scans:
  /// 1) If ingredientId missing, try sku map; if still missing, leave pending.
  /// 2) If price present + pack known, push price point to PriceHistory.
  Future<void> processAll() async {
    final conn = await Connectivity().checkConnectivity();
    final online = conn != ConnectivityResult.none;

    final queueSvc = ref.read(scanQueueServiceProvider);
    final queue = await queueSvc.list();
    final skuMap = await ref.read(skuMappingServiceProvider).all();

    for (final item in queue) {
      if (item.status != ScanStatus.pending.name) continue;

      final ingId = item.ingredientId ?? skuMap[item.ean];
      if (ingId == null) {
        // unresolved mapping — wait for user
        if (kDebugMode) debugPrint('[Scan] unresolved mapping for ${item.ean}');
        continue;
      }

      // If we have price & pack & store, update Price History as PPU for this store
      final hasPriceData = item.priceCents != null && item.packQty != null && item.packQty! > 0 && item.storeId != null;
      if (hasPriceData) {
        final ppuCents = (item.priceCents! / item.packQty!).round();
        if (online) {
          // Persist locally now as source of truth
          await ref.read(priceHistoryServiceProvider).add(
                PricePoint(
                  id: const Uuid().v4(),
                  ingredientId: ingId,
                  storeId: item.storeId!,
                  ppuCents: ppuCents,
                  unit: item.packUnit ?? 'g',
                  at: DateTime.now(),
                  source: 'scan',
                ),
              );
          if (kDebugMode) {
            debugPrint('[Scan] price push ${item.ean} ppu=$ppuCents to store=${item.storeId} online=$online');
          }
        } else {
          // Enqueue for later when offline
          await ref.read(offlineCenterProvider).enqueue(
                OfflineTaskType.priceHistoryPush,
                dedupeKey: 'price:$ingId:${item.storeId}:${DateTime.now().millisecondsSinceEpoch}',
                payload: {
                  'ingredientId': ingId,
                  'storeId': item.storeId!,
                  'ppuCents': ppuCents,
                  'unit': item.packUnit ?? 'g',
                  'atIso': DateTime.now().toIso8601String(),
                  'source': 'scan',
                },
              );
          if (kDebugMode) {
            debugPrint('[Scan] queued price push ${item.ean} ppu=$ppuCents to store=${item.storeId}');
          }
        }
      }

      // Mark resolved if it has mapping; keep note
      await queueSvc.upsert(
        item.copyWith(
          ingredientId: ingId,
          status: ScanStatus.resolved,
          note: item.ingredientId == null ? 'Linked via map' : item.note,
        ),
      );
    }
  }
}
