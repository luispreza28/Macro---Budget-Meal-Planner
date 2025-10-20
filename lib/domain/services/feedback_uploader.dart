import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final feedbackUploaderProvider = Provider<FeedbackUploader>((_) => FeedbackUploader());

/// Placeholder uploader. Replace with Firebase implementation when configured.
class FeedbackUploader {
  Future<void> uploadZip({required String feedbackId, required Map<String, dynamic> manifest, required File zip}) async {
    throw UnsupportedError('Feedback upload not configured');
  }
}
