import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../../domain/entities/ingredient.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/pantry_item.dart' as domain;
import '../../domain/repositories/pantry_repository.dart';
import '../datasources/database.dart' as db;

// Represents a single validation issue (missing or insufficient stock)
class PantryIssue {
  PantryIssue({
    required this.ingredientId,
    required this.requiredQty,
    required this.availableQty,
    required this.unitName,
    required this.reason,
  });

  final String ingredientId;
  final double requiredQty;
  final double availableQty;
  final String unitName;
  final String reason;

  @override
  String toString() =>
      '[$reason] $ingredientId: required=$requiredQty $unitName, available=$availableQty $unitName';
}

// Thrown when pantry stock cannot fulfill all requested items.
class PantryValidationException implements Exception {
  PantryValidationException(this.issues);

  final List<PantryIssue> issues;

  bool get isEmpty => issues.isEmpty;

  @override
  String toString() {
    if (issues.isEmpty) return 'PantryValidationException(no issues)';
    final lines = issues.map((i) => i.toString()).join('; ');
    return 'PantryValidationException: $lines';
  }
}

const double _kQuantityEpsilon = 1e-6;

class PantryRepositoryImpl implements PantryRepository {
  PantryRepositoryImpl(this._database);

  final db.AppDatabase _database;

  Future<void> Function()? _beforeTransactionCallback;

  @visibleForTesting
  set beforeTransactionCallback(Future<void> Function()? callback) {
    _beforeTransactionCallback = callback;
  }

  @override
  Future<List<domain.PantryItem>> getAllPantryItems() async {
    final rows = await _database.select(_database.pantryItems).get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<domain.PantryItem?> getPantryItemByIngredientId(
    String ingredientId,
  ) async {
    final row = await (_database.select(
      _database.pantryItems,
    )..where((tbl) => tbl.ingredientId.equals(ingredientId))).getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<List<domain.PantryItem>> getPantryItemsByIngredientIds(
    List<String> ingredientIds,
  ) async {
    if (ingredientIds.isEmpty) return const [];
    final rows = await (_database.select(
      _database.pantryItems,
    )..where((tbl) => tbl.ingredientId.isIn(ingredientIds))).get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<void> addPantryItem(domain.PantryItem item) async {
    await _database
        .into(_database.pantryItems)
        .insert(_mapToCompanion(item, updatedAt: item.addedAt));
  }

  @override
  Future<void> updatePantryItem(domain.PantryItem item) async {
    await _database
        .update(_database.pantryItems)
        .replace(_mapToCompanion(item));
  }

  @override
  Future<void> removePantryItem(String id) async {
    await (_database.delete(
      _database.pantryItems,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> removePantryItemByIngredientId(String ingredientId) async {
    await (_database.delete(
      _database.pantryItems,
    )..where((tbl) => tbl.ingredientId.equals(ingredientId))).go();
  }

  @override
  Future<void> clearPantry() async {
    await _database.delete(_database.pantryItems).go();
  }

  @override
  Future<bool> isIngredientInPantry(String ingredientId) async {
    final result =
        await (_database.selectOnly(_database.pantryItems)
              ..addColumns([_database.pantryItems.id.count()])
              ..where(_database.pantryItems.ingredientId.equals(ingredientId)))
            .getSingle();
    return (result.read(_database.pantryItems.id.count()) ?? 0) > 0;
  }

  @override
  Future<List<domain.PantryItem>> getPantryItemsWithSufficientQuantity(
    Map<String, double> requiredQuantities,
  ) async {
    if (requiredQuantities.isEmpty) return const [];
    final items = await getPantryItemsByIngredientIds(
      requiredQuantities.keys.toList(),
    );
    return items.where((item) {
      final required = requiredQuantities[item.ingredientId];
      return required != null && item.qty >= required;
    }).toList();
  }

  @override
  Future<void> useIngredientsFromPantry(
    Map<String, double> usedQuantities,
  ) async {
    if (usedQuantities.isEmpty) return;

    final requiredQuantities = <String, double>{};
    usedQuantities.forEach((ingredientId, qty) {
      if (qty > _kQuantityEpsilon) {
        requiredQuantities[ingredientId] = qty;
      }
    });
    if (requiredQuantities.isEmpty) return;

    final aggregates = await _loadPantryAggregates(requiredQuantities.keys);

    final issues = <PantryIssue>[];
    for (final entry in requiredQuantities.entries) {
      final ingredientId = entry.key;
      final requiredQty = entry.value;
      final aggregate = aggregates[ingredientId];

      if (aggregate == null || aggregate.totalQty <= _kQuantityEpsilon) {
        issues.add(
          PantryIssue(
            ingredientId: ingredientId,
            requiredQty: requiredQty,
            availableQty: 0,
            unitName: aggregate?.unitName ?? 'unknown',
            reason: 'missing',
          ),
        );
        continue;
      }

      if (aggregate.hasUnitMismatch) {
        issues.add(
          PantryIssue(
            ingredientId: ingredientId,
            requiredQty: requiredQty,
            availableQty: aggregate.totalQty,
            unitName: aggregate.unitName,
            reason: 'unit_mismatch',
          ),
        );
        continue;
      }

      if (aggregate.totalQty + _kQuantityEpsilon < requiredQty) {
        issues.add(
          PantryIssue(
            ingredientId: ingredientId,
            requiredQty: requiredQty,
            availableQty: aggregate.totalQty,
            unitName: aggregate.unitName,
            reason: 'insufficient',
          ),
        );
      }
    }

    if (issues.isNotEmpty) {
      throw PantryValidationException(issues);
    }

    await _database.transaction(() async {
      if (_beforeTransactionCallback != null) {
        await _beforeTransactionCallback!();
      }

      for (final entry in requiredQuantities.entries) {
        final ingredientId = entry.key;
        var remaining = entry.value;

        final rows =
            await (_database.select(_database.pantryItems)
                  ..where((tbl) => tbl.ingredientId.equals(ingredientId))
                  ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
                .get();

        for (final row in rows) {
          if (remaining <= _kQuantityEpsilon) break;

          final take = remaining < row.qty ? remaining : row.qty;
          final newQty = row.qty - take;

          if (newQty <= _kQuantityEpsilon) {
            await (_database.delete(
              _database.pantryItems,
            )..where((tbl) => tbl.id.equals(row.id))).go();
          } else {
            await (_database.update(
              _database.pantryItems,
            )..where((tbl) => tbl.id.equals(row.id))).write(
              db.PantryItemsCompanion(
                qty: Value(newQty),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }

          remaining -= take;
        }

        if (remaining > _kQuantityEpsilon) {
          final consumed = entry.value - remaining;
          throw PantryValidationException([
            PantryIssue(
              ingredientId: ingredientId,
              requiredQty: entry.value,
              availableQty: consumed,
              unitName: aggregates[ingredientId]?.unitName ?? 'unknown',
              reason: 'insufficient',
            ),
          ]);
        }
      }
    });
  }

  @override
  Future<int> getTotalPantryValueCents() async {
    final rows = await _database.select(_database.pantryItems).get();
    if (rows.isEmpty) return 0;
    final ingredientIds = {for (final row in rows) row.ingredientId}.toList();
    final ingredients = await (_database.select(
      _database.ingredients,
    )..where((tbl) => tbl.id.isIn(ingredientIds))).get();
    final priceByIngredient = {
      for (final ingredient in ingredients)
        ingredient.id: ingredient.pricePerUnitCents,
    };
    var total = 0;
    for (final row in rows) {
      final pricePerUnit = priceByIngredient[row.ingredientId];
      if (pricePerUnit == null) continue;
      total += (row.qty * pricePerUnit).round();
    }
    return total;
  }

  @override
  Future<int> getPantryItemsCount() async {
    final result = await (_database.selectOnly(
      _database.pantryItems,
    )..addColumns([_database.pantryItems.id.count()])).getSingle();
    return result.read(_database.pantryItems.id.count()) ?? 0;
  }

  @override
  Future<List<domain.PantryItem>> getPantryItemsByAisle(Aisle aisle) async {
    final query = _database.select(_database.pantryItems).join([
      innerJoin(
        _database.ingredients,
        _database.ingredients.id.equalsExp(_database.pantryItems.ingredientId),
      ),
    ])..where(_database.ingredients.aisle.equals(aisle.value));
    final rows = await query.get();
    return rows
        .map((row) => _mapToEntity(row.readTable(_database.pantryItems)))
        .toList();
  }

  @override
  Future<void> bulkInsertPantryItems(List<domain.PantryItem> items) async {
    if (items.isEmpty) return;
    await _database.batch((batch) {
      batch.insertAll(
        _database.pantryItems,
        items
            .map((item) => _mapToCompanion(item, updatedAt: item.addedAt))
            .toList(),
      );
    });
  }

  @override
  Stream<List<domain.PantryItem>> watchAllPantryItems() {
    return _database
        .select(_database.pantryItems)
        .watch()
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Stream<domain.PantryItem?> watchPantryItemByIngredientId(
    String ingredientId,
  ) {
    return (_database.select(_database.pantryItems)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .watchSingleOrNull()
        .map((row) => row != null ? _mapToEntity(row) : null);
  }

  @override
  Stream<int> watchPantryItemsCount() {
    return (_database.selectOnly(_database.pantryItems)
          ..addColumns([_database.pantryItems.id.count()]))
        .watchSingle()
        .map((row) => row.read(_database.pantryItems.id.count()) ?? 0);
  }

  Future<Map<String, _PantryAggregate>> _loadPantryAggregates(
    Iterable<String> ingredientIds,
  ) async {
    final ids = ingredientIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const {};

    final rows = await (_database.select(
      _database.pantryItems,
    )..where((tbl) => tbl.ingredientId.isIn(ids))).get();

    final aggregates = <String, _PantryAggregate>{};
    for (final row in rows) {
      final aggregate = aggregates.putIfAbsent(
        row.ingredientId,
        () => _PantryAggregate(),
      );
      aggregate.addRow(row);
    }
    return aggregates;
  }

  domain.PantryItem _mapToEntity(db.PantryItem data) {
    return domain.PantryItem(
      id: data.id,
      ingredientId: data.ingredientId,
      qty: data.qty,
      unit: _unitFromString(data.unit),
      addedAt: data.createdAt,
    );
  }

  db.PantryItemsCompanion _mapToCompanion(
    domain.PantryItem item, {
    DateTime? updatedAt,
  }) {
    final timestamp = updatedAt ?? DateTime.now();
    return db.PantryItemsCompanion(
      id: Value(item.id),
      ingredientId: Value(item.ingredientId),
      qty: Value(item.qty),
      unit: Value(item.unit.value),
      createdAt: Value(item.addedAt),
      updatedAt: Value(timestamp),
    );
  }

  Unit _unitFromString(String value) {
    return Unit.values.firstWhere(
      (unit) => unit.value == value,
      orElse: () => Unit.grams,
    );
  }
}

class _PantryAggregate {
  _PantryAggregate();

  double totalQty = 0;
  final Set<String> _units = <String>{};

  void addRow(db.PantryItem row) {
    totalQty += row.qty;
    _units.add(row.unit);
  }

  String get unitName {
    if (_units.isEmpty) {
      return 'unknown';
    }
    if (_units.length == 1) {
      return _units.first;
    }
    return 'mixed';
  }

  bool get hasUnitMismatch => _units.length > 1;
}

  @override
  Future<Map<String, ({double qty, Unit unit})>> getOnHand() async {
    // Aggregate by ingredientId in the ingredient's base unit only.
    final query = _database.select(_database.pantryItems).join([
      innerJoin(
        _database.ingredients,
        _database.ingredients.id.equalsExp(_database.pantryItems.ingredientId),
      ),
    ]);

    final rows = await query.get();
    final Map<String, ({double qty, Unit unit})> out = {};
    for (final row in rows) {
      final p = row.readTable(_database.pantryItems);
      final ingRow = row.readTable(_database.ingredients);
      final baseUnit = Unit.values.firstWhere(
        (u) => u.value == ingRow.unit,
        orElse: () => Unit.grams,
      );
      if (p.unit != ingRow.unit) {
        // Skip non-base unit rows for conservative total without schema changes.
        continue;
      }
      final prev = out[p.ingredientId];
      final acc = (prev?.qty ?? 0) + p.qty;
      out[p.ingredientId] = (qty: acc, unit: baseUnit);
    }
    return out;
  }

  @override
  Future<int> addOnHandDeltas(
    List<({String ingredientId, double qty, Unit unit})> deltas,
  ) async {
    if (deltas.isEmpty) return 0;
    final now = DateTime.now();
    final uuid = const Uuid();
    await _database.batch((batch) {
      for (final d in deltas) {
        batch.insert(
          _database.pantryItems,
          db.PantryItemsCompanion(
            id: Value('pantry_${uuid.v4()}'),
            ingredientId: Value(d.ingredientId),
            qty: Value(d.qty),
            unit: Value(d.unit.value),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
    });
    return deltas.map((e) => e.ingredientId).toSet().length;
  }

  @override
  Future<void> setOnHand({
    required String ingredientId,
    required double qty,
    required Unit unit,
  }) async {
    final now = DateTime.now();
    final uuid = const Uuid();
    await _database.transaction(() async {
      await (_database.delete(_database.pantryItems)
            ..where((t) => t.ingredientId.equals(ingredientId)))
          .go();
      await _database.into(_database.pantryItems).insert(
            db.PantryItemsCompanion(
              id: Value('pantry_${uuid.v4()}'),
              ingredientId: Value(ingredientId),
              qty: Value(qty),
              unit: Value(unit.value),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }
