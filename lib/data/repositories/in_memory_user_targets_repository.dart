import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user_targets.dart';
import '../../domain/repositories/user_targets_repository.dart';

/// Simple in-memory + SharedPreferences implementation that
/// immediately emits the current value to watchers.
/// This prevents "infinite loading" in StreamProviders.
class InMemoryUserTargetsRepository implements UserTargetsRepository {
  InMemoryUserTargetsRepository(this._prefs) {
    // Load cached current targets (if any)
    final jsonStr = _prefs.getString(_kCurrentTargetsKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        _current = UserTargets.fromJson(map);
      } catch (_) {
        _current = null;
      }
    }
  }

  final SharedPreferences _prefs;

  static const String _kCurrentTargetsKey = 'user_targets_current';
  static const String _kOnboardingCompletedKey = 'onboarding_completed';

  final _controller = StreamController<UserTargets?>.broadcast();
  UserTargets? _current;

  // ---- Helpers ----
  void _emit(UserTargets? value) {
    _current = value;
    _controller.add(_current);
  }

  Future<void> _persist(UserTargets? value) async {
    if (value == null) {
      await _prefs.remove(_kCurrentTargetsKey);
    } else {
      await _prefs.setString(_kCurrentTargetsKey, json.encode(value.toJson()));
    }
  }

  // ---- Interface implementation ----

  @override
  Future<UserTargets?> getCurrentUserTargets() async => _current;

  @override
  Future<UserTargets?> getUserTargetsById(String id) async {
    if (_current?.id == id) return _current;
    return null;
  }

  @override
  Future<List<UserTargets>> getAllUserTargets() async {
    return _current == null ? <UserTargets>[] : <UserTargets>[_current!];
  }

  @override
  Future<void> saveUserTargets(UserTargets targets) async {
    await _persist(targets);
    _emit(targets);
  }

  @override
  Future<void> updateUserTargets(UserTargets targets) async {
    await _persist(targets);
    _emit(targets);
  }

  @override
  Future<void> deleteUserTargets(String id) async {
    if (_current?.id == id) {
      await _persist(null);
      _emit(null);
    }
  }

  @override
  Future<void> setCurrentTargets(String id) async {
    // Only 1 slot in this minimal impl. No-op unless mismatched IDs need handling.
    if (_current?.id != id) {
      // Nothing to switch to in this in-memory single-target demo.
    }
  }

  @override
  Future<UserTargets> getDefaultTargets() async => UserTargets.defaultTargets();

  @override
  Future<UserTargets> createCuttingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  }) async {
    return UserTargets.cuttingPreset(
      bodyWeightLbs: bodyWeightLbs,
      budgetCents: budgetCents,
    );
  }

  @override
  Future<UserTargets> createBulkingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  }) async {
    return UserTargets.bulkingPreset(
      bodyWeightLbs: bodyWeightLbs,
      budgetCents: budgetCents,
    );
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    return _prefs.getBool(_kOnboardingCompletedKey) ?? false;
  }

  @override
  Future<void> markOnboardingCompleted() async {
    await _prefs.setBool(_kOnboardingCompletedKey, true);
  }

  @override
  Future<int> getTargetsCount() async => _current == null ? 0 : 1;

  @override
  Stream<UserTargets?> watchCurrentUserTargets() async* {
    // Emit current value immediately (even if null) to avoid infinite loading
    yield _current;
    yield* _controller.stream;
  }

  @override
  Stream<List<UserTargets>> watchAllUserTargets() async* {
    yield _current == null ? <UserTargets>[] : <UserTargets>[_current!];
    yield* _controller.stream.map(
      (value) => value == null ? <UserTargets>[] : <UserTargets>[value],
    );
  }
}
