import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../domain/services/notification_service.dart';
import '../../../domain/services/cook_timer_service.dart';
import '../../../domain/services/voice_command_service.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/cook_session_providers.dart';
import '../../providers/cook_glue_providers.dart';
import '../../../domain/entities/recipe.dart';

class CookModePage extends ConsumerStatefulWidget {
  const CookModePage({super.key, required this.recipeId});
  final String recipeId;

  @override
  ConsumerState<CookModePage> createState() => _CookModePageState();
}

class _CookModePageState extends ConsumerState<CookModePage> {
  final _tts = FlutterTts();
  StreamSubscription<Duration>? _timerSub;
  Duration? _timerLeft;
  Duration? _timerTotal;
  bool _listening = false;

  String get _timerKey {
    final session = ref.read(cookSessionProvider(widget.recipeId));
    return '${session.id}-${session.stepIndex}';
  }

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(cookSessionProvider(widget.recipeId).notifier);
    // Initialize durations sidecar
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await notifier.init();
      final session = ref.read(cookSessionProvider(widget.recipeId));
      if (session.keepAwake) {
        await WakelockPlus.enable();
      }
      if (session.voiceEnabled) {
        _startVoice();
      }
    });
  }

  @override
  void dispose() {
    _stopVoice();
    _tts.stop();
    _timerSub?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _startVoice() async {
    if (_listening) return;
    final svc = ref.read(voiceCommandServiceProvider);
    final ok = await svc.init();
    if (!ok) return;
    _listening = true;
    await svc.listen(_onPhrase);
    if (mounted) setState(() {});
  }

  Future<void> _stopVoice() async {
    if (!_listening) return;
    await ref.read(voiceCommandServiceProvider).stop();
    _listening = false;
    if (mounted) setState(() {});
  }

  void _onPhrase(String p) async {
    final notifier = ref.read(cookSessionProvider(widget.recipeId).notifier);
    final recipe = ref.read(recipeByIdProvider(widget.recipeId)).value;
    final steps = recipe?.steps ?? const <String>[];
    if (p.contains('next')) {
      _haptic();
      notifier.next(steps.length);
      _speakCurrent();
    } else if (p.contains('back') || p.contains('previous')) {
      _haptic();
      notifier.prev();
      _speakCurrent();
    } else if (p.contains('repeat')) {
      _speakCurrent(force: true);
    } else if (p.contains('start timer')) {
      _startTimer();
    } else if (p.contains('pause timer') || p.contains('stop timer') || p.contains('stop')) {
      _stopTimer();
    } else if (p.contains('servings up')) {
      final s = ref.read(cookSessionProvider(widget.recipeId));
      final v = (s.servingsOverride == 0 ? (recipe?.servings ?? 1) : s.servingsOverride) + 1;
      ref.read(cookSessionProvider(widget.recipeId).notifier).setServingsOverride(v.clamp(1, 16));
    } else if (p.contains('servings down')) {
      final s = ref.read(cookSessionProvider(widget.recipeId));
      final cur = (s.servingsOverride == 0 ? (recipe?.servings ?? 1) : s.servingsOverride);
      final v = (cur - 1).clamp(1, 16);
      ref.read(cookSessionProvider(widget.recipeId).notifier).setServingsOverride(v);
    } else if (p.startsWith('how much')) {
      final parts = p.split(' ');
      if (parts.length >= 3) {
        final query = parts.sublist(2).join(' ').trim();
        if (query.isNotEmpty && recipe != null) {
          final s = ref.read(cookSessionProvider(widget.recipeId));
          final list = await ref.read(scaledIngredientsProvider((recipe, s.servingsOverride)).future);
          final found = list.firstWhere((l) => l.name.toLowerCase().contains(query), orElse: () => list.isNotEmpty ? list.first : null);
          if (mounted && found != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${found.name}: ${found.label}')),
            );
          }
        }
      }
    }
  }

  void _haptic() => HapticFeedback.mediumImpact();

  Future<void> _speakCurrent({bool force = false}) async {
    final session = ref.read(cookSessionProvider(widget.recipeId));
    if (!session.ttsEnabled && !force) return;
    final recipe = ref.read(recipeByIdProvider(widget.recipeId)).value;
    final step = (recipe?.steps ?? const <String>[])[session.stepIndex];
    await _tts.stop();
    await _tts.speak(step);
  }

  void _startTimer() {
    final session = ref.read(cookSessionProvider(widget.recipeId));
    final recipe = ref.read(recipeByIdProvider(widget.recipeId)).value;
    final steps = recipe?.steps ?? const <String>[];
    if (steps.isEmpty) return;
    final secs = session.durations[session.stepIndex] ?? 0;
    if (secs <= 0) return;
    final svc = ref.read(cookTimerServiceProvider);
    final key = _timerKey;
    _timerSub?.cancel();
    _timerLeft = Duration(seconds: secs);
    _timerTotal = Duration(seconds: secs);
    _timerSub = svc.start(key, Duration(seconds: secs)).listen((left) {
      setState(() => _timerLeft = left);
      if (left.inSeconds <= 0) {
        // Auto-cancel any scheduled fallback upon completion by simply not scheduling again
      }
    });
    setState(() {});
  }

  void _stopTimer() {
    final svc = ref.read(cookTimerServiceProvider);
    svc.stop(_timerKey);
    _timerSub?.cancel();
    _timerSub = null;
    setState(() {
      _timerLeft = null;
      _timerTotal = null;
    });
  }

  Future<bool> _onWillPop() async {
    // If a timer is running, schedule a one-shot notification as fallback
    if (_timerLeft != null && _timerLeft!.inSeconds > 0) {
      final recipe = ref.read(recipeByIdProvider(widget.recipeId)).value;
      final s = ref.read(cookSessionProvider(widget.recipeId));
      final notif = ref.read(notificationServiceProvider);
      await notif.init();
      await notif.requestPermissionIfNeeded();
      final title = 'Timer done — ${recipe?.name ?? 'Recipe'}';
      final body = 'Step ${s.stepIndex + 1} finished';
      // Use session.stepIndex to get deterministic id range 200xx
      final id = 20000 + s.stepIndex;
      await notif.scheduleIn(id: id, delay: _timerLeft!, title: title, body: body, payload: 'open:cook:${widget.recipeId}');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeByIdProvider(widget.recipeId));
    final session = ref.watch(cookSessionProvider(widget.recipeId));
    final notifier = ref.read(cookSessionProvider(widget.recipeId).notifier);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          title: recipeAsync.when(
            data: (r) => Text(r?.name ?? 'Cook'),
            loading: () => const Text('Cook'),
            error: (_, __) => const Text('Cook'),
          ),
          actions: [
            // Step indicator
            recipeAsync.maybeWhen(
              data: (r) => r != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                          child: Text('${session.stepIndex + 1}/${r.steps.length}',
                              style: Theme.of(context).textTheme.titleMedium)),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'tts':
                    notifier.toggleTts();
                    if (session.ttsEnabled) await _tts.stop();
                    break;
                  case 'voice':
                    notifier.toggleVoice();
                    final s = ref.read(cookSessionProvider(widget.recipeId));
                    if (s.voiceEnabled) {
                      _startVoice();
                    } else {
                      _stopVoice();
                    }
                    break;
                  case 'awake':
                    notifier.toggleAwake();
                    final s2 = ref.read(cookSessionProvider(widget.recipeId));
                    if (s2.keepAwake) {
                      await WakelockPlus.enable();
                    } else {
                      await WakelockPlus.disable();
                    }
                    break;
                }
                if (mounted) setState(() {});
              },
              itemBuilder: (ctx) => [
                CheckedPopupMenuItem(
                  value: 'tts',
                  checked: session.ttsEnabled,
                  child: const Text('Read step (TTS)'),
                ),
                CheckedPopupMenuItem(
                  value: 'voice',
                  checked: session.voiceEnabled,
                  child: const Text('Voice control'),
                ),
                CheckedPopupMenuItem(
                  value: 'awake',
                  checked: session.keepAwake,
                  child: const Text('Keep screen awake'),
                ),
              ],
            ),
          ],
        ),
        body: recipeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load: $e')),
          data: (recipe) {
            if (recipe == null) {
              return const Center(child: Text('Recipe not found'));
            }
            final steps = recipe.steps;
            if (steps.isEmpty) {
              return const Center(child: Text('No steps provided for this recipe.'));
            }

            final servings = session.servingsOverride == 0 ? recipe.servings : session.servingsOverride;

            return SafeArea(
              child: Column(
                children: [
                  // Yield scaler + ingredients peek
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Servings -',
                                onPressed: () {
                                  final v = (servings - 1).clamp(1, 16);
                                  notifier.setServingsOverride(v);
                                },
                                icon: const Icon(Icons.remove),
                              ),
                              Text('$servings', style: Theme.of(context).textTheme.titleMedium),
                              IconButton(
                                tooltip: 'Servings +',
                                onPressed: () {
                                  final v = (servings + 1).clamp(1, 16);
                                  notifier.setServingsOverride(v);
                                },
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ActionChip(
                          label: const Text('Ingredients'),
                          avatar: const Icon(Icons.list_alt),
                          onPressed: () async {
                            final lines = await ref.read(scaledIngredientsProvider((recipe, session.servingsOverride)).future);
                            if (!mounted) return;
                            showModalBottomSheet(
                              context: context,
                              showDragHandle: true,
                              builder: (ctx) => SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Ingredients', style: Theme.of(ctx).textTheme.titleMedium),
                                      const SizedBox(height: 8),
                                      Flexible(
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          itemBuilder: (_, i) => Row(
                                            children: [
                                              Expanded(child: Text(lines[i].name)),
                                              Text(lines[i].label, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                          separatorBuilder: (_, __) => const Divider(height: 8),
                                          itemCount: lines.length,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (session.voiceEnabled) ...[
                          const SizedBox(width: 8),
                          const _VoicePill(),
                        ],
                      ],
                    ),
                  ),

                  // Step card with swipe + tap to repeat
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _speakCurrent(force: true);
                      },
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity == null) return;
                        if (details.primaryVelocity! < 0) {
                          // left swipe => next
                          _haptic();
                          notifier.next(steps.length);
                          _speakCurrent();
                        } else if (details.primaryVelocity! > 0) {
                          _haptic();
                          notifier.prev();
                          _speakCurrent();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          steps[session.stepIndex],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(height: 1.3),
                        ),
                      ),
                    ),
                  ),

                  // Timer row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        _TimerWidget(
                          total: _timerTotal ?? (session.durations[session.stepIndex] != null ? Duration(seconds: session.durations[session.stepIndex]!) : null),
                          left: _timerLeft,
                          onStart: _startTimer,
                          onStop: _stopTimer,
                          onEdit: () async {
                            final secs = await _pickDurationSeconds(context, session.durations[session.stepIndex] ?? 0);
                            if (secs != null) {
                              await notifier.setDuration(session.stepIndex, secs);
                              if (mounted) setState(() {});
                            }
                          },
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () {
                            _haptic();
                            notifier.prev();
                            _speakCurrent();
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () {
                            _haptic();
                            notifier.next(steps.length);
                            _speakCurrent();
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<int?> _pickDurationSeconds(BuildContext context, int initialSeconds) async {
    final initialM = (initialSeconds ~/ 60);
    final initialS = (initialSeconds % 60);
    final mmCtrl = TextEditingController(text: '$initialM');
    final ssCtrl = TextEditingController(text: '$initialS');
    int? result;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step Timer', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: mmCtrl,
                      decoration: const InputDecoration(labelText: 'Minutes'),
                      keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: ssCtrl,
                      decoration: const InputDecoration(labelText: 'Seconds'),
                      keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      final m = int.tryParse(mmCtrl.text.trim()) ?? 0;
                      final s = int.tryParse(ssCtrl.text.trim()) ?? 0;
                      final v = (m.clamp(0, 999) * 60) + s.clamp(0, 59);
                      result = v;
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result;
  }
}

class _TimerWidget extends StatelessWidget {
  const _TimerWidget({
    required this.total,
    required this.left,
    required this.onStart,
    required this.onStop,
    required this.onEdit,
  });
  final Duration? total;
  final Duration? left;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = total;
    final l = left;
    final running = l != null && t != null && l.inSeconds > 0 && l.inSeconds <= t.inSeconds;
    final value = (t == null || l == null) ? null : (1 - (l.inMilliseconds / t.inMilliseconds));
    String label() {
      if (t == null) return 'No timer';
      final cur = l ?? t;
      final mm = cur.inMinutes.remainder(600).toString().padLeft(2, '0');
      final ss = cur.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$mm:$ss';
    }

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 56,
              width: 56,
              child: CircularProgressIndicator(
                value: value,
              ),
            ),
            Text(label()),
          ],
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Edit duration',
          onPressed: onEdit,
          icon: const Icon(Icons.edit),
        ),
        const SizedBox(width: 8),
        if (t != null)
          FilledButton.tonalIcon(
            onPressed: running ? onStop : onStart,
            icon: Icon(running ? Icons.pause : Icons.play_arrow),
            label: Text(running ? 'Pause' : 'Start'),
          ),
      ],
    );
  }
}

class _VoicePill extends StatelessWidget {
  const _VoicePill();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(children: [
        const Icon(Icons.mic, size: 16),
        const SizedBox(width: 6),
        Text('Listening', style: Theme.of(context).textTheme.labelMedium),
      ]),
    );
  }
}


