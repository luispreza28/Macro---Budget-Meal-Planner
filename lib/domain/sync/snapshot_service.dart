import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/plan_providers.dart';
import '../../presentation/providers/pantry_providers.dart';
import '../services/budget_settings_service.dart';
import '../services/multiweek_series_service.dart';
import '../services/periodization_service.dart';
import '../services/price_history_service.dart';
import '../services/sub_rules_service.dart';
import '../services/taste_profile_service.dart';
import 'snapshot_models.dart';

final snapshotServiceProvider = Provider<SnapshotService>((ref) => SnapshotService(ref));

class SnapshotService {
  SnapshotService(this.ref);
  final Ref ref;

  Future<AppSnapshot> buildSnapshot() async {
    // Drift data via providers
    final recipes = await ref.read(allRecipesProvider.future);
    final ingredients = await ref.read(allIngredientsProvider.future);
    final plans = await ref.read(allPlansProvider.future);
    final pantry = await ref.read(allPantryItemsProvider.future);

    // SP-backed services
    final taste = await ref.read(tasteProfileServiceProvider).get();
    final phases = await ref.read(periodizationServiceProvider).list();
    final series = await ref.read(multiweekSeriesServiceProvider).list();
    final budget = await ref.read(budgetSettingsServiceProvider).get();
    final subRules = await ref.read(subRulesServiceProvider).list();

    // Price history: read raw from SharedPreferences to avoid private accessor
    final sp = await SharedPreferences.getInstance();
    final rawPrice = sp.getString('price.history.v1');
    Map<String, dynamic> priceHistJson = {};
    if (rawPrice != null) {
      try {
        priceHistJson = (jsonDecode(rawPrice) as Map).cast<String, dynamic>();
      } catch (_) {
        priceHistJson = {};
      }
    }

    // Shopping checked state per plan
    final shoppingChecked = <String, dynamic>{};
    for (final p in plans) {
      final key = 'shopping_checked_${p.id}';
      final xs = sp.getStringList(key) ?? const <String>[];
      shoppingChecked[key] = xs;
    }

    final drift = <String, dynamic>{
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'recipes': recipes.map((e) => e.toJson()).toList(),
      'plans': plans.map((e) => e.toJson()).toList(),
      'pantry': pantry.map((e) => e.toJson()).toList(),
    };
    final spMap = <String, dynamic>{
      'taste.profile.v1': taste.toJson(),
      'periodization.phases.v1': phases.map((e) => e.toJson()).toList(),
      'multiweek.series.v1': series.map((e) => e.toJson()).toList(),
      'price.history.v1': priceHistJson,
      'budget.settings.v2': budget.toJson(),
      'sub.rules.v1': subRules.map((e) => e.toJson()).toList(),
      'shopping.checked.v1': shoppingChecked,
    };

    return AppSnapshot(
      schema: 'snapshot.v1',
      createdAt: DateTime.now(),
      drift: drift,
      sp: spMap,
    );
  }

  Uint8List gzipJson(Map<String, dynamic> json) {
    final raw = utf8.encode(jsonEncode(json));
    final gz = GZipEncoder().encode(raw)!;
    return Uint8List.fromList(gz);
  }

  Future<SnapshotManifest> uploadSnapshot(AppSnapshot snap, {required String uid}) async {
    final id = const Uuid().v4();
    final path = 'snapshots/$uid/$id.json.gz';
    final gz = gzipJson(snap.toJson());
    final refS = FirebaseStorage.instance.ref(path);
    await refS.putData(gz, SettableMetadata(contentType: 'application/gzip'));

    final info = await PackageInfo.fromPlatform();
    final manifest = SnapshotManifest(
      id: id,
      appVersion: info.version,
      createdAt: snap.createdAt,
      records: _countRecords(snap),
      sections: _sectionCounts(snap),
      storagePath: refS.fullPath,
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('manifests')
        .doc(id)
        .set(manifest.toJson());
    if (kDebugMode) {
      debugPrint('[Cloud][backup] uploaded ${manifest.id} records=${manifest.records}');
    }
    return manifest;
  }

  int _countRecords(AppSnapshot s) {
    int n = 0;
    for (final v in s.drift.values) {
      if (v is List) n += v.length;
    }
    for (final v in s.sp.values) {
      if (v is List) n += v.length;
      else if (v is Map) n += v.length;
      else n += 1;
    }
    return n;
  }

  Map<String, int> _sectionCounts(AppSnapshot s) {
    final m = <String, int>{};
    s.drift.forEach((k, v) {
      m[k] = (v is List) ? v.length : 1;
    });
    s.sp.forEach((k, v) {
      m[k] = (v is List)
          ? v.length
          : (v is Map
              ? v.length
              : 1);
    });
    return m;
  }

  Future<List<SnapshotManifest>> listManifests(String uid) async {
    final q = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('manifests')
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs.map((d) => SnapshotManifest.fromJson(d.data())).toList();
  }

  Future<AppSnapshot> downloadSnapshot({required String uid, required String manifestId}) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('manifests')
        .doc(manifestId)
        .get();
    final m = SnapshotManifest.fromJson(doc.data()!);
    final refS = FirebaseStorage.instance.ref(m.storagePath);
    final data = await refS.getData();
    final archive = GZipDecoder().decodeBytes(data!);
    final json = jsonDecode(utf8.decode(archive)) as Map<String, dynamic>;
    return AppSnapshot.fromJson(json);
  }
}

