import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final batchSessionServiceProvider = Provider<BatchSessionService>((_) => BatchSessionService());

class BatchSessionService {
  static const _k = 'batch.sessions.v1'; // Map<sessionId, BatchSessionJson>
  static const _tag = '[Batch]';

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<BatchSession>> list() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const [];
    final m = (jsonDecode(raw) as Map).cast<String, Map<String, dynamic>>();
    final xs = m.values.map(BatchSession.fromJson).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (kDebugMode) debugPrint('$_tag session list: ${xs.length}');
    return xs;
  }

  Future<BatchSession?> byId(String id) async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return null;
    final m = (jsonDecode(raw) as Map).cast<String, Map<String, dynamic>>();
    final j = m[id];
    return j == null ? null : BatchSession.fromJson(j);
  }

  Future<void> upsert(BatchSession s) async {
    final sp = await _sp();
    final raw = sp.getString(_k);
    final m = raw == null
        ? <String, Map<String, dynamic>>{}
        : (jsonDecode(raw) as Map).cast<String, Map<String, dynamic>>();
    m[s.id] = s.toJson();
    await sp.setString(_k, jsonEncode(m));
    if (kDebugMode) debugPrint('$_tag upsert ${s.id}');
  }

  Future<void> remove(String id) async {
    final sp = await _sp();
    final raw = sp.getString(_k);
    if (raw == null) return;
    final m = (jsonDecode(raw) as Map).cast<String, Map<String, dynamic>>();
    m.remove(id);
    await sp.setString(_k, jsonEncode(m));
    if (kDebugMode) debugPrint('$_tag remove $id');
  }
}

class BatchSession {
  final String id; // uuid
  final String name; // e.g., "Sunday Meal Prep"
  final DateTime createdAt;
  final DateTime cookDate; // planned cook date
  final List<BatchItem> items; // recipes to cook
  final bool shoppingGenerated; // flag for UX
  final bool started; // Cook checklist started
  final bool finished; // Finalized (portions created)
  final String? note; // session note
  const BatchSession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.cookDate,
    required this.items,
    this.shoppingGenerated = false,
    this.started = false,
    this.finished = false,
    this.note,
  });

  BatchSession copyWith({
    String? name,
    DateTime? cookDate,
    List<BatchItem>? items,
    bool? shoppingGenerated,
    bool? started,
    bool? finished,
    String? note,
  }) =>
      BatchSession(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        cookDate: cookDate ?? this.cookDate,
        items: items ?? this.items,
        shoppingGenerated: shoppingGenerated ?? this.shoppingGenerated,
        started: started ?? this.started,
        finished: finished ?? this.finished,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'cookDate': cookDate.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'shoppingGenerated': shoppingGenerated,
        'started': started,
        'finished': finished,
        'note': note,
      };
  factory BatchSession.fromJson(Map<String, dynamic> j) => BatchSession(
        id: j['id'],
        name: j['name'],
        createdAt: DateTime.parse(j['createdAt']),
        cookDate: DateTime.parse(j['cookDate']),
        items: (j['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(BatchItem.fromJson)
            .toList(),
        shoppingGenerated: j['shoppingGenerated'] ?? false,
        started: j['started'] ?? false,
        finished: j['finished'] ?? false,
        note: j['note'],
      );
}

class BatchItem {
  final String recipeId;
  final int targetServings; // how many servings to cook
  final int portions; // how many portion containers to create
  final String? labelNote; // e.g., “No onions for Alex”
  final BatchProgress progress; // checklist progress
  const BatchItem({
    required this.recipeId,
    required this.targetServings,
    required this.portions,
    this.labelNote,
    this.progress = const BatchProgress(),
  });

  BatchItem copyWith({
    int? targetServings,
    int? portions,
    String? labelNote,
    BatchProgress? progress,
  }) =>
      BatchItem(
        recipeId: recipeId,
        targetServings: targetServings ?? this.targetServings,
        portions: portions ?? this.portions,
        labelNote: labelNote ?? this.labelNote,
        progress: progress ?? this.progress,
      );

  Map<String, dynamic> toJson() => {
        'recipeId': recipeId,
        'targetServings': targetServings,
        'portions': portions,
        'labelNote': labelNote,
        'progress': progress.toJson(),
      };
  factory BatchItem.fromJson(Map<String, dynamic> j) => BatchItem(
        recipeId: j['recipeId'],
        targetServings: j['targetServings'],
        portions: j['portions'],
        labelNote: j['labelNote'],
        progress: BatchProgress.fromJson((j['progress'] as Map).cast<String, dynamic>()),
      );
}

class BatchProgress {
  final bool prepped;
  final bool cooked;
  final bool portioned;
  final String? note;
  const BatchProgress({this.prepped = false, this.cooked = false, this.portioned = false, this.note});

  BatchProgress copyWith({bool? prepped, bool? cooked, bool? portioned, String? note}) => BatchProgress(
        prepped: prepped ?? this.prepped,
        cooked: cooked ?? this.cooked,
        portioned: portioned ?? this.portioned,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {'prepped': prepped, 'cooked': cooked, 'portioned': portioned, 'note': note};
  factory BatchProgress.fromJson(Map<String, dynamic> j) => BatchProgress(
        prepped: j['prepped'] ?? false,
        cooked: j['cooked'] ?? false,
        portioned: j['portioned'] ?? false,
        note: j['note'],
      );
}

