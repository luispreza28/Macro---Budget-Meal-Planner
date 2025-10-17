import 'dart:convert';

class SnapshotManifest {
  final String id; // uuid
  final String appVersion; // from package_info
  final DateTime createdAt; // serverTimestamp fallback to local
  final int records; // total records count
  final Map<String, int> sections; // counts per section
  final String storagePath; // gs://.../snapshots/{uid}/{id}.json.gz
  const SnapshotManifest({
    required this.id,
    required this.appVersion,
    required this.createdAt,
    required this.records,
    required this.sections,
    required this.storagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'appVersion': appVersion,
        'createdAt': createdAt.toIso8601String(),
        'records': records,
        'sections': sections,
        'storagePath': storagePath,
      };

  factory SnapshotManifest.fromJson(Map<String, dynamic> j) => SnapshotManifest(
        id: j['id'],
        appVersion: j['appVersion'],
        createdAt: DateTime.parse(j['createdAt']),
        records: j['records'],
        sections: (j['sections'] as Map)
            .map((k, v) => MapEntry(k as String, (v as num).toInt())),
        storagePath: j['storagePath'],
      );
}

class AppSnapshot {
  final String schema; // e.g., "snapshot.v1"
  final DateTime createdAt;
  final Map<String, dynamic> drift; // section->List<Map>
  final Map<String, dynamic> sp; // key->jsonValue
  const AppSnapshot({
    required this.schema,
    required this.createdAt,
    required this.drift,
    required this.sp,
  });

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'createdAt': createdAt.toIso8601String(),
        'drift': drift,
        'sp': sp,
      };

  factory AppSnapshot.fromJson(Map<String, dynamic> j) => AppSnapshot(
        schema: j['schema'],
        createdAt: DateTime.parse(j['createdAt']),
        drift: (j['drift'] as Map).cast<String, dynamic>(),
        sp: (j['sp'] as Map).cast<String, dynamic>(),
      );
}

