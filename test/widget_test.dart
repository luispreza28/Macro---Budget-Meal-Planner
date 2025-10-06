// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_budget_meal_planner/domain/entities/user_targets.dart';
import 'package:macro_budget_meal_planner/domain/repositories/user_targets_repository.dart';
import 'package:macro_budget_meal_planner/presentation/providers/database_providers.dart';

import 'package:macro_budget_meal_planner/main.dart';

// Mock UserTargets repository for testing
class MockUserTargetsRepository implements UserTargetsRepository {
  @override
  Future<UserTargets?> getCurrentUserTargets() async => null;
  
  @override
  Future<UserTargets?> getUserTargetsById(String id) async => null;
  
  @override
  Future<List<UserTargets>> getAllUserTargets() async => [];
  
  @override
  Future<void> saveUserTargets(UserTargets targets) async {}
  
  @override
  Future<void> updateUserTargets(UserTargets targets) async {}
  
  @override
  Future<void> deleteUserTargets(String id) async {}
  
  @override
  Future<void> setCurrentTargets(String id) async {}
  
  @override
  Future<UserTargets> getDefaultTargets() async => UserTargets.defaultTargets();
  
  @override
  Future<UserTargets> createCuttingPreset({required double bodyWeightLbs, int? budgetCents}) async =>
      UserTargets.cuttingPreset(bodyWeightLbs: bodyWeightLbs, budgetCents: budgetCents);
  
  @override
  Future<UserTargets> createBulkingPreset({required double bodyWeightLbs, int? budgetCents}) async =>
      UserTargets.bulkingPreset(bodyWeightLbs: bodyWeightLbs, budgetCents: budgetCents);
  
  @override
  Future<bool> hasCompletedOnboarding() async => false;
  
  @override
  Future<void> markOnboardingCompleted() async {}
  
  @override
  Future<int> getTargetsCount() async => 0;
  
  @override
  Stream<UserTargets?> watchCurrentUserTargets() => Stream.value(null);
  
  @override
  Stream<List<UserTargets>> watchAllUserTargets() => Stream.value([]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userTargetsRepositoryProvider.overrideWithValue(MockUserTargetsRepository()),
        ],
        child: const MacroBudgetMealPlannerApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the onboarding page loads
    expect(find.text('What\'s your goal?'), findsOneWidget);
    expect(find.text('Choose a preset to get started quickly, or customize your own targets.'), findsOneWidget);
  });

  testWidgets('Navigation from onboarding to home works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userTargetsRepositoryProvider.overrideWithValue(MockUserTargetsRepository()),
        ],
        child: const MacroBudgetMealPlannerApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Select a goal first to enable the Continue button
    await tester.tap(find.text('Cutting'));
    await tester.pumpAndSettle();
    
    // Tap the "Continue" button (not "Get Started" since that's only on the last step)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify that we moved to the next step (body weight step)
    expect(find.text('What\'s your body weight?'), findsOneWidget);
  });
}
