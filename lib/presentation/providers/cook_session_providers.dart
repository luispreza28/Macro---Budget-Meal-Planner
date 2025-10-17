import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/services/step_duration_service.dart';

class CookSession {
  final String id; // uuid
  final String recipeId;
  final int stepIndex; // 0-based
  final int servingsOverride; // if 0 => use recipe.servings
  final bool ttsEnabled;
  final bool voiceEnabled;
  final bool keepAwake;
  final Map<int, int> durations; // stepIndex -> seconds
  const CookSession({
    required this.id,
    required this.recipeId,
    this.stepIndex = 0,
    this.servingsOverride = 0,
    this.ttsEnabled = false,
    this.voiceEnabled = true,
    this.keepAwake = true,
    this.durations = const {},
  });

  CookSession copyWith({
    int? stepIndex,
    int? servingsOverride,
    bool? ttsEnabled,
    bool? voiceEnabled,
    bool? keepAwake,
    Map<int, int>? durations,
  }) =>
      CookSession(
        id: id,
        recipeId: recipeId,
        stepIndex: stepIndex ?? this.stepIndex,
        servingsOverride: servingsOverride ?? this.servingsOverride,
        ttsEnabled: ttsEnabled ?? this.ttsEnabled,
        voiceEnabled: voiceEnabled ?? this.voiceEnabled,
        keepAwake: keepAwake ?? this.keepAwake,
        durations: durations ?? this.durations,
      );
}

final cookSessionProvider = StateNotifierProvider.family<CookSessionNotifier, CookSession, String>((ref, recipeId) {
  return CookSessionNotifier(ref, recipeId);
});

class CookSessionNotifier extends StateNotifier<CookSession> {
  CookSessionNotifier(this.ref, this.recipeId)
      : super(CookSession(id: const Uuid().v4(), recipeId: recipeId));
  final Ref ref;
  final String recipeId;

  Future<void> init() async {
    final dur = await ref.read(stepDurationServiceProvider).getForRecipe(recipeId);
    state = state.copyWith(durations: dur);
  }

  void next(int max) => state = state.copyWith(stepIndex: (state.stepIndex + 1).clamp(0, max - 1));
  void prev() => state = state.copyWith(stepIndex: (state.stepIndex - 1).clamp(0, state.stepIndex));
  void jump(int i, int max) => state = state.copyWith(stepIndex: i.clamp(0, max - 1));
  void setServingsOverride(int v) => state = state.copyWith(servingsOverride: v);
  void toggleTts() => state = state.copyWith(ttsEnabled: !state.ttsEnabled);
  void toggleVoice() => state = state.copyWith(voiceEnabled: !state.voiceEnabled);
  void toggleAwake() => state = state.copyWith(keepAwake: !state.keepAwake);
  Future<void> setDuration(int stepIndex, int seconds) async {
    await ref.read(stepDurationServiceProvider).upsert(recipeId, stepIndex, seconds);
    final d = Map<int, int>.from(state.durations)..[stepIndex] = seconds;
    state = state.copyWith(durations: d);
  }
}

