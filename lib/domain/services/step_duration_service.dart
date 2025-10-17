import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final stepDurationServiceProvider = Provider<StepDurationService>((_) => StepDurationService());

class StepDurationService {
  static const _k = 'cook.stepDurations.v1'; // Map<recipeId, Map<stepIndex, seconds>>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<Map<int, int>> getForRecipe(String recipeId) async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return {};
    final root = (jsonDecode(raw) as Map).cast<String, dynamic>();
    final m = (root[recipeId] as Map?)?.cast<String, dynamic>() ?? {};
    return m.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
  }

  Future<void> upsert(String recipeId, int stepIndex, int seconds) async {
    final sp = await _sp();
    final raw = sp.getString(_k);
    final root = raw == null
        ? <String, Map<String, int>>{}
        : (jsonDecode(raw) as Map)
            .map((k, v) => MapEntry(k as String, (v as Map).cast<String, int>()));
    final m = root[recipeId] ?? <String, int>{};
    m['$stepIndex'] = seconds;
    root[recipeId] = m;
    await sp.setString(_k, jsonEncode(root));
  }
}

