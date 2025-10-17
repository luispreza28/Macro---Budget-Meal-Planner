import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/plan.dart';
import '../../domain/services/plan_templates_service.dart';
import '../../domain/services/plan_template_io.dart';
import '../../domain/services/plan_template_apply_service.dart';

final localTemplatesProvider = FutureProvider<List<PlanTemplate>>((ref) async {
  return ref.read(planTemplatesServiceProvider).list();
});

final saveCurrentPlanAsTemplateProvider = FutureProvider.family<PlanTemplate?, (
  Plan plan,
  String name,
  List<String> tags,
  String? coverEmoji,
  String? notes,
)>((ref, arg) async {
  final (plan, name, tags, coverEmoji, notes) = arg;
  final payload = await ref.read(planTemplateIOProvider).exportTemplatePayload(plan);
  final t = PlanTemplate(
    id: const Uuid().v4(),
    name: name,
    tags: tags,
    coverEmoji: coverEmoji,
    notes: notes,
    createdAt: DateTime.now(),
    days: ((payload['plan']?['days'] as List?)?.length ?? 7),
    payload: payload,
  );
  await ref.read(planTemplatesServiceProvider).upsert(t);
  return t;
});

final shareTemplateProvider = FutureProvider.family<String?, PlanTemplate>((ref, t) async {
  final link = await ref.read(planTemplateIOProvider).uploadTemplateBlob(
        payload: t.payload,
        name: t.name,
        tags: t.tags,
        coverEmoji: t.coverEmoji,
        notes: t.notes,
        unlisted: true,
      );
  return link.code; // treat as sharing code
});

final importTemplateByCodeProvider =
    FutureProvider.family<(TemplatePreview, Map<String, dynamic>), String>((ref, code) async {
  final payload = await ref.read(planTemplateIOProvider).downloadTemplatePayload(code);
  final preview = await ref.read(planTemplateApplyServiceProvider).preview(payload);
  return (preview, payload);
});

final acceptImportProvider = FutureProvider.family<bool, (
  Map<String, dynamic> payload,
  String? saveName,
  List<String> tags,
  String? coverEmoji,
)>((ref, arg) async {
  final (payload, saveName, tags, coverEmoji) = arg;
  await ref.read(planTemplateApplyServiceProvider).importAndSave(
        payload: payload,
        saveLocalTemplateId: const Uuid().v4(),
        templateName: saveName,
        tags: tags,
        coverEmoji: coverEmoji,
      );
  return true;
});

final instantiateTemplateProvider =
    FutureProvider.family<Plan, Map<String, dynamic>>((ref, payload) async {
  return ref.read(planTemplateApplyServiceProvider).instantiatePlan(payload);
});

