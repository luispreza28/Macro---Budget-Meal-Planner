import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final multiweekSeriesServiceProvider = Provider<MultiweekSeriesService>((_) => MultiweekSeriesService());

class MultiweekSeriesService {
  static const _k = 'multiweek.series.v1'; // Map<seriesId, SeriesJson>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<MultiweekSeries>> list() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const [];
    final m = (jsonDecode(raw) as Map).cast<String, Map<String, dynamic>>();
    final xs = m.values.map(MultiweekSeries.fromJson).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return xs;
  }

  Future<MultiweekSeries?> byId(String id) async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return null;
    final m = (jsonDecode(raw) as Map).cast<String, Map<String, dynamic>>();
    final j = m[id];
    return j == null ? null : MultiweekSeries.fromJson(j);
  }

  Future<void> upsert(MultiweekSeries s) async {
    final sp = await _sp();
    final raw = sp.getString(_k);
    final m = raw == null
        ? <String, Map<String, dynamic>>{}
        : (jsonDecode(raw) as Map).cast<String, Map<String, dynamic>>();
    m[s.id] = s.toJson();
    await sp.setString(_k, jsonEncode(m));
  }

  Future<void> remove(String id) async {
    final sp = await _sp();
    final raw = sp.getString(_k);
    if (raw == null) return;
    final m = (jsonDecode(raw) as Map).cast<String, Map<String, dynamic>>();
    m.remove(id);
    await sp.setString(_k, jsonEncode(m));
  }
}

class MultiweekSeries {
  final String id; // uuid
  final String name; // e.g., "Oct Meal Plan"
  final DateTime createdAt;
  final DateTime week0Start; // local date 00:00 (Mon or your anchor)
  final int weeks; // 2..4
  final List<String> planIds; // length == weeks, each is an existing Plan.id
  const MultiweekSeries({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.week0Start,
    required this.weeks,
    required this.planIds,
  });

  MultiweekSeries copyWith({String? name, List<String>? planIds}) => MultiweekSeries(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        week0Start: week0Start,
        weeks: weeks,
        planIds: planIds ?? this.planIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'week0Start': week0Start.toIso8601String(),
        'weeks': weeks,
        'planIds': planIds,
      };
  factory MultiweekSeries.fromJson(Map<String, dynamic> j) => MultiweekSeries(
        id: j['id'],
        name: j['name'],
        createdAt: DateTime.parse(j['createdAt']),
        week0Start: DateTime.parse(j['week0Start']),
        weeks: j['weeks'],
        planIds: List<String>.from(j['planIds'] ?? const []),
      );
}

