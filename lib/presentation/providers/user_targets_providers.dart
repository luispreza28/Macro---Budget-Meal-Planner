import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_targets.dart';
import '../../domain/repositories/user_targets_repository.dart';
import 'database_providers.dart';

/// Provider for current user targets
final currentUserTargetsProvider = StreamProvider<UserTargets?>((ref) {
  final repository = ref.watch(userTargetsRepositoryProvider);
  return repository.watchCurrentUserTargets();
});

/// Provider for all user targets (Pro feature - multiple presets)
final allUserTargetsProvider = StreamProvider<List<UserTargets>>((ref) {
  final repository = ref.watch(userTargetsRepositoryProvider);
  return repository.watchAllUserTargets();
});

/// Provider for user targets by ID
final userTargetsByIdProvider = 
    FutureProvider.family<UserTargets?, String>((ref, id) {
  final repository = ref.watch(userTargetsRepositoryProvider);
  return repository.getUserTargetsById(id);
});

/// Provider for default targets
final defaultUserTargetsProvider = FutureProvider<UserTargets>((ref) {
  final repository = ref.watch(userTargetsRepositoryProvider);
  return repository.getDefaultTargets();
});

/// Provider for onboarding completion status
final onboardingCompletedProvider = FutureProvider<bool>((ref) {
  final repository = ref.watch(userTargetsRepositoryProvider);
  return repository.hasCompletedOnboarding();
});

/// Provider for user targets count
final userTargetsCountProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(userTargetsRepositoryProvider);
  return repository.getTargetsCount();
});

/// Notifier for managing user targets operations
class UserTargetsNotifier extends StateNotifier<AsyncValue<void>> {
  UserTargetsNotifier(this._repository) : super(const AsyncValue.data(null));

  final UserTargetsRepository _repository;

  Future<void> saveUserTargets(UserTargets targets) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.saveUserTargets(targets));
  }

  Future<void> updateUserTargets(UserTargets targets) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateUserTargets(targets));
  }

  Future<void> deleteUserTargets(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deleteUserTargets(id));
  }

  Future<void> setCurrentTargets(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.setCurrentTargets(id));
  }

  Future<UserTargets> createCuttingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => _repository.createCuttingPreset(
      bodyWeightLbs: bodyWeightLbs,
      budgetCents: budgetCents,
    ));
    
    if (result.hasValue) {
      state = const AsyncValue.data(null);
      return result.value!;
    } else {
      throw result.error!;
    }
  }

  Future<UserTargets> createBulkingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => _repository.createBulkingPreset(
      bodyWeightLbs: bodyWeightLbs,
      budgetCents: budgetCents,
    ));
    
    if (result.hasValue) {
      state = const AsyncValue.data(null);
      return result.value!;
    } else {
      throw result.error!;
    }
  }

  Future<void> markOnboardingCompleted() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.markOnboardingCompleted());
  }
}

/// Provider for user targets operations
final userTargetsNotifierProvider = 
    StateNotifierProvider<UserTargetsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(userTargetsRepositoryProvider);
  return UserTargetsNotifier(repository);
});
