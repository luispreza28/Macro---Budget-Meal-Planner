import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user_targets.dart';
import '../../domain/repositories/user_targets_repository.dart';

/// Keys for SharedPreferences
const _kAllTargetsKey = 'user_targets_all_json'; // List<UserTargets> as JSON
const _kCurrentTargetsIdKey = 'user_targets_current_id';
const _kOnboardingDoneKey = 'onboarding_completed';

/// Lightweight local repository for UserTargets using SharedPreferences.
class UserTargetsLocalRepository implements UserTargetsRepository {
  UserTargetsLocalRepository(this._prefs) {
    _allTargets = _readAllFromPrefs();
    _currentId = _prefs.getString(_kCurrentTargetsIdKey);
    if (_currentId != null && _currentId!.isEmpty) {
      _currentId = null; // normalize empty string to null
    }
    _emit();
  }

  final SharedPreferences _prefs;

  // In-memory cache
  List<UserTargets> _allTargets = const [];
  String? _currentId;

  // Broadcast streams
  final _allCtrl = StreamController<List<UserTargets>>.broadcast();
  final _currentCtrl = StreamController<UserTargets?>.broadcast();

  // ----------------- Helpers -----------------

  List<UserTargets> _readAllFromPrefs() {
    final jsonStr = _prefs.getString(_kAllTargetsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final raw = json.decode(jsonStr) as List<dynamic>;
      return raw
          .cast<Map<String, dynamic>>()
          .map(UserTargets.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeAllToPrefs(List<UserTargets> targets) async {
    final encoded = json.encode(targets.map((t) => t.toJson()).toList());
    await _prefs.setString(_kAllTargetsKey, encoded);
  }

  UserTargets? _computeCurrent() {
    if (_allTargets.isEmpty) return null;
    if (_currentId == null || _currentId!.isEmpty) return null;
    try {
      return _allTargets.firstWhere((t) => t.id == _currentId);
    } catch (_) {
      // If the stored id no longer exists, treat as no current target.
      return null;
    }
  }

  void _emit() {
    _allCtrl.add(List.unmodifiable(_allTargets));
    _currentCtrl.add(_computeCurrent());
  }

  Future<void> _persistAndEmit() async {
    await _writeAllToPrefs(_allTargets);
    if (_currentId == null || _currentId!.isEmpty) {
      await _prefs.remove(_kCurrentTargetsIdKey);
    } else {
      await _prefs.setString(_kCurrentTargetsIdKey, _currentId!);
    }
    _emit();
  }

  // ----------------- Repository API -----------------

  @override
  Future<UserTargets?> getCurrentUserTargets() async => _computeCurrent();

  @override
  Future<UserTargets?> getUserTargetsById(String id) async {
    try {
      return _allTargets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<UserTargets>> getAllUserTargets() async =>
      List.unmodifiable(_allTargets);

  @override
  Future<void> saveUserTargets(UserTargets targets) async {
    final idx = _allTargets.indexWhere((t) => t.id == targets.id);
    if (idx >= 0) {
      _allTargets[idx] = targets;
    } else {
      _allTargets = [..._allTargets, targets];
    }
    _currentId ??= targets.id; // first saved becomes current by default
    await _persistAndEmit();
  }

  @override
  Future<void> updateUserTargets(UserTargets targets) async {
    final idx = _allTargets.indexWhere((t) => t.id == targets.id);
    if (idx >= 0) {
      _allTargets[idx] = targets;
      await _persistAndEmit();
    } else {
      await saveUserTargets(targets);
    }
  }

  @override
  Future<void> deleteUserTargets(String id) async {
    _allTargets = _allTargets.where((t) => t.id != id).toList();
    if (_currentId == id) {
      _currentId = null; // clear current if it was deleted
    }
    await _persistAndEmit();
  }

  @override
  Future<void> setCurrentTargets(String id) async {
    _currentId = id;
    await _persistAndEmit();
  }

  @override
  Future<UserTargets> getDefaultTargets() async =>
      UserTargets.defaultTargets();

  @override
  Future<UserTargets> createCuttingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  }) async {
    final preset = UserTargets.cuttingPreset(
      bodyWeightLbs: bodyWeightLbs,
      budgetCents: budgetCents,
    );
    await saveUserTargets(preset);
    await setCurrentTargets(preset.id);
    return preset;
  }

  @override
  Future<UserTargets> createBulkingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  }) async {
    final preset = UserTargets.bulkingPreset(
      bodyWeightLbs: bodyWeightLbs,
      budgetCents: budgetCents,
    );
    await saveUserTargets(preset);
    await setCurrentTargets(preset.id);
    return preset;
  }

  @override
  Future<bool> hasCompletedOnboarding() async =>
      _prefs.getBool(_kOnboardingDoneKey) ?? false;

  @override
  Future<void> markOnboardingCompleted() async =>
      _prefs.setBool(_kOnboardingDoneKey, true);

  @override
  Future<int> getTargetsCount() async => _allTargets.length;

  // -------- FIX: yield initial snapshot before controller stream --------
  @override
  Stream<UserTargets?> watchCurrentUserTargets() async* {
    yield _computeCurrent();            // immediate snapshot
    yield* _currentCtrl.stream;         // then live updates
  }

  @override
  Stream<List<UserTargets>> watchAllUserTargets() async* {
    yield List.unmodifiable(_allTargets); // immediate snapshot
    yield* _allCtrl.stream;               // then live updates
  }
}
