import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/services/feedback_service.dart';
import '../../providers/feedback_providers.dart';
import '../../../domain/services/telemetry_service.dart';

class FeedbackFormPage extends ConsumerStatefulWidget {
  const FeedbackFormPage({super.key, this.prefillTitle = '', this.prefillDescription = ''});
  final String prefillTitle;
  final String prefillDescription;

  @override
  ConsumerState<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends ConsumerState<FeedbackFormPage> {
  late FeedbackDraft _draft;
  final _formKey = GlobalKey<FormState>();
  final _screenshotController = ScreenshotController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final id = ref.read(newFeedbackDraftIdProvider);
    _draft = FeedbackDraft(
      id: id,
      kind: FeedbackKind.bug,
      title: widget.prefillTitle,
      description: widget.prefillDescription,
      steps: '',
      expected: '',
      actual: '',
      contactEmail: null,
      screenshotPaths: const [],
      createdAt: DateTime.now(),
    );
    // telemetry open
    ref.read(telemetryServiceProvider).event('feedback_open');
    _save();
  }

  Future<void> _save() async {
    await ref.read(saveFeedbackDraftProvider(_draft).future);
  }

  Future<void> _addScreenshotCapture() async {
    try {
      final bytes = await _screenshotController.capture(pixelRatio: 2.0);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fb_${_draft.id}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes, flush: true);
      setState(() {
        if (_draft.screenshotPaths.length < 5) {
          _draft = _draft.copyWith(screenshotPaths: [..._draft.screenshotPaths, file.path]);
        }
      });
      await _save();
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    try {
      final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (x == null) return;
      setState(() {
        if (_draft.screenshotPaths.length < 5) {
          _draft = _draft.copyWith(screenshotPaths: [..._draft.screenshotPaths, x.path]);
        }
      });
      await _save();
    } catch (_) {}
  }

  void _removeScreenshotAt(int i) async {
    final paths = [..._draft.screenshotPaths];
    final p = paths.removeAt(i);
    setState(() { _draft = _draft.copyWith(screenshotPaths: paths); });
    await _save();
    // best-effort cleanup
    try { final f = File(p); if (await f.exists()) { await f.delete(); } } catch (_) {}
  }

  Future<void> _preview() async {
    if (!mounted) return;
    context.push('/feedback/preview', extra: _draft);
  }

  Future<void> _send() async {
    // Build zip then show share sheet directly. Upload can be done in preview too.
    final res = await ref.read(buildDiagnosticsZipProvider(_draft).future);
    final (path, manifest) = res;
    await Share.shareXFiles([XFile(path)], subject: 'App Feedback');
    ref.read(telemetryServiceProvider).event('feedback_send', params: {'upload': false});
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        appBar: AppBar(title: const Text('Send Feedback')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<FeedbackKind>(
                segments: const [
                  ButtonSegment(value: FeedbackKind.bug, label: Text('Bug')),
                  ButtonSegment(value: FeedbackKind.suggestion, label: Text('Suggestion')),
                  ButtonSegment(value: FeedbackKind.data_issue, label: Text('Data issue')),
                  ButtonSegment(value: FeedbackKind.price_mismatch, label: Text('Price mismatch')),
                  ButtonSegment(value: FeedbackKind.other, label: Text('Other')),
                ],
                selected: {_draft.kind},
                onSelectionChanged: (s) {
                  setState(() => _draft = _draft.copyWith(kind: s.first));
                  _save();
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _draft.title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (v) { _draft = _draft.copyWith(title: v); _save(); },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _draft.description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (v) { _draft = _draft.copyWith(description: v); _save(); },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _draft.steps,
                decoration: const InputDecoration(labelText: 'Steps to reproduce'),
                maxLines: 3,
                onChanged: (v) { _draft = _draft.copyWith(steps: v); _save(); },
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _draft.expected,
                    decoration: const InputDecoration(labelText: 'Expected'),
                    onChanged: (v) { _draft = _draft.copyWith(expected: v); _save(); },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _draft.actual,
                    decoration: const InputDecoration(labelText: 'Actual'),
                    onChanged: (v) { _draft = _draft.copyWith(actual: v); _save(); },
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _draft.contactEmail ?? '',
                decoration: const InputDecoration(labelText: 'Contact email (optional)'),
                onChanged: (v) { _draft = _draft.copyWith(contactEmail: v.trim().isEmpty ? null : v.trim()); _save(); },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: _draft.screenshotPaths.length >= 5 ? null : _addScreenshotCapture,
                    child: const Text('Capture screen'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _draft.screenshotPaths.length >= 5 ? null : _pickFromGallery,
                    child: const Text('Pick from gallery'),
                  ),
                  const Spacer(),
                  Text('${_draft.screenshotPaths.length}/5'),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < _draft.screenshotPaths.length; i++)
                    Stack(
                      children: [
                        Image.file(File(_draft.screenshotPaths[i]), width: 96, height: 96, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeScreenshotAt(i),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(onPressed: _preview, child: const Text('Preview diagnostics')),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _send();
                      }
                    },
                    child: const Text('Send'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Privacy: We include app logs (redacted), device & app version, and any screenshots you attach.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

