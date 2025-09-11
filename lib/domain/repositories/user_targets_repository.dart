import '../entities/user_targets.dart';

/// Repository interface for user targets data operations
abstract class UserTargetsRepository {
  /// Get current user targets
  Future<UserTargets?> getCurrentUserTargets();

  /// Get user targets by ID
  Future<UserTargets?> getUserTargetsById(String id);

  /// Get all user targets (for Pro users with multiple presets)
  Future<List<UserTargets>> getAllUserTargets();

  /// Save user targets
  Future<void> saveUserTargets(UserTargets targets);

  /// Update existing user targets
  Future<void> updateUserTargets(UserTargets targets);

  /// Delete user targets
  Future<void> deleteUserTargets(String id);

  /// Set current active targets
  Future<void> setCurrentTargets(String id);

  /// Get default targets for onboarding
  Future<UserTargets> getDefaultTargets();

  /// Create cutting preset
  Future<UserTargets> createCuttingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  });

  /// Create bulking preset
  Future<UserTargets> createBulkingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  });

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding();

  /// Mark onboarding as completed
  Future<void> markOnboardingCompleted();

  /// Get targets count
  Future<int> getTargetsCount();

  /// Watch current user targets (reactive stream)
  Stream<UserTargets?> watchCurrentUserTargets();

  /// Watch all user targets (reactive stream)
  Stream<List<UserTargets>> watchAllUserTargets();
}
