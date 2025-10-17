import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../sync/snapshot_models.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/plan.dart';
import '../../domain/sync/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

final planTemplateIOProvider = Provider<PlanTemplateIO>((ref) => PlanTemplateIO(ref));

class PlanTemplateIO {
  PlanTemplateIO(this.ref);
  final Ref ref;

  /// Build normalized template payload from an existing plan.
  /// Includes the plan (days->meals recipeId+servings), referenced recipes (with items), and referenced ingredients minimal schema.
  Future<Map<String, dynamic>> exportTemplatePayload(Plan plan) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Templates] export start');
    }

    final recipes = <Recipe>[];
    final ings = <Ingredient>{};

    // Snapshot ingredients once for lookup
    final allIngs = await ref.read(allIngredientsProvider.future);
    final ingMap = {for (final i in allIngs) i.id: i};

    for (final d in plan.days) {
      for (final m in d.meals) {
        final r = await ref.read(recipeByIdProvider(m.recipeId).future);
        if (r != null) {
          recipes.add(r);
          for (final it in r.items) {
            final ing = ingMap[it.ingredientId];
            if (ing != null) ings.add(ing);
          }
        }
      }
    }
    final payload = {
      'schema': 'plan.template.v1',
      'plan': plan.toJson(),
      'recipes': recipes.map((r) => r.toJson()).toList(),
      'ingredients': ings.map((i) => i.toJson()).toList(),
    };
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Templates] export done: recipes=${recipes.length} ings=${ings.length}');
    }
    return payload;
  }

  Uint8List gzipJson(Map<String, dynamic> json) {
    final raw = utf8.encode(jsonEncode(json));
    final gz = GZipEncoder().encode(raw)!;
    return Uint8List.fromList(gz);
  }

  Future<ShareLink> uploadTemplateBlob({
    required Map<String, dynamic> payload,
    required String name,
    required List<String> tags,
    String? coverEmoji,
    String? notes,
    bool unlisted = true,
  }) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Templates] share start');
    }
    final uid = ref.read(authServiceProvider).uid();
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final id = const Uuid().v4();
    final path = 'templates/$uid/$id.json.gz';

    final refS = FirebaseStorage.instance.ref(path);
    await refS.putData(gzipJson(payload), SettableMetadata(contentType: 'application/gzip'));

    final manifest = {
      'id': id,
      'ownerUid': uid,
      'name': name,
      'tags': tags,
      'coverEmoji': coverEmoji,
      'notes': notes,
      'unlisted': unlisted,
      'createdAt': DateTime.now().toIso8601String(),
      'storagePath': refS.fullPath,
      'schema': 'plan.template.v1',
      'days': ((payload['plan']?['days'] as List?)?.length ?? 7),
    };

    await FirebaseFirestore.instance.collection('templates').doc(id).set(manifest);
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Templates] share uploaded manifest=$id');
    }
    return ShareLink(code: id);
  }

  Future<Map<String, dynamic>> downloadTemplatePayload(String code) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Templates] import download code=$code');
    }
    final doc = await FirebaseFirestore.instance.collection('templates').doc(code).get();
    if (!doc.exists) {
      throw StateError('Template not found');
    }
    final storagePath = doc['storagePath'] as String;
    final data = await FirebaseStorage.instance.ref(storagePath).getData();
    final json = jsonDecode(utf8.decode(GZipDecoder().decodeBytes(data!))) as Map<String, dynamic>;
    if (json['schema'] != 'plan.template.v1') {
      throw StateError('Unsupported template schema');
    }
    return json;
  }
}

class ShareLink {
  final String code;
  const ShareLink({required this.code});
}

