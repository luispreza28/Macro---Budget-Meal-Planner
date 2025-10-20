import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/providers/database_providers.dart';

final feedbackServiceProvider = Provider<FeedbackService>((ref) => FeedbackService(ref));

enum FeedbackKind { bug, suggestion, data_issue, price_mismatch, other }

class FeedbackDraft {
  final String id; // uuid
  final FeedbackKind kind;
  final String title;
  final String description;
  final String steps;
  final String expected;
  final String actual;
  final String? contactEmail;
  final List<String> screenshotPaths; // local file paths
  final DateTime createdAt;
  const FeedbackDraft({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.steps,
    required this.expected,
    required this.actual,
    this.contactEmail,
    this.screenshotPaths = const [],
    required this.createdAt,
  });

  FeedbackDraft copyWith({
    FeedbackKind? kind,
    String? title,
    String? description,
    String? steps,
    String? expected,
    String? actual,
    String? contactEmail,
    List<String>? screenshotPaths,
  }) => FeedbackDraft(
        id: id,
        kind: kind ?? this.kind,
        title: title ?? this.title,
        description: description ?? this.description,
        steps: steps ?? this.steps,
        expected: expected ?? this.expected,
        actual: actual ?? this.actual,
        contactEmail: contactEmail ?? this.contactEmail,
        screenshotPaths: screenshotPaths ?? this.screenshotPaths,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'description': description,
        'steps': steps,
        'expected': expected,
        'actual': actual,
        'contactEmail': contactEmail,
        'screenshotPaths': screenshotPaths,
        'createdAt': createdAt.toIso8601String(),
      };
  factory FeedbackDraft.fromJson(Map<String, dynamic> j) => FeedbackDraft(
        id: j['id'] as String,
        kind: FeedbackKind.values.firstWhere(
          (k) => k.name == ((j['kind'] as String?) ?? 'other'),
          orElse: () => FeedbackKind.other,
        ),
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        steps: (j['steps'] as String?) ?? '',
        expected: (j['expected'] as String?) ?? '',
        actual: (j['actual'] as String?) ?? '',
        contactEmail: j['contactEmail'] as String?,
        screenshotPaths: (j['screenshotPaths'] as List?)?.cast<String>() ?? const [],
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class FeedbackService {
  FeedbackService(this.ref);
  final Ref ref;
  static const _k = 'feedback.queue.v1'; // List<FeedbackDraft>
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<List<FeedbackDraft>> list() async {
    final raw = _prefs.getString(_k);
    if (raw == null) return const [];
    final xs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return xs.map(FeedbackDraft.fromJson).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveAll(List<FeedbackDraft> xs) async {
    await _prefs.setString(_k, jsonEncode(xs.map((e) => e.toJson()).toList()));
  }

  Future<void> upsert(FeedbackDraft d) async {
    final xs = await list();
    final i = xs.indexWhere((x) => x.id == d.id);
    if (i >= 0) {
      xs[i] = d;
    } else {
      xs.add(d);
    }
    await saveAll(xs);
  }

  Future<void> remove(String id) async {
    final xs = await list()..removeWhere((x) => x.id == id);
    await saveAll(xs);
  }
}
