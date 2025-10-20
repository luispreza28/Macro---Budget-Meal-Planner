import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/offline_center.dart';

final offlineDaemonProvider = Provider<OfflineDaemon>((ref) {
  final d = OfflineDaemon(ref);
  d.start();
  ref.onDispose(d.stop);
  return d;
});

class OfflineDaemon {
  OfflineDaemon(this.ref);
  final Ref ref;
  Timer? _t;

  void start() {
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 20), (_) async {
      final online = await ref.read(connectivityStatusProvider.future).then((s) => s.online).catchError((_) {
        return false;
      });
      await ref.read(offlineCenterProvider).processEligible(online: online);
      ref.invalidate(offlineTasksProvider);
    });
  }

  void stop() {
    _t?.cancel();
    _t = null;
  }
}

