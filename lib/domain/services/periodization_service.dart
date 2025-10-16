import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final periodizationServiceProvider =
    Provider<PeriodizationService>((_) => PeriodizationService());

class PeriodizationService {
  static const _k = 'periodization.phases.v1'; // List<Phase>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<Phase>> list() async {
    try {
      final raw = (await _sp()).getString(_k);
      if (raw == null) return const [];
      final xs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final list = xs.map(Phase.fromJson).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      if (kDebugMode) {
        debugPrint('[Periodization] list -> ${list.length} phases');
      }
      return list;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Periodization] list error: $e');
      }
      return const [];
    }
  }

  Future<void> saveAll(List<Phase> xs) async {
    final sp = await _sp();
    await sp.setString(_k, jsonEncode(xs.map((e) => e.toJson()).toList()));
    if (kDebugMode) {
      debugPrint('[Periodization] saveAll -> ${xs.length}');
    }
  }

  Future<void> upsert(Phase p) async {
    final xs = await list();
    final i = xs.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      xs[i] = p;
    } else {
      xs.add(p);
    }
    await saveAll(xs);
  }

  Future<void> remove(String id) async {
    final xs = await list()..removeWhere((x) => x.id == id);
    await saveAll(xs);
  }
}

class Phase {
  final String id; // uuid
  final PhaseType type;
  final DateTime start; // inclusive local date 00:00
  final DateTime end; // inclusive local date 23:59
  final String? note;
  const Phase({
    required this.id,
    required this.type,
    required this.start,
    required this.end,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'note': note,
      };
  factory Phase.fromJson(Map<String, dynamic> j) => Phase(
        id: j['id'],
        type: PhaseType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => PhaseType.maintain,
        ),
        start: DateTime.parse(j['start']),
        end: DateTime.parse(j['end']),
        note: j['note'],
      );

  bool contains(DateTime d) {
    final dd = DateTime(d.year, d.month, d.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return dd.isAfter(s.subtract(const Duration(seconds: 1))) &&
        dd.isBefore(e.add(const Duration(seconds: 1)));
  }
}

enum PhaseType { cut, maintain, bulk }

