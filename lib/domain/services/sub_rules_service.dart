import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final subRulesServiceProvider = Provider<SubRulesService>((_) => SubRulesService());

class SubRulesService {
  static const _k = 'sub.rules.v1'; // List<SubRule>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<SubRule>> list() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const [];
    try {
      final xs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final rules = xs.map(SubRule.fromJson).toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));
      if (kDebugMode) debugPrint('[SubRules] load ${rules.length}');
      return rules;
    } catch (e) {
      if (kDebugMode) debugPrint('[SubRules] decode failed: $e');
      return const [];
    }
  }

  Future<void> saveAll(List<SubRule> xs) async {
    final sp = await _sp();
    await sp.setString(_k, jsonEncode(xs.map((e) => e.toJson()).toList()));
    if (kDebugMode) debugPrint('[SubRules] save ${xs.length}');
  }

  Future<void> upsert(SubRule r) async {
    final xs = await list();
    final i = xs.indexWhere((x) => x.id == r.id);
    if (i >= 0) {
      xs[i] = r;
    } else {
      xs.add(r);
    }
    await saveAll(xs);
  }

  Future<void> remove(String id) async {
    final xs = await list()..removeWhere((x) => x.id == id);
    await saveAll(xs);
  }
}

enum SubAction { always, prefer, never }

class SubRule {
  final String id; // uuid
  final SubAction action; // always / prefer / never
  final Target from; // ingredientId OR tag ('tag:spicy') OR wildcard
  final Target? to; // for always/prefer; null for never
  final List<String> scopeTags; // e.g., 'mexican','veg','dinner'
  final double? maxPpuCents; // optional cost ceiling per base unit
  final int priority; // lower = earlier
  final bool enabled;

  const SubRule({
    required this.id,
    required this.action,
    required this.from,
    this.to,
    this.scopeTags = const [],
    this.maxPpuCents,
    this.priority = 100,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action.name,
        'from': from.toJson(),
        'to': to?.toJson(),
        'scopeTags': scopeTags,
        'maxPpuCents': maxPpuCents,
        'priority': priority,
        'enabled': enabled
      };
  factory SubRule.fromJson(Map<String, dynamic> j) => SubRule(
        id: j['id'],
        action: SubAction.values.firstWhere((e) => e.name == j['action'], orElse: () => SubAction.prefer),
        from: Target.fromJson((j['from'] as Map).cast<String, dynamic>()),
        to: j['to'] == null ? null : Target.fromJson((j['to'] as Map).cast<String, dynamic>()),
        scopeTags: List<String>.from(j['scopeTags'] ?? const []),
        maxPpuCents: (j['maxPpuCents'] as num?)?.toDouble(),
        priority: j['priority'] ?? 100,
        enabled: j['enabled'] ?? true,
      );

  bool appliesTo(Set<String> recipeTags) {
    if (!enabled) return false;
    if (scopeTags.isEmpty) return true;
    for (final t in scopeTags) {
      if (recipeTags.contains(t)) return true;
    }
    return false;
  }
}

class Target {
  final String kind; // 'ingredient' | 'tag' | 'any'
  final String value; // id or tag value
  const Target.ingredient(this.value)
      : kind = 'ingredient';
  const Target.tag(this.value)
      : kind = 'tag';
  const Target.any()
      : kind = 'any',
        value = '*';

  Map<String, dynamic> toJson() => {'kind': kind, 'value': value};
  factory Target.fromJson(Map<String, dynamic> j) => Target._(j['kind'], j['value']);
  const Target._(this.kind, this.value);

  bool matchesIngredient(String ingredientId, Set<String> ingredientTags) {
    switch (kind) {
      case 'ingredient':
        return value == ingredientId;
      case 'tag':
        return ingredientTags.contains(value);
      case 'any':
        return true;
      default:
        return false;
    }
  }
}

