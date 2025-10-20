import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'price_history_service.dart';
import '../../presentation/providers/database_providers.dart';
import 'feedback_uploader.dart';

final offlineCenterProvider = Provider<OfflineCenter>((ref) => OfflineCenter(ref));
final offlineTasksProvider = FutureProvider<List<OfflineTask>>((ref) async => ref.read(offlineCenterProvider).list());
final connectivityStatusProvider = StreamProvider<ConnectivityState>((ref) => OfflineCenter.connectivityStream());

enum OfflineTaskType { priceHistoryPush, feedbackUpload, templatePublish, cloudDeltaPush }
enum OfflineTaskStatus { pending, running, done, failed, cancelled }

class OfflineTask {
  final String id; // uuid
  final OfflineTaskType type;
  final String dedupeKey; // idem key (e.g., "price:ingId:storeId:ts")
  final Map<String, dynamic> payload; // minimal info to execute
  final OfflineTaskStatus status;
  final int attempt; // number of attempts
  final DateTime nextAt; // not before (backoff)
  final String? lastError; // truncated
  final DateTime createdAt;
  final DateTime updatedAt;

  const OfflineTask({
    required this.id,
    required this.type,
    required this.dedupeKey,
    required this.payload,
    this.status = OfflineTaskStatus.pending,
    this.attempt = 0,
    DateTime? nextAt,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : nextAt = nextAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        lastError = lastError,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  OfflineTask copyWith({
    OfflineTaskStatus? status,
    int? attempt,
    DateTime? nextAt,
    String? lastError,
  }) =>
      OfflineTask(
        id: id,
        type: type,
        dedupeKey: dedupeKey,
        payload: payload,
        status: status ?? this.status,
        attempt: attempt ?? this.attempt,
        nextAt: nextAt ?? this.nextAt,
        lastError: lastError ?? this.lastError,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'dedupeKey': dedupeKey,
        'payload': payload,
        'status': status.name,
        'attempt': attempt,
        'nextAt': nextAt.toIso8601String(),
        'lastError': lastError,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory OfflineTask.fromJson(Map<String, dynamic> j) => OfflineTask(
        id: j['id'] as String,
        type: OfflineTaskType.values.firstWhere((e) => e.name == j['type'] as String),
        dedupeKey: j['dedupeKey'] as String,
        payload: (j['payload'] as Map).cast<String, dynamic>(),
        status: OfflineTaskStatus.values.firstWhere((e) => e.name == j['status'] as String),
        attempt: (j['attempt'] ?? 0 as int).toInt(),
        nextAt: DateTime.tryParse((j['nextAt'] ?? '') as String) ?? DateTime.fromMillisecondsSinceEpoch(0),
        lastError: j['lastError'] as String?,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '') as String),
        updatedAt: DateTime.tryParse((j['updatedAt'] ?? '') as String),
      );
}

class OfflineCenter {
  OfflineCenter(this.ref);
  final Ref ref;
  static const _k = 'offline.tasks.v1'; // List<OfflineTask>
  static const _maxTasks = 500;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  // ---- PUBLIC API
  Future<List<OfflineTask>> list() async => _load();

  Future<void> enqueue(OfflineTaskType type, {required String dedupeKey, required Map<String, dynamic> payload}) async {
    final xs = await _load();
    final i = xs.indexWhere((t) => t.dedupeKey == dedupeKey && t.status != OfflineTaskStatus.done && t.status != OfflineTaskStatus.cancelled);
    if (i >= 0) return; // deduped
    xs.add(OfflineTask(id: const Uuid().v4(), type: type, dedupeKey: dedupeKey, payload: payload));
    await _save(_trim(xs));
  }

  Future<void> remove(String id) async {
    final xs = await _load()..removeWhere((t) => t.id == id);
    await _save(xs);
  }

  Future<void> clearDone() async {
    final xs = await _load()..removeWhere((t) => t.status == OfflineTaskStatus.done || t.status == OfflineTaskStatus.cancelled);
    await _save(xs);
  }

  Future<void> retryNow(String id) async {
    final xs = await _load();
    final i = xs.indexWhere((t) => t.id == id);
    if (i < 0) return;
    xs[i] = xs[i].copyWith(nextAt: DateTime.fromMillisecondsSinceEpoch(0), status: OfflineTaskStatus.pending);
    await _save(xs);
  }

  Future<void> processEligible({required bool online}) async {
    if (!online) return;
    final xs = await _load();
    final now = DateTime.now();
    bool changed = false;
    for (int i = 0; i < xs.length; i++) {
      final t = xs[i];
      if (t.status != OfflineTaskStatus.pending) continue;
      if (t.nextAt.isAfter(now)) continue;
      final running = t.copyWith(status: OfflineTaskStatus.running);
      xs[i] = running;
      changed = true;
      await _save(xs);

      try {
        await _execute(running);
        xs[i] = running.copyWith(status: OfflineTaskStatus.done, lastError: null);
      } catch (e) {
        if (kDebugMode) debugPrint('[Offline] ${t.type} failed: $e');
        final backoffSec = _backoffSeconds(running.attempt + 1);
        xs[i] = running.copyWith(
          status: OfflineTaskStatus.pending,
          attempt: running.attempt + 1,
          nextAt: now.add(Duration(seconds: backoffSec)),
          lastError: _truncate('$e'),
        );
      }
      changed = true;
      await _save(xs);
    }
    if (changed) {
      // no-op
    }
  }

  // ---- EXECUTION (ADAPTERS)
  Future<void> _execute(OfflineTask t) async {
    switch (t.type) {
      case OfflineTaskType.priceHistoryPush:
        // payload: {ingredientId, storeId, ppuCents, atIso, source, unit?}
        await ref.read(priceHistoryServiceProvider).add(
              PricePoint(
                id: t.payload['id'] ?? const Uuid().v4(),
                ingredientId: t.payload['ingredientId'] as String,
                storeId: t.payload['storeId'] as String,
                ppuCents: (t.payload['ppuCents'] as num).toInt(),
                unit: (t.payload['unit'] as String?) ?? 'g',
                at: DateTime.parse(t.payload['atIso'] as String),
                source: (t.payload['source'] as String?) ?? 'offline',
              ),
            );
        return;
      case OfflineTaskType.feedbackUpload:
        // payload: {path, manifest{...}}
        await ref.read(feedbackUploaderProvider).uploadZip(
              feedbackId: t.payload['manifest']['id'] as String,
              manifest: (t.payload['manifest'] as Map).cast<String, dynamic>(),
              zip: File(t.payload['path'] as String),
            );
        return;
      case OfflineTaskType.templatePublish:
        throw UnsupportedError('templatePublish not implemented');
      case OfflineTaskType.cloudDeltaPush:
        throw UnsupportedError('cloudDeltaPush not implemented');
    }
  }

  // ---- STORAGE
  Future<List<OfflineTask>> _load() async {
    final raw = _prefs.getString(_k);
    if (raw == null) return const [];
    final xs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>().map(OfflineTask.fromJson).toList();
    return xs;
  }

  Future<void> _save(List<OfflineTask> xs) async {
    await _prefs.setString(_k, jsonEncode(xs.map((e) => e.toJson()).toList()));
  }

  List<OfflineTask> _trim(List<OfflineTask> xs) {
    if (xs.length <= _maxTasks) return xs;
    xs.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // oldest first
    return xs.sublist(xs.length - _maxTasks);
  }

  static int _backoffSeconds(int attempt) {
    // exponential backoff with jitter: min(2^attempt * 2, 300) +/- 20%
    final base = min(pow(2, attempt).toInt() * 2, 300);
    final jitter = (base * (0.2 * (Random().nextDouble() - 0.5))).round();
    return max(2, base + jitter);
  }

  static Stream<ConnectivityState> connectivityStream() async* {
    final conn = Connectivity();
    ConnectivityResult last = await conn.checkConnectivity();
    yield ConnectivityState(last != ConnectivityResult.none);
    await for (final r in conn.onConnectivityChanged) {
      yield ConnectivityState(r != ConnectivityResult.none);
    }
  }

  static String _truncate(String s) => s.length > 200 ? (s.substring(0, 200) + '…') : s;
}

class ConnectivityState {
  final bool online;
  const ConnectivityState(this.online);
}

