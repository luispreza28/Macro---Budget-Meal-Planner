import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'telemetry_settings_service.dart';

// Firebase
import 'package:firebase_analytics/firebase_analytics.dart' as fan;
import 'package:firebase_crashlytics/firebase_crashlytics.dart' as fcx;
import 'package:firebase_core/firebase_core.dart' as fcore;

// Optional sentry via dart-define USE_SENTRY
const bool _useSentry = bool.fromEnvironment('USE_SENTRY', defaultValue: false);
import 'package:sentry_flutter/sentry_flutter.dart' as snt;

final telemetryServiceProvider = Provider<TelemetryService>((ref) => TelemetryService(ref));

class TelemetryService {
  TelemetryService(this.ref);
  final Ref ref;

  final String _sessionId = const Uuid().v4();
  final List<String> _ring = <String>[];
  static const int _ringMax = 500;
  IOSink? _fileSink;
  File? _file;
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    final s = await ref.read(telemetrySettingsServiceProvider).get();
    if (!s.enabled) return;

    // Prepare log file first so we can log init issues too
    try {
      final dir = await getApplicationSupportDirectory();
      _file = File('${dir.path}/app_log.txt');
      _fileSink = _file!.openWrite(mode: FileMode.append);
    } catch (_) {}

    log('[telemetry] session=$_sessionId start');

    if (!kDebugMode) {
      try {
        if (_useSentry) {
          await snt.SentryFlutter.init((o) {
            o.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
            o.tracesSampleRate = s.performance ? 0.2 : 0.0;
            o.enableAutoNativeBreadcrumbs = s.breadcrumbs;
          });
        } else {
          try {
            await fcore.Firebase.initializeApp();
          } catch (_) {
            // ignore init failure; continue with local logs only
          }
          if (s.analytics) {
            try {
              await fan.FirebaseAnalytics.instance.logEvent(name: 'app_init', parameters: {'session': _sessionId});
            } catch (_) {}
          }
          try {
            await fcx.FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(s.crashReporting);
          } catch (_) {}
        }
      } catch (e) {
        // Do not crash on init failure
        log('[telemetry] init failed ${e.runtimeType}');
      }
    }
  }

  String sessionId() => _sessionId;
  String deviceHint() => '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

  void log(String line) {
    final redacted = _redact(line);
    final ts = DateTime.now().toIso8601String();
    final entry = '[$ts][$_sessionId] $redacted';
    _ring.add(entry);
    if (_ring.length > _ringMax) _ring.removeAt(0);
    try {
      _fileSink?.writeln(entry);
    } catch (_) {}
    if (kDebugMode) debugPrint(entry);
  }

  List<String> ringDump() => List.unmodifiable(_ring);

  Future<File?> flushAndFile() async {
    try {
      await _fileSink?.flush();
    } catch (_) {}
    return _file;
  }

  Future<void> recordError(Object error, StackTrace stack, {String? reason}) async {
    final s = await ref.read(telemetrySettingsServiceProvider).get();
    log('[error] ${reason ?? ''} ${error.runtimeType}');
    if (!s.enabled || kDebugMode) return;
    try {
      if (_useSentry) {
        await snt.Sentry.captureException(error, stackTrace: stack, hint: reason);
      } else {
        if (s.crashReporting) await fcx.FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
      }
    } catch (_) {}
  }

  Future<void> event(String name, {Map<String, Object?> params = const {}}) async {
    final s = await ref.read(telemetrySettingsServiceProvider).get();
    if (!s.enabled || !s.analytics) {
      log('[event.disabled] $name ${params.toString()}');
      return;
    }
    try {
      if (_useSentry) {
        await snt.Sentry.captureMessage('event:$name', level: snt.SentryLevel.info, withScope: (scope) {
          params.forEach((k, v) => scope.setTag(k, '$v'));
        });
      } else {
        await fan.FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
      }
    } catch (_) {}
    log('[event] $name ${params.toString()}');
  }

  T trace<T>(String name, T Function() body) {
    // Non-async convenience (best-effort – settings snapshot not awaited)
    final sw = Stopwatch()..start();
    try {
      return body();
    } finally {
      sw.stop();
      log('[trace] $name ${sw.elapsedMilliseconds}ms');
    }
  }

  Future<T> traceAsync<T>(String name, Future<T> Function() body) async {
    final s = await ref.read(telemetrySettingsServiceProvider).get();
    final enabled = s.enabled && s.performance;
    final sw = enabled ? (Stopwatch()..start()) : null;
    try {
      return await body();
    } finally {
      if (sw != null) {
        sw.stop();
        log('[trace] $name ${sw.elapsedMilliseconds}ms');
      }
    }
  }

  Future<File?> buildLogBundle() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final out = File('${tempDir.path}/telemetry_logs_${DateTime.now().millisecondsSinceEpoch}.zip');
      final encoder = ZipFileEncoder();
      encoder.create(out.path);
      final f = await flushAndFile();
      if (f != null && await f.exists()) {
        encoder.addFile(f);
      }
      final ringText = ringDump().join('\n');
      final ringFile = File('${tempDir.path}/ring_buffer.txt');
      await ringFile.writeAsString(ringText);
      encoder.addFile(ringFile);
      encoder.close();
      try { await ringFile.delete(); } catch (_) {}
      return out;
    } catch (e) {
      log('[telemetry] bundle failed ${e.runtimeType}');
      return null;
    }
  }

  String _redact(String s) {
    // Basic redaction: emails, 12+ digit numbers
    s = s.replaceAll(RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false), '<email>');
    s = s.replaceAll(RegExp(r'\b\d{12,}\b'), '<num>');
    return s;
  }
}
