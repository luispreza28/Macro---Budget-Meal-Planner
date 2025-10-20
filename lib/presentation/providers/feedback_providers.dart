import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/services/feedback_service.dart';
import '../../domain/services/diagnostics_bundle_service.dart';
import '../../domain/services/feedback_uploader.dart';

// Toggle upload UI via dart-define: --dart-define=FEEDBACK_UPLOAD=true
const bool kFeedbackUploadEnabled = bool.fromEnvironment('FEEDBACK_UPLOAD', defaultValue: false);

final feedbackQueueProvider = FutureProvider<List<FeedbackDraft>>((ref) async {
  return ref.read(feedbackServiceProvider).list();
});

final saveFeedbackDraftProvider = FutureProvider.family<FeedbackDraft, FeedbackDraft>((ref, draft) async {
  await ref.read(feedbackServiceProvider).upsert(draft);
  return draft;
});

final buildDiagnosticsZipProvider = FutureProvider.family<(String path, Map<String, dynamic> manifest), FeedbackDraft>((ref, draft) async {
  final manifest = {
    'id': draft.id,
    'kind': draft.kind.name,
    'title': draft.title,
    'createdAt': draft.createdAt.toIso8601String(),
    'contactEmail': draft.contactEmail,
  };
  final file = await ref.read(diagnosticsBundleServiceProvider).buildZip(
        feedbackId: draft.id,
        meta: manifest,
        screenshotPaths: draft.screenshotPaths,
      );
  return (file.path, manifest);
});

final uploadFeedbackProvider = FutureProvider.family<bool, (String path, Map<String, dynamic> manifest)>((ref, arg) async {
  final (path, manifest) = arg;
  try {
    await ref.read(feedbackUploaderProvider).uploadZip(
          feedbackId: manifest['id'] as String,
          manifest: manifest,
          zip: File(path),
        );
    return true;
  } catch (_) {
    return false;
  }
});

/// Helper to create a fresh draft id
final newFeedbackDraftIdProvider = Provider<String>((_) => const Uuid().v4());

