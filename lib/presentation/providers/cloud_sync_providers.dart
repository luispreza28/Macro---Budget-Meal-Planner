import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/sync/auth_service.dart';
import '../../domain/sync/snapshot_service.dart';
import '../../domain/sync/restore_service.dart';
import '../../domain/sync/snapshot_models.dart';
import '../providers/plan_providers.dart';

final backupNowProvider = FutureProvider<SnapshotManifest?>((ref) async {
  final uid = ref.read(authServiceProvider).uid();
  if (uid == null) return null;
  try {
    final snap = await ref.read(snapshotServiceProvider).buildSnapshot();
    final manifest = await ref.read(snapshotServiceProvider).uploadSnapshot(snap, uid: uid);
    final sp = await SharedPreferences.getInstance();
    await sp.setString('cloud.lastBackupAt', DateTime.now().toIso8601String());
    if (kDebugMode) {
      debugPrint('[Cloud][backup] complete: ${manifest.records} records');
    }
    return manifest;
  } catch (e) {
    if (kDebugMode) debugPrint('[Cloud][backup] failed: $e');
    return null;
  }
});

final listBackupsProvider = FutureProvider<List<SnapshotManifest>>((ref) async {
  final uid = ref.read(authServiceProvider).uid();
  if (uid == null) return const [];
  return ref.read(snapshotServiceProvider).listManifests(uid);
});

final restoreFromManifestProvider =
    FutureProvider.family<bool, String>((ref, manifestId) async {
  final uid = ref.read(authServiceProvider).uid();
  if (uid == null) return false;
  try {
    final snap = await ref
        .read(snapshotServiceProvider)
        .downloadSnapshot(uid: uid, manifestId: manifestId);
    await ref.read(restoreServiceProvider).apply(snap);
    return true;
  } catch (e) {
    if (kDebugMode) debugPrint('[Cloud][restore] failed: $e');
    return false;
  }
});

// Auto-backup preferences
final cloudAutoDailyProvider = FutureProvider<bool>((ref) async {
  final sp = await SharedPreferences.getInstance();
  return sp.getBool('cloud.auto.daily') ?? true;
});

final cloudAutoOnPlanSaveProvider = FutureProvider<bool>((ref) async {
  final sp = await SharedPreferences.getInstance();
  return sp.getBool('cloud.auto.onPlanSave') ?? true;
});

// Listener that triggers a backup when a new latest plan appears
final autoBackupOnLatestPlanProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<dynamic>>>(allPlansProvider, (prev, next) async {
    final uid = ref.read(authServiceProvider).uid();
    if (uid == null) return;
    final enable = await ref.read(cloudAutoOnPlanSaveProvider.future);
    if (!enable) return;
    final prevLen = prev?.maybeWhen(data: (d) => (d as List).length, orElse: () => null);
    final nextLen = next.maybeWhen(data: (d) => (d as List).length, orElse: () => null);
    if (prevLen != null && nextLen != null && nextLen > prevLen) {
      // Best-effort enqueue when a new plan was added
      // ignore: unawaited_futures
      ref.read(backupNowProvider.future);
    }
  });
});
