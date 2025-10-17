import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final scanQueueServiceProvider = Provider<ScanQueueService>((_) => ScanQueueService());

class ScanQueueService {
  static const _k = 'barcode.queue.v2'; // List<ScanItemJson>
  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<ScanItem>> list() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const [];
    try {
      final xs = (jsonDecode(raw) as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      return xs.map(ScanItem.fromJson).toList()
        ..sort((a, b) => (a.createdAt).compareTo(b.createdAt));
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<ScanItem> xs) async {
    final sp = await _sp();
    await sp.setString(_k, jsonEncode(xs.map((e) => e.toJson()).toList()));
  }

  Future<void> add(ScanItem item) async {
    final xs = await list();
    xs.add(item);
    await saveAll(xs);
  }

  Future<void> upsert(ScanItem item) async {
    final xs = await list();
    final i = xs.indexWhere((x) => x.id == item.id);
    if (i >= 0) {
      xs[i] = item;
    } else {
      xs.add(item);
    }
    await saveAll(xs);
  }

  Future<void> remove(String id) async {
    final xs = await list()..removeWhere((x) => x.id == id);
    await saveAll(xs);
  }

  Future<void> clearProcessed() async {
    final xs = await list()
      ..removeWhere((x) => x.status != ScanStatus.pending.name);
    await saveAll(xs);
  }
}

enum ScanStatus { pending, resolved, failed }

class ScanItem {
  final String id; // uuid
  final String ean; // barcode text
  final DateTime createdAt;
  final String? ingredientId;
  final String? storeId;
  final double? packQty; // in ingredient.base unit
  final String? packUnit; // 'g'|'ml'|'piece'
  final int? priceCents; // total price for pack
  final String status; // ScanStatus
  final String? note; // failure reason / comments
  const ScanItem({
    required this.id,
    required this.ean,
    required this.createdAt,
    this.ingredientId,
    this.storeId,
    this.packQty,
    this.packUnit,
    this.priceCents,
    this.status = 'pending',
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ean': ean,
        'createdAt': createdAt.toIso8601String(),
        'ingredientId': ingredientId,
        'storeId': storeId,
        'packQty': packQty,
        'packUnit': packUnit,
        'priceCents': priceCents,
        'status': status,
        'note': note,
      };

  factory ScanItem.fromJson(Map<String, dynamic> j) => ScanItem(
        id: j['id'] as String,
        ean: j['ean'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        ingredientId: j['ingredientId'] as String?,
        storeId: j['storeId'] as String?,
        packQty: (j['packQty'] as num?)?.toDouble(),
        packUnit: j['packUnit'] as String?,
        priceCents: (j['priceCents'] as num?)?.toInt(),
        status: (j['status'] as String?) ?? 'pending',
        note: j['note'] as String?,
      );

  ScanItem copyWith({
    String? ingredientId,
    String? storeId,
    double? packQty,
    String? packUnit,
    int? priceCents,
    ScanStatus? status,
    String? note,
  }) =>
      ScanItem(
        id: id,
        ean: ean,
        createdAt: createdAt,
        ingredientId: ingredientId ?? this.ingredientId,
        storeId: storeId ?? this.storeId,
        packQty: packQty ?? this.packQty,
        packUnit: packUnit ?? this.packUnit,
        priceCents: priceCents ?? this.priceCents,
        status: (status ??
                ScanStatus.values.firstWhere((e) => e.name == this.status))
            .name,
        note: note ?? this.note,
      );
}

