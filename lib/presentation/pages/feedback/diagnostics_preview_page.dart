import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../domain/services/feedback_service.dart';
import '../../providers/feedback_providers.dart';
import '../../../domain/services/telemetry_service.dart';

class DiagnosticsPreviewPage extends ConsumerWidget {
  const DiagnosticsPreviewPage({super.key, required this.draft});
  final FeedbackDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zipAsync = ref.watch(buildDiagnosticsZipProvider(draft));
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics Preview')),
      body: zipAsync.when(
        data: (data) {
          final (path, manifest) = data;
          final file = File(path);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Included files:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('snapshot.json'),
                Text('logs/app_log.txt or logs/ring.txt'),
                Text('screenshots (${draft.screenshotPaths.length})'),
                const SizedBox(height: 12),
                Text('Approx. size: ${_prettySize(file.lengthSync())}'),
                const SizedBox(height: 16),
                const Text('Privacy: Logs and snapshot include redaction for emails and long tokens.'),
                const Spacer(),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        await Share.shareXFiles([XFile(path)], subject: 'App Feedback');
                        ref.read(telemetryServiceProvider).event('feedback_send', params: {'upload': false});
                      },
                      child: const Text('Share ZIP'),
                    ),
                    const SizedBox(width: 8),
                    if (kFeedbackUploadEnabled)
                      FutureBuilder(
                        future: Connectivity().checkConnectivity(),
                        builder: (context, snap) {
                          final offline = (snap.data?.name ?? 'none') == 'none';
                          return FilledButton(
                            onPressed: offline
                                ? null
                                : () async {
                                    final ok = await ref.read(uploadFeedbackProvider((path, manifest)).future);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text(ok ? 'Uploaded: ${manifest['id']}' : 'Upload failed'),
                                      ));
                                      if (ok) {
                                        ref.read(telemetryServiceProvider).event('feedback_send', params: {'upload': true});
                                      }
                                    }
                                  },
                            child: const Text('Upload to Support'),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to build diagnostics: $e')),
      ),
    );
  }

  static String _prettySize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unit = 0;
    while (size > 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(1)} ${units[unit]}';
  }
}
