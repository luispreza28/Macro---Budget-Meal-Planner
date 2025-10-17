import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final planTemplatesServiceProvider = Provider<PlanTemplatesService>((_) => PlanTemplatesService());

class PlanTemplatesService {
  static const _k = 'plan.templates.v1'; // List<TemplateJson>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<PlanTemplate>> list() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const [];
    final xs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return xs.map(PlanTemplate.fromJson).toList();
  }

  Future<void> saveAll(List<PlanTemplate> xs) async {
    final sp = await _sp();
    await sp.setString(_k, jsonEncode(xs.map((e) => e.toJson()).toList()));
  }

  Future<void> upsert(PlanTemplate t) async {
    final xs = await list();
    final i = xs.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      xs[i] = t;
    } else {
      xs.add(t);
    }
    await saveAll(xs);
  }

  Future<void> remove(String id) async {
    final xs = await list()..removeWhere((x) => x.id == id);
    await saveAll(xs);
  }
}

class PlanTemplate {
  final String id; // uuid
  final String name;
  final String? coverEmoji; // simple cover
  final List<String> tags; // e.g., "bulk","veg","budget"
  final String? notes;
  final DateTime createdAt;
  final int days; // 7..14
  final Map<String, dynamic> payload; // normalized template payload (see exporter)
  const PlanTemplate({
    required this.id,
    required this.name,
    this.coverEmoji,
    this.tags = const [],
    this.notes,
    required this.createdAt,
    required this.days,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'coverEmoji': coverEmoji,
        'tags': tags,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'days': days,
        'payload': payload,
      };
  factory PlanTemplate.fromJson(Map<String, dynamic> j) => PlanTemplate(
        id: j['id'],
        name: j['name'],
        coverEmoji: j['coverEmoji'],
        tags: List<String>.from(j['tags'] ?? const []),
        notes: j['notes'],
        createdAt: DateTime.parse(j['createdAt']),
        days: (j['days'] ?? 7).toInt(),
        payload: (j['payload'] as Map).cast<String, dynamic>(),
      );
}

