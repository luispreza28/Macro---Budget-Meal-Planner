import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../presentation/providers/recipe_providers.dart';
import '../../presentation/providers/ingredient_providers.dart';
import 'telemetry_service.dart';
import 'telemetry_settings_service.dart';

final diagnosticsBundleServiceProvider = Provider<DiagnosticsBundleService>((ref) => DiagnosticsBundleService(ref));

class DiagnosticsBundleService {
  DiagnosticsBundleService(this.ref);
  final Ref ref;

  Future<File> buildZip({
    required String feedbackId,
    required Map<String, dynamic> meta,
    List<String> screenshotPaths = const [],
  }) async {
    final now = DateTime.now();
    final dir = await getTemporaryDirectory();
    final zipPath = '${dir.path}/feedback_$feedbackId.zip';
    final zip = Archive();

    // app/device info
    final pkg = await PackageInfo.fromPlatform();
    final dev = await DeviceInfoPlugin().deviceInfo;
    final conn = await Connectivity().checkConnectivity();

    // settings snapshot
    final telemetrySettings = await ref.read(telemetrySettingsServiceProvider).get();

    // domain snapshot (lightweight)
    final recipes = await ref.read(allRecipesProvider.future);
    final ings = await ref.read(allIngredientsProvider.future);

    final snapshot = {
      'meta': meta, // kind, title, email, etc.
      'app': {'name': pkg.appName, 'version': pkg.version, 'build': pkg.buildNumber},
      'device': dev.data,
      'connectivity': conn.name,
      'telemetry': telemetrySettings.toJson(),
      'catalogCounts': {'recipes': recipes.length, 'ingredients': ings.length},
      'now': now.toIso8601String(),
    };
    zip.addFile(ArchiveFile.string('snapshot.json', jsonEncode(snapshot)));

    // logs (redacted) from Telemetry v1
    final telemetry = ref.read(telemetryServiceProvider);
    final logFile = await telemetry.flushAndFile();
    if (logFile != null && await logFile.exists()) {
      zip.addFile(ArchiveFile('logs/app_log.txt', await logFile.length(), await logFile.readAsBytes()));
    } else {
      final buf = telemetry.ringDump().join('\n');
      zip.addFile(ArchiveFile.string('logs/ring.txt', buf));
    }

    // screenshots
    for (int i = 0; i < screenshotPaths.length; i++) {
      final p = screenshotPaths[i];
      final f = File(p);
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        zip.addFile(ArchiveFile('screenshots/s${i}_${p.split('/').last}', bytes.length, bytes));
      }
    }

    // write zip
    final data = ZipEncoder().encode(zip)!;
    final out = File(zipPath);
    await out.writeAsBytes(data, flush: true);
    return out;
  }
}

