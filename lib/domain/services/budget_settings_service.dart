import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final budgetSettingsServiceProvider = Provider<BudgetSettingsService>((_) => BudgetSettingsService());

class BudgetSettingsService {
  static const _k = 'budget.settings.v2';
  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<BudgetSettings> get() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const BudgetSettings();
    return BudgetSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(BudgetSettings s) async {
    final sp = await _sp();
    await sp.setString(_k, jsonEncode(s.toJson()));
  }
}

class BudgetSettings {
  final int weeklyBudgetCents;        // default 8000 ($80)
  final bool showNudges;              // default true
  final bool autoCheapMode;           // default false (allows optimizer to suggest on gen)
  final double kcalTolerancePct;      // default 5%
  final double proteinTolerancePct;   // default 5%
  final int maxAutoSwaps;             // default 2
  final String? preferredStoreId;     // optional “primary” store context
  const BudgetSettings({
    this.weeklyBudgetCents = 8000,
    this.showNudges = true,
    this.autoCheapMode = false,
    this.kcalTolerancePct = 5.0,
    this.proteinTolerancePct = 5.0,
    this.maxAutoSwaps = 2,
    this.preferredStoreId,
  });

  BudgetSettings copyWith({
    int? weeklyBudgetCents,
    bool? showNudges,
    bool? autoCheapMode,
    double? kcalTolerancePct,
    double? proteinTolerancePct,
    int? maxAutoSwaps,
    String? preferredStoreId,
  }) => BudgetSettings(
    weeklyBudgetCents: weeklyBudgetCents ?? this.weeklyBudgetCents,
    showNudges: showNudges ?? this.showNudges,
    autoCheapMode: autoCheapMode ?? this.autoCheapMode,
    kcalTolerancePct: kcalTolerancePct ?? this.kcalTolerancePct,
    proteinTolerancePct: proteinTolerancePct ?? this.proteinTolerancePct,
    maxAutoSwaps: maxAutoSwaps ?? this.maxAutoSwaps,
    preferredStoreId: preferredStoreId ?? this.preferredStoreId,
  );

  Map<String, dynamic> toJson() => {
    'weeklyBudgetCents': weeklyBudgetCents,
    'showNudges': showNudges,
    'autoCheapMode': autoCheapMode,
    'kcalTolerancePct': kcalTolerancePct,
    'proteinTolerancePct': proteinTolerancePct,
    'maxAutoSwaps': maxAutoSwaps,
    'preferredStoreId': preferredStoreId,
  };
  factory BudgetSettings.fromJson(Map<String,dynamic> j) => BudgetSettings(
    weeklyBudgetCents: j['weeklyBudgetCents'] ?? 8000,
    showNudges: j['showNudges'] ?? true,
    autoCheapMode: j['autoCheapMode'] ?? false,
    kcalTolerancePct: (j['kcalTolerancePct'] ?? 5.0).toDouble(),
    proteinTolerancePct: (j['proteinTolerancePct'] ?? 5.0).toDouble(),
    maxAutoSwaps: j['maxAutoSwaps'] ?? 2,
    preferredStoreId: j['preferredStoreId'],
  );
}

