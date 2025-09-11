import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user_targets.dart' as domain;
import '../../domain/repositories/user_targets_repository.dart';
import '../datasources/database.dart';

/// Concrete implementation of UserTargetsRepository using Drift + SharedPreferences.
/// - Stores presets in the `UserTargets` table (Drift).
/// - Stores current active preset id and onboarding flag in SharedPreferences.
/// - Exposes reactive streams for current + all targets.
class UserTargetsRepositoryImpl implements UserTargetsRepository {
  UserTargetsRepositoryImpl(this._db, this._prefs) {
    // Re-emit current on any table changes.
    _allSub = _db.select(_db.userTargets).watch().listen((_) {
      _emitCurrent();
    });
    // Initial emission.
    _emitCurrent();
  }

  final AppDatabase _db;
  final SharedPreferences _prefs;

  // Keys in SharedPreferences
  static const _kCurrentTargetsId = 'current_user_targets_id_v1';
  static const _kOnboardingCompleted = 'onboarding_completed_v1';

  // Current stream controller
  final _currentCtrl = StreamController<domain.UserTargets?>.broadcast();
  StreamSubscription<List<UserTarget>>? _allSub;

  // ------------ Mapping helpers ------------
  domain.UserTargets _toDomain(UserTarget row) {
    return domain.UserTargets(
      id: row.id,
      kcal: row.kcal,
      proteinG: row.proteinG,
      carbsG: row.carbsG,
      fatG: row.fatG,
      budgetCents: row.budgetCents,
      mealsPerDay: row.mealsPerDay,
      timeCapMins: row.timeCapMins,
      dietFlags: _decodeList(row.dietFlags),
      equipment: _decodeList(row.equipment),
      planningMode: _modeFromString(row.planningMode),
    );
  }

  UserTargetsCompanion _toCompanion(domain.UserTargets e, {bool isUpdate = false}) {
    final now = DateTime.now();
    return UserTargetsCompanion(
      id: drift.Value(e.id),
      kcal: drift.Value(e.kcal),
      proteinG: drift.Value(e.proteinG),
      carbsG: drift.Value(e.carbsG),
      fatG: drift.Value(e.fatG),
      budgetCents: drift.Value(e.budgetCents),
      mealsPerDay: drift.Value(e.mealsPerDay),
      timeCapMins: drift.Value(e.timeCapMins),
      dietFlags: drift.Value(_encodeList(e.dietFlags)),
      equipment: drift.Value(_encodeList(e.equipment)),
      planningMode: drift.Value(_modeToString(e.planningMode)),
      // createdAt has default on insert; we still set defensively
      createdAt: isUpdate ? const drift.Value.absent() : drift.Value(now),
      updatedAt: drift.Value(now),
    );
  }

  static String _encodeList(List<String> v) => jsonEncode(v);
  static List<String> _decodeList(String v) {
    try {
      final raw = jsonDecode(v);
      if (raw is List) return raw.map((e) => e.toString()).toList();
    } catch (_) {}
    // Backwards compat if old data used comma-separated
    return v.split(',').where((s) => s.isNotEmpty).toList();
  }

  static String _modeToString(domain.PlanningMode m) => m.value;
  static domain.PlanningMode _modeFromString(String s) {
    for (final m in domain.PlanningMode.values) {
      if (m.value == s) return m;
    }
    // Fallback
    return domain.PlanningMode.maintenance;
  }

  Future<void> _emitCurrent() async {
    final current = await getCurrentUserTargets();
    if (!_currentCtrl.isClosed) {
      _currentCtrl.add(current);
    }
  }

  Future<domain.UserTargets?> _selectById(String id) async {
    final q = _db.select(_db.userTargets)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<domain.UserTargets>> _selectAll() async {
    final rows = await _db.select(_db.userTargets).get();
    return rows.map(_toDomain).toList();
  }

  // ------------ Interface implementation ------------

  @override
  Future<domain.UserTargets?> getCurrentUserTargets() async {
    final id = _prefs.getString(_kCurrentTargetsId);
    if (id != null) {
      final existing = await _selectById(id);
      if (existing != null) return existing;
    }
    // No current set: if there is exactly one preset, make it current.
    final all = await _selectAll();
    if (all.isNotEmpty) {
      // Choose the first as current to keep UX moving
      await setCurrentTargets(all.first.id);
      return all.first;
    }
    return null;
  }

  @override
  Future<domain.UserTargets?> getUserTargetsById(String id) => _selectById(id);

  @override
  Future<List<domain.UserTargets>> getAllUserTargets() => _selectAll();

  @override
  Future<void> saveUserTargets(domain.UserTargets targets) async {
    await _db.into(_db.userTargets).insertOnConflictUpdate(_toCompanion(targets));
    // If no current is set, make this one current.
    _prefs.getString(_kCurrentTargetsId) ?? await setCurrentTargets(targets.id);
    await _emitCurrent();
  }

  @override
  Future<void> updateUserTargets(domain.UserTargets targets) async {
    final comp = _toCompanion(targets, isUpdate: true);
    await (_db.update(_db.userTargets)..where((t) => t.id.equals(targets.id))).write(comp);
    await _emitCurrent();
  }

  @override
  Future<void> deleteUserTargets(String id) async {
    await (_db.delete(_db.userTargets)..where((t) => t.id.equals(id))).go();
    // If deleting current, move current to another preset or clear
    final currentId = _prefs.getString(_kCurrentTargetsId);
    if (currentId == id) {
      final remaining = await _selectAll();
      if (remaining.isNotEmpty) {
        await setCurrentTargets(remaining.first.id);
      } else {
        await _prefs.remove(_kCurrentTargetsId);
      }
    }
    await _emitCurrent();
  }

  @override
  Future<void> setCurrentTargets(String id) async {
    // Ensure the id exists
    final exists = await _selectById(id);
    if (exists == null) {
      throw StateError('Cannot set current targets: id "$id" does not exist.');
    }
    await _prefs.setString(_kCurrentTargetsId, id);
    await _emitCurrent();
  }

  @override
  Future<domain.UserTargets> getDefaultTargets() async {
    return domain.UserTargets.defaultTargets();
  }

  @override
  Future<domain.UserTargets> createCuttingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  }) async {
    final preset = domain.UserTargets.cuttingPreset(
      bodyWeightLbs: bodyWeightLbs,
      budgetCents: budgetCents,
    );
    await saveUserTargets(preset);
    await setCurrentTargets(preset.id);
    return preset;
  }

  @override
  Future<domain.UserTargets> createBulkingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  }) async {
    final preset = domain.UserTargets.bulkingPreset(
      bodyWeightLbs: bodyWeightLbs,
      budgetCents: budgetCents,
    );
    await saveUserTargets(preset);
    await setCurrentTargets(preset.id);
    return preset;
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    return _prefs.getBool(_kOnboardingCompleted) ?? false;
  }

  @override
  Future<void> markOnboardingCompleted() async {
    await _prefs.setBool(_kOnboardingCompleted, true);
  }

  @override
  Future<int> getTargetsCount() async {
    final q = _db.selectOnly(_db.userTargets)..addColumns([_db.userTargets.id.count()]);
    final row = await q.getSingle();
    final countExpr = row.read(_db.userTargets.id.count());
    return countExpr ?? 0;
  }

  @override
  Stream<domain.UserTargets?> watchCurrentUserTargets() => _currentCtrl.stream;

  @override
  Stream<List<domain.UserTargets>> watchAllUserTargets() {
    return _db.select(_db.userTargets).watch().map(
          (rows) => rows.map(_toDomain).toList(),
        );
  }

  // Call when disposing the repo (optional; if you wire as app-scoped singletons, app exit cleans up).
  void dispose() {
    _allSub?.cancel();
    _currentCtrl.close();
  }
}
