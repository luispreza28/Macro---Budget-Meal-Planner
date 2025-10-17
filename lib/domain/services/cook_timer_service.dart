import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cookTimerServiceProvider = Provider<CookTimerService>((_) => CookTimerService());

class CookTimerService {
  final _timers = <String, _TimerState>{}; // key: sessionId-stepIndex

  Stream<Duration> start(String key, Duration duration) {
    _timers[key]?.timer?.cancel();
    final c = StreamController<Duration>.broadcast();
    final state = _TimerState(duration: duration, left: duration, ctr: c);
    _timers[key] = state;
    c.add(duration);
    state.timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.left - const Duration(seconds: 1);
      state.left = left;
      if (left.inSeconds <= 0) {
        c.add(Duration.zero);
        t.cancel();
      } else {
        c.add(left);
      }
    });
    return c.stream;
  }

  void stop(String key) {
    _timers[key]?.timer?.cancel();
    _timers.remove(key);
  }

  Duration? currentLeft(String key) => _timers[key]?.left;
}

class _TimerState {
  _TimerState({required this.duration, required this.left, required this.ctr});
  final Duration duration;
  Duration left;
  Timer? timer;
  final StreamController<Duration> ctr;
}

