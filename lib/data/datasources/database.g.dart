// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $IngredientsTable extends Ingredients
    with TableInfo<$IngredientsTable, Ingredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalPer100gMeta = const VerificationMeta(
    'kcalPer100g',
  );
  @override
  late final GeneratedColumn<double> kcalPer100g = GeneratedColumn<double>(
    'kcal_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPer100gMeta = const VerificationMeta(
    'proteinPer100g',
  );
  @override
  late final GeneratedColumn<double> proteinPer100g = GeneratedColumn<double>(
    'protein_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsPer100gMeta = const VerificationMeta(
    'carbsPer100g',
  );
  @override
  late final GeneratedColumn<double> carbsPer100g = GeneratedColumn<double>(
    'carbs_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatPer100gMeta = const VerificationMeta(
    'fatPer100g',
  );
  @override
  late final GeneratedColumn<double> fatPer100g = GeneratedColumn<double>(
    'fat_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricePerUnitCentsMeta = const VerificationMeta(
    'pricePerUnitCents',
  );
  @override
  late final GeneratedColumn<int> pricePerUnitCents = GeneratedColumn<int>(
    'price_per_unit_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchasePackQtyMeta = const VerificationMeta(
    'purchasePackQty',
  );
  @override
  late final GeneratedColumn<double> purchasePackQty = GeneratedColumn<double>(
    'purchase_pack_qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchasePackUnitMeta = const VerificationMeta(
    'purchasePackUnit',
  );
  @override
  late final GeneratedColumn<String> purchasePackUnit = GeneratedColumn<String>(
    'purchase_pack_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchasePackPriceCentsMeta =
      const VerificationMeta('purchasePackPriceCents');
  @override
  late final GeneratedColumn<int> purchasePackPriceCents = GeneratedColumn<int>(
    'purchase_pack_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aisleMeta = const VerificationMeta('aisle');
  @override
  late final GeneratedColumn<String> aisle = GeneratedColumn<String>(
    'aisle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastVerifiedAtMeta = const VerificationMeta(
    'lastVerifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastVerifiedAt =
      GeneratedColumn<DateTime>(
        'last_verified_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    unit,
    kcalPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    pricePerUnitCents,
    purchasePackQty,
    purchasePackUnit,
    purchasePackPriceCents,
    aisle,
    tags,
    source,
    lastVerifiedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ingredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('kcal_per100g')) {
      context.handle(
        _kcalPer100gMeta,
        kcalPer100g.isAcceptableOrUnknown(
          data['kcal_per100g']!,
          _kcalPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kcalPer100gMeta);
    }
    if (data.containsKey('protein_per100g')) {
      context.handle(
        _proteinPer100gMeta,
        proteinPer100g.isAcceptableOrUnknown(
          data['protein_per100g']!,
          _proteinPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinPer100gMeta);
    }
    if (data.containsKey('carbs_per100g')) {
      context.handle(
        _carbsPer100gMeta,
        carbsPer100g.isAcceptableOrUnknown(
          data['carbs_per100g']!,
          _carbsPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbsPer100gMeta);
    }
    if (data.containsKey('fat_per100g')) {
      context.handle(
        _fatPer100gMeta,
        fatPer100g.isAcceptableOrUnknown(data['fat_per100g']!, _fatPer100gMeta),
      );
    } else if (isInserting) {
      context.missing(_fatPer100gMeta);
    }
    if (data.containsKey('price_per_unit_cents')) {
      context.handle(
        _pricePerUnitCentsMeta,
        pricePerUnitCents.isAcceptableOrUnknown(
          data['price_per_unit_cents']!,
          _pricePerUnitCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerUnitCentsMeta);
    }
    if (data.containsKey('purchase_pack_qty')) {
      context.handle(
        _purchasePackQtyMeta,
        purchasePackQty.isAcceptableOrUnknown(
          data['purchase_pack_qty']!,
          _purchasePackQtyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchasePackQtyMeta);
    }
    if (data.containsKey('purchase_pack_unit')) {
      context.handle(
        _purchasePackUnitMeta,
        purchasePackUnit.isAcceptableOrUnknown(
          data['purchase_pack_unit']!,
          _purchasePackUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchasePackUnitMeta);
    }
    if (data.containsKey('purchase_pack_price_cents')) {
      context.handle(
        _purchasePackPriceCentsMeta,
        purchasePackPriceCents.isAcceptableOrUnknown(
          data['purchase_pack_price_cents']!,
          _purchasePackPriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('aisle')) {
      context.handle(
        _aisleMeta,
        aisle.isAcceptableOrUnknown(data['aisle']!, _aisleMeta),
      );
    } else if (isInserting) {
      context.missing(_aisleMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('last_verified_at')) {
      context.handle(
        _lastVerifiedAtMeta,
        lastVerifiedAt.isAcceptableOrUnknown(
          data['last_verified_at']!,
          _lastVerifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ingredient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      kcalPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal_per100g'],
      )!,
      proteinPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_per100g'],
      )!,
      carbsPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_per100g'],
      )!,
      fatPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_per100g'],
      )!,
      pricePerUnitCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_per_unit_cents'],
      )!,
      purchasePackQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_pack_qty'],
      )!,
      purchasePackUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_pack_unit'],
      )!,
      purchasePackPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_pack_price_cents'],
      ),
      aisle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aisle'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      lastVerifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_verified_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(attachedDatabase, alias);
  }
}

class Ingredient extends DataClass implements Insertable<Ingredient> {
  final String id;
  final String name;
  final String unit;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final int pricePerUnitCents;
  final double purchasePackQty;
  final String purchasePackUnit;
  final int? purchasePackPriceCents;
  final String aisle;
  final String tags;
  final String source;
  final DateTime? lastVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.pricePerUnitCents,
    required this.purchasePackQty,
    required this.purchasePackUnit,
    this.purchasePackPriceCents,
    required this.aisle,
    required this.tags,
    required this.source,
    this.lastVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['kcal_per100g'] = Variable<double>(kcalPer100g);
    map['protein_per100g'] = Variable<double>(proteinPer100g);
    map['carbs_per100g'] = Variable<double>(carbsPer100g);
    map['fat_per100g'] = Variable<double>(fatPer100g);
    map['price_per_unit_cents'] = Variable<int>(pricePerUnitCents);
    map['purchase_pack_qty'] = Variable<double>(purchasePackQty);
    map['purchase_pack_unit'] = Variable<String>(purchasePackUnit);
    if (!nullToAbsent || purchasePackPriceCents != null) {
      map['purchase_pack_price_cents'] = Variable<int>(purchasePackPriceCents);
    }
    map['aisle'] = Variable<String>(aisle);
    map['tags'] = Variable<String>(tags);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || lastVerifiedAt != null) {
      map['last_verified_at'] = Variable<DateTime>(lastVerifiedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  IngredientsCompanion toCompanion(bool nullToAbsent) {
    return IngredientsCompanion(
      id: Value(id),
      name: Value(name),
      unit: Value(unit),
      kcalPer100g: Value(kcalPer100g),
      proteinPer100g: Value(proteinPer100g),
      carbsPer100g: Value(carbsPer100g),
      fatPer100g: Value(fatPer100g),
      pricePerUnitCents: Value(pricePerUnitCents),
      purchasePackQty: Value(purchasePackQty),
      purchasePackUnit: Value(purchasePackUnit),
      purchasePackPriceCents: purchasePackPriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePackPriceCents),
      aisle: Value(aisle),
      tags: Value(tags),
      source: Value(source),
      lastVerifiedAt: lastVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerifiedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Ingredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ingredient(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      kcalPer100g: serializer.fromJson<double>(json['kcalPer100g']),
      proteinPer100g: serializer.fromJson<double>(json['proteinPer100g']),
      carbsPer100g: serializer.fromJson<double>(json['carbsPer100g']),
      fatPer100g: serializer.fromJson<double>(json['fatPer100g']),
      pricePerUnitCents: serializer.fromJson<int>(json['pricePerUnitCents']),
      purchasePackQty: serializer.fromJson<double>(json['purchasePackQty']),
      purchasePackUnit: serializer.fromJson<String>(json['purchasePackUnit']),
      purchasePackPriceCents: serializer.fromJson<int?>(
        json['purchasePackPriceCents'],
      ),
      aisle: serializer.fromJson<String>(json['aisle']),
      tags: serializer.fromJson<String>(json['tags']),
      source: serializer.fromJson<String>(json['source']),
      lastVerifiedAt: serializer.fromJson<DateTime?>(json['lastVerifiedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'kcalPer100g': serializer.toJson<double>(kcalPer100g),
      'proteinPer100g': serializer.toJson<double>(proteinPer100g),
      'carbsPer100g': serializer.toJson<double>(carbsPer100g),
      'fatPer100g': serializer.toJson<double>(fatPer100g),
      'pricePerUnitCents': serializer.toJson<int>(pricePerUnitCents),
      'purchasePackQty': serializer.toJson<double>(purchasePackQty),
      'purchasePackUnit': serializer.toJson<String>(purchasePackUnit),
      'purchasePackPriceCents': serializer.toJson<int?>(purchasePackPriceCents),
      'aisle': serializer.toJson<String>(aisle),
      'tags': serializer.toJson<String>(tags),
      'source': serializer.toJson<String>(source),
      'lastVerifiedAt': serializer.toJson<DateTime?>(lastVerifiedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Ingredient copyWith({
    String? id,
    String? name,
    String? unit,
    double? kcalPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    int? pricePerUnitCents,
    double? purchasePackQty,
    String? purchasePackUnit,
    Value<int?> purchasePackPriceCents = const Value.absent(),
    String? aisle,
    String? tags,
    String? source,
    Value<DateTime?> lastVerifiedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Ingredient(
    id: id ?? this.id,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    kcalPer100g: kcalPer100g ?? this.kcalPer100g,
    proteinPer100g: proteinPer100g ?? this.proteinPer100g,
    carbsPer100g: carbsPer100g ?? this.carbsPer100g,
    fatPer100g: fatPer100g ?? this.fatPer100g,
    pricePerUnitCents: pricePerUnitCents ?? this.pricePerUnitCents,
    purchasePackQty: purchasePackQty ?? this.purchasePackQty,
    purchasePackUnit: purchasePackUnit ?? this.purchasePackUnit,
    purchasePackPriceCents: purchasePackPriceCents.present
        ? purchasePackPriceCents.value
        : this.purchasePackPriceCents,
    aisle: aisle ?? this.aisle,
    tags: tags ?? this.tags,
    source: source ?? this.source,
    lastVerifiedAt: lastVerifiedAt.present
        ? lastVerifiedAt.value
        : this.lastVerifiedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Ingredient copyWithCompanion(IngredientsCompanion data) {
    return Ingredient(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      kcalPer100g: data.kcalPer100g.present
          ? data.kcalPer100g.value
          : this.kcalPer100g,
      proteinPer100g: data.proteinPer100g.present
          ? data.proteinPer100g.value
          : this.proteinPer100g,
      carbsPer100g: data.carbsPer100g.present
          ? data.carbsPer100g.value
          : this.carbsPer100g,
      fatPer100g: data.fatPer100g.present
          ? data.fatPer100g.value
          : this.fatPer100g,
      pricePerUnitCents: data.pricePerUnitCents.present
          ? data.pricePerUnitCents.value
          : this.pricePerUnitCents,
      purchasePackQty: data.purchasePackQty.present
          ? data.purchasePackQty.value
          : this.purchasePackQty,
      purchasePackUnit: data.purchasePackUnit.present
          ? data.purchasePackUnit.value
          : this.purchasePackUnit,
      purchasePackPriceCents: data.purchasePackPriceCents.present
          ? data.purchasePackPriceCents.value
          : this.purchasePackPriceCents,
      aisle: data.aisle.present ? data.aisle.value : this.aisle,
      tags: data.tags.present ? data.tags.value : this.tags,
      source: data.source.present ? data.source.value : this.source,
      lastVerifiedAt: data.lastVerifiedAt.present
          ? data.lastVerifiedAt.value
          : this.lastVerifiedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ingredient(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('kcalPer100g: $kcalPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('pricePerUnitCents: $pricePerUnitCents, ')
          ..write('purchasePackQty: $purchasePackQty, ')
          ..write('purchasePackUnit: $purchasePackUnit, ')
          ..write('purchasePackPriceCents: $purchasePackPriceCents, ')
          ..write('aisle: $aisle, ')
          ..write('tags: $tags, ')
          ..write('source: $source, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    unit,
    kcalPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    pricePerUnitCents,
    purchasePackQty,
    purchasePackUnit,
    purchasePackPriceCents,
    aisle,
    tags,
    source,
    lastVerifiedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ingredient &&
          other.id == this.id &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.kcalPer100g == this.kcalPer100g &&
          other.proteinPer100g == this.proteinPer100g &&
          other.carbsPer100g == this.carbsPer100g &&
          other.fatPer100g == this.fatPer100g &&
          other.pricePerUnitCents == this.pricePerUnitCents &&
          other.purchasePackQty == this.purchasePackQty &&
          other.purchasePackUnit == this.purchasePackUnit &&
          other.purchasePackPriceCents == this.purchasePackPriceCents &&
          other.aisle == this.aisle &&
          other.tags == this.tags &&
          other.source == this.source &&
          other.lastVerifiedAt == this.lastVerifiedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class IngredientsCompanion extends UpdateCompanion<Ingredient> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> unit;
  final Value<double> kcalPer100g;
  final Value<double> proteinPer100g;
  final Value<double> carbsPer100g;
  final Value<double> fatPer100g;
  final Value<int> pricePerUnitCents;
  final Value<double> purchasePackQty;
  final Value<String> purchasePackUnit;
  final Value<int?> purchasePackPriceCents;
  final Value<String> aisle;
  final Value<String> tags;
  final Value<String> source;
  final Value<DateTime?> lastVerifiedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const IngredientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.kcalPer100g = const Value.absent(),
    this.proteinPer100g = const Value.absent(),
    this.carbsPer100g = const Value.absent(),
    this.fatPer100g = const Value.absent(),
    this.pricePerUnitCents = const Value.absent(),
    this.purchasePackQty = const Value.absent(),
    this.purchasePackUnit = const Value.absent(),
    this.purchasePackPriceCents = const Value.absent(),
    this.aisle = const Value.absent(),
    this.tags = const Value.absent(),
    this.source = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientsCompanion.insert({
    required String id,
    required String name,
    required String unit,
    required double kcalPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    required int pricePerUnitCents,
    required double purchasePackQty,
    required String purchasePackUnit,
    this.purchasePackPriceCents = const Value.absent(),
    required String aisle,
    required String tags,
    required String source,
    this.lastVerifiedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       unit = Value(unit),
       kcalPer100g = Value(kcalPer100g),
       proteinPer100g = Value(proteinPer100g),
       carbsPer100g = Value(carbsPer100g),
       fatPer100g = Value(fatPer100g),
       pricePerUnitCents = Value(pricePerUnitCents),
       purchasePackQty = Value(purchasePackQty),
       purchasePackUnit = Value(purchasePackUnit),
       aisle = Value(aisle),
       tags = Value(tags),
       source = Value(source);
  static Insertable<Ingredient> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<double>? kcalPer100g,
    Expression<double>? proteinPer100g,
    Expression<double>? carbsPer100g,
    Expression<double>? fatPer100g,
    Expression<int>? pricePerUnitCents,
    Expression<double>? purchasePackQty,
    Expression<String>? purchasePackUnit,
    Expression<int>? purchasePackPriceCents,
    Expression<String>? aisle,
    Expression<String>? tags,
    Expression<String>? source,
    Expression<DateTime>? lastVerifiedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (kcalPer100g != null) 'kcal_per100g': kcalPer100g,
      if (proteinPer100g != null) 'protein_per100g': proteinPer100g,
      if (carbsPer100g != null) 'carbs_per100g': carbsPer100g,
      if (fatPer100g != null) 'fat_per100g': fatPer100g,
      if (pricePerUnitCents != null) 'price_per_unit_cents': pricePerUnitCents,
      if (purchasePackQty != null) 'purchase_pack_qty': purchasePackQty,
      if (purchasePackUnit != null) 'purchase_pack_unit': purchasePackUnit,
      if (purchasePackPriceCents != null)
        'purchase_pack_price_cents': purchasePackPriceCents,
      if (aisle != null) 'aisle': aisle,
      if (tags != null) 'tags': tags,
      if (source != null) 'source': source,
      if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? unit,
    Value<double>? kcalPer100g,
    Value<double>? proteinPer100g,
    Value<double>? carbsPer100g,
    Value<double>? fatPer100g,
    Value<int>? pricePerUnitCents,
    Value<double>? purchasePackQty,
    Value<String>? purchasePackUnit,
    Value<int?>? purchasePackPriceCents,
    Value<String>? aisle,
    Value<String>? tags,
    Value<String>? source,
    Value<DateTime?>? lastVerifiedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return IngredientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      kcalPer100g: kcalPer100g ?? this.kcalPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      pricePerUnitCents: pricePerUnitCents ?? this.pricePerUnitCents,
      purchasePackQty: purchasePackQty ?? this.purchasePackQty,
      purchasePackUnit: purchasePackUnit ?? this.purchasePackUnit,
      purchasePackPriceCents:
          purchasePackPriceCents ?? this.purchasePackPriceCents,
      aisle: aisle ?? this.aisle,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (kcalPer100g.present) {
      map['kcal_per100g'] = Variable<double>(kcalPer100g.value);
    }
    if (proteinPer100g.present) {
      map['protein_per100g'] = Variable<double>(proteinPer100g.value);
    }
    if (carbsPer100g.present) {
      map['carbs_per100g'] = Variable<double>(carbsPer100g.value);
    }
    if (fatPer100g.present) {
      map['fat_per100g'] = Variable<double>(fatPer100g.value);
    }
    if (pricePerUnitCents.present) {
      map['price_per_unit_cents'] = Variable<int>(pricePerUnitCents.value);
    }
    if (purchasePackQty.present) {
      map['purchase_pack_qty'] = Variable<double>(purchasePackQty.value);
    }
    if (purchasePackUnit.present) {
      map['purchase_pack_unit'] = Variable<String>(purchasePackUnit.value);
    }
    if (purchasePackPriceCents.present) {
      map['purchase_pack_price_cents'] = Variable<int>(
        purchasePackPriceCents.value,
      );
    }
    if (aisle.present) {
      map['aisle'] = Variable<String>(aisle.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (lastVerifiedAt.present) {
      map['last_verified_at'] = Variable<DateTime>(lastVerifiedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('kcalPer100g: $kcalPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('pricePerUnitCents: $pricePerUnitCents, ')
          ..write('purchasePackQty: $purchasePackQty, ')
          ..write('purchasePackUnit: $purchasePackUnit, ')
          ..write('purchasePackPriceCents: $purchasePackPriceCents, ')
          ..write('aisle: $aisle, ')
          ..write('tags: $tags, ')
          ..write('source: $source, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, Recipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _servingsMeta = const VerificationMeta(
    'servings',
  );
  @override
  late final GeneratedColumn<int> servings = GeneratedColumn<int>(
    'servings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeMinsMeta = const VerificationMeta(
    'timeMins',
  );
  @override
  late final GeneratedColumn<int> timeMins = GeneratedColumn<int>(
    'time_mins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuisineMeta = const VerificationMeta(
    'cuisine',
  );
  @override
  late final GeneratedColumn<String> cuisine = GeneratedColumn<String>(
    'cuisine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dietFlagsMeta = const VerificationMeta(
    'dietFlags',
  );
  @override
  late final GeneratedColumn<String> dietFlags = GeneratedColumn<String>(
    'diet_flags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemsMeta = const VerificationMeta('items');
  @override
  late final GeneratedColumn<String> items = GeneratedColumn<String>(
    'items',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<String> steps = GeneratedColumn<String>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalPerServMeta = const VerificationMeta(
    'kcalPerServ',
  );
  @override
  late final GeneratedColumn<double> kcalPerServ = GeneratedColumn<double>(
    'kcal_per_serv',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPerServMeta = const VerificationMeta(
    'proteinPerServ',
  );
  @override
  late final GeneratedColumn<double> proteinPerServ = GeneratedColumn<double>(
    'protein_per_serv',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsPerServMeta = const VerificationMeta(
    'carbsPerServ',
  );
  @override
  late final GeneratedColumn<double> carbsPerServ = GeneratedColumn<double>(
    'carbs_per_serv',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatPerServMeta = const VerificationMeta(
    'fatPerServ',
  );
  @override
  late final GeneratedColumn<double> fatPerServ = GeneratedColumn<double>(
    'fat_per_serv',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costPerServCentsMeta = const VerificationMeta(
    'costPerServCents',
  );
  @override
  late final GeneratedColumn<int> costPerServCents = GeneratedColumn<int>(
    'cost_per_serv_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    servings,
    timeMins,
    cuisine,
    dietFlags,
    items,
    steps,
    kcalPerServ,
    proteinPerServ,
    carbsPerServ,
    fatPerServ,
    costPerServCents,
    source,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recipe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('servings')) {
      context.handle(
        _servingsMeta,
        servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta),
      );
    } else if (isInserting) {
      context.missing(_servingsMeta);
    }
    if (data.containsKey('time_mins')) {
      context.handle(
        _timeMinsMeta,
        timeMins.isAcceptableOrUnknown(data['time_mins']!, _timeMinsMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMinsMeta);
    }
    if (data.containsKey('cuisine')) {
      context.handle(
        _cuisineMeta,
        cuisine.isAcceptableOrUnknown(data['cuisine']!, _cuisineMeta),
      );
    }
    if (data.containsKey('diet_flags')) {
      context.handle(
        _dietFlagsMeta,
        dietFlags.isAcceptableOrUnknown(data['diet_flags']!, _dietFlagsMeta),
      );
    } else if (isInserting) {
      context.missing(_dietFlagsMeta);
    }
    if (data.containsKey('items')) {
      context.handle(
        _itemsMeta,
        items.isAcceptableOrUnknown(data['items']!, _itemsMeta),
      );
    } else if (isInserting) {
      context.missing(_itemsMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsMeta);
    }
    if (data.containsKey('kcal_per_serv')) {
      context.handle(
        _kcalPerServMeta,
        kcalPerServ.isAcceptableOrUnknown(
          data['kcal_per_serv']!,
          _kcalPerServMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kcalPerServMeta);
    }
    if (data.containsKey('protein_per_serv')) {
      context.handle(
        _proteinPerServMeta,
        proteinPerServ.isAcceptableOrUnknown(
          data['protein_per_serv']!,
          _proteinPerServMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinPerServMeta);
    }
    if (data.containsKey('carbs_per_serv')) {
      context.handle(
        _carbsPerServMeta,
        carbsPerServ.isAcceptableOrUnknown(
          data['carbs_per_serv']!,
          _carbsPerServMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbsPerServMeta);
    }
    if (data.containsKey('fat_per_serv')) {
      context.handle(
        _fatPerServMeta,
        fatPerServ.isAcceptableOrUnknown(
          data['fat_per_serv']!,
          _fatPerServMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fatPerServMeta);
    }
    if (data.containsKey('cost_per_serv_cents')) {
      context.handle(
        _costPerServCentsMeta,
        costPerServCents.isAcceptableOrUnknown(
          data['cost_per_serv_cents']!,
          _costPerServCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costPerServCentsMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recipe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      servings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}servings'],
      )!,
      timeMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_mins'],
      )!,
      cuisine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuisine'],
      ),
      dietFlags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diet_flags'],
      )!,
      items: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}steps'],
      )!,
      kcalPerServ: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal_per_serv'],
      )!,
      proteinPerServ: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_per_serv'],
      )!,
      carbsPerServ: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_per_serv'],
      )!,
      fatPerServ: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_per_serv'],
      )!,
      costPerServCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_per_serv_cents'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class Recipe extends DataClass implements Insertable<Recipe> {
  final String id;
  final String name;
  final int servings;
  final int timeMins;
  final String? cuisine;
  final String dietFlags;
  final String items;
  final String steps;
  final double kcalPerServ;
  final double proteinPerServ;
  final double carbsPerServ;
  final double fatPerServ;
  final int costPerServCents;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Recipe({
    required this.id,
    required this.name,
    required this.servings,
    required this.timeMins,
    this.cuisine,
    required this.dietFlags,
    required this.items,
    required this.steps,
    required this.kcalPerServ,
    required this.proteinPerServ,
    required this.carbsPerServ,
    required this.fatPerServ,
    required this.costPerServCents,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['servings'] = Variable<int>(servings);
    map['time_mins'] = Variable<int>(timeMins);
    if (!nullToAbsent || cuisine != null) {
      map['cuisine'] = Variable<String>(cuisine);
    }
    map['diet_flags'] = Variable<String>(dietFlags);
    map['items'] = Variable<String>(items);
    map['steps'] = Variable<String>(steps);
    map['kcal_per_serv'] = Variable<double>(kcalPerServ);
    map['protein_per_serv'] = Variable<double>(proteinPerServ);
    map['carbs_per_serv'] = Variable<double>(carbsPerServ);
    map['fat_per_serv'] = Variable<double>(fatPerServ);
    map['cost_per_serv_cents'] = Variable<int>(costPerServCents);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      name: Value(name),
      servings: Value(servings),
      timeMins: Value(timeMins),
      cuisine: cuisine == null && nullToAbsent
          ? const Value.absent()
          : Value(cuisine),
      dietFlags: Value(dietFlags),
      items: Value(items),
      steps: Value(steps),
      kcalPerServ: Value(kcalPerServ),
      proteinPerServ: Value(proteinPerServ),
      carbsPerServ: Value(carbsPerServ),
      fatPerServ: Value(fatPerServ),
      costPerServCents: Value(costPerServCents),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Recipe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recipe(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      servings: serializer.fromJson<int>(json['servings']),
      timeMins: serializer.fromJson<int>(json['timeMins']),
      cuisine: serializer.fromJson<String?>(json['cuisine']),
      dietFlags: serializer.fromJson<String>(json['dietFlags']),
      items: serializer.fromJson<String>(json['items']),
      steps: serializer.fromJson<String>(json['steps']),
      kcalPerServ: serializer.fromJson<double>(json['kcalPerServ']),
      proteinPerServ: serializer.fromJson<double>(json['proteinPerServ']),
      carbsPerServ: serializer.fromJson<double>(json['carbsPerServ']),
      fatPerServ: serializer.fromJson<double>(json['fatPerServ']),
      costPerServCents: serializer.fromJson<int>(json['costPerServCents']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'servings': serializer.toJson<int>(servings),
      'timeMins': serializer.toJson<int>(timeMins),
      'cuisine': serializer.toJson<String?>(cuisine),
      'dietFlags': serializer.toJson<String>(dietFlags),
      'items': serializer.toJson<String>(items),
      'steps': serializer.toJson<String>(steps),
      'kcalPerServ': serializer.toJson<double>(kcalPerServ),
      'proteinPerServ': serializer.toJson<double>(proteinPerServ),
      'carbsPerServ': serializer.toJson<double>(carbsPerServ),
      'fatPerServ': serializer.toJson<double>(fatPerServ),
      'costPerServCents': serializer.toJson<int>(costPerServCents),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Recipe copyWith({
    String? id,
    String? name,
    int? servings,
    int? timeMins,
    Value<String?> cuisine = const Value.absent(),
    String? dietFlags,
    String? items,
    String? steps,
    double? kcalPerServ,
    double? proteinPerServ,
    double? carbsPerServ,
    double? fatPerServ,
    int? costPerServCents,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Recipe(
    id: id ?? this.id,
    name: name ?? this.name,
    servings: servings ?? this.servings,
    timeMins: timeMins ?? this.timeMins,
    cuisine: cuisine.present ? cuisine.value : this.cuisine,
    dietFlags: dietFlags ?? this.dietFlags,
    items: items ?? this.items,
    steps: steps ?? this.steps,
    kcalPerServ: kcalPerServ ?? this.kcalPerServ,
    proteinPerServ: proteinPerServ ?? this.proteinPerServ,
    carbsPerServ: carbsPerServ ?? this.carbsPerServ,
    fatPerServ: fatPerServ ?? this.fatPerServ,
    costPerServCents: costPerServCents ?? this.costPerServCents,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Recipe copyWithCompanion(RecipesCompanion data) {
    return Recipe(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      servings: data.servings.present ? data.servings.value : this.servings,
      timeMins: data.timeMins.present ? data.timeMins.value : this.timeMins,
      cuisine: data.cuisine.present ? data.cuisine.value : this.cuisine,
      dietFlags: data.dietFlags.present ? data.dietFlags.value : this.dietFlags,
      items: data.items.present ? data.items.value : this.items,
      steps: data.steps.present ? data.steps.value : this.steps,
      kcalPerServ: data.kcalPerServ.present
          ? data.kcalPerServ.value
          : this.kcalPerServ,
      proteinPerServ: data.proteinPerServ.present
          ? data.proteinPerServ.value
          : this.proteinPerServ,
      carbsPerServ: data.carbsPerServ.present
          ? data.carbsPerServ.value
          : this.carbsPerServ,
      fatPerServ: data.fatPerServ.present
          ? data.fatPerServ.value
          : this.fatPerServ,
      costPerServCents: data.costPerServCents.present
          ? data.costPerServCents.value
          : this.costPerServCents,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recipe(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('servings: $servings, ')
          ..write('timeMins: $timeMins, ')
          ..write('cuisine: $cuisine, ')
          ..write('dietFlags: $dietFlags, ')
          ..write('items: $items, ')
          ..write('steps: $steps, ')
          ..write('kcalPerServ: $kcalPerServ, ')
          ..write('proteinPerServ: $proteinPerServ, ')
          ..write('carbsPerServ: $carbsPerServ, ')
          ..write('fatPerServ: $fatPerServ, ')
          ..write('costPerServCents: $costPerServCents, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    servings,
    timeMins,
    cuisine,
    dietFlags,
    items,
    steps,
    kcalPerServ,
    proteinPerServ,
    carbsPerServ,
    fatPerServ,
    costPerServCents,
    source,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.id == this.id &&
          other.name == this.name &&
          other.servings == this.servings &&
          other.timeMins == this.timeMins &&
          other.cuisine == this.cuisine &&
          other.dietFlags == this.dietFlags &&
          other.items == this.items &&
          other.steps == this.steps &&
          other.kcalPerServ == this.kcalPerServ &&
          other.proteinPerServ == this.proteinPerServ &&
          other.carbsPerServ == this.carbsPerServ &&
          other.fatPerServ == this.fatPerServ &&
          other.costPerServCents == this.costPerServCents &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecipesCompanion extends UpdateCompanion<Recipe> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> servings;
  final Value<int> timeMins;
  final Value<String?> cuisine;
  final Value<String> dietFlags;
  final Value<String> items;
  final Value<String> steps;
  final Value<double> kcalPerServ;
  final Value<double> proteinPerServ;
  final Value<double> carbsPerServ;
  final Value<double> fatPerServ;
  final Value<int> costPerServCents;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.servings = const Value.absent(),
    this.timeMins = const Value.absent(),
    this.cuisine = const Value.absent(),
    this.dietFlags = const Value.absent(),
    this.items = const Value.absent(),
    this.steps = const Value.absent(),
    this.kcalPerServ = const Value.absent(),
    this.proteinPerServ = const Value.absent(),
    this.carbsPerServ = const Value.absent(),
    this.fatPerServ = const Value.absent(),
    this.costPerServCents = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    required String id,
    required String name,
    required int servings,
    required int timeMins,
    this.cuisine = const Value.absent(),
    required String dietFlags,
    required String items,
    required String steps,
    required double kcalPerServ,
    required double proteinPerServ,
    required double carbsPerServ,
    required double fatPerServ,
    required int costPerServCents,
    required String source,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       servings = Value(servings),
       timeMins = Value(timeMins),
       dietFlags = Value(dietFlags),
       items = Value(items),
       steps = Value(steps),
       kcalPerServ = Value(kcalPerServ),
       proteinPerServ = Value(proteinPerServ),
       carbsPerServ = Value(carbsPerServ),
       fatPerServ = Value(fatPerServ),
       costPerServCents = Value(costPerServCents),
       source = Value(source);
  static Insertable<Recipe> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? servings,
    Expression<int>? timeMins,
    Expression<String>? cuisine,
    Expression<String>? dietFlags,
    Expression<String>? items,
    Expression<String>? steps,
    Expression<double>? kcalPerServ,
    Expression<double>? proteinPerServ,
    Expression<double>? carbsPerServ,
    Expression<double>? fatPerServ,
    Expression<int>? costPerServCents,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (servings != null) 'servings': servings,
      if (timeMins != null) 'time_mins': timeMins,
      if (cuisine != null) 'cuisine': cuisine,
      if (dietFlags != null) 'diet_flags': dietFlags,
      if (items != null) 'items': items,
      if (steps != null) 'steps': steps,
      if (kcalPerServ != null) 'kcal_per_serv': kcalPerServ,
      if (proteinPerServ != null) 'protein_per_serv': proteinPerServ,
      if (carbsPerServ != null) 'carbs_per_serv': carbsPerServ,
      if (fatPerServ != null) 'fat_per_serv': fatPerServ,
      if (costPerServCents != null) 'cost_per_serv_cents': costPerServCents,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? servings,
    Value<int>? timeMins,
    Value<String?>? cuisine,
    Value<String>? dietFlags,
    Value<String>? items,
    Value<String>? steps,
    Value<double>? kcalPerServ,
    Value<double>? proteinPerServ,
    Value<double>? carbsPerServ,
    Value<double>? fatPerServ,
    Value<int>? costPerServCents,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      servings: servings ?? this.servings,
      timeMins: timeMins ?? this.timeMins,
      cuisine: cuisine ?? this.cuisine,
      dietFlags: dietFlags ?? this.dietFlags,
      items: items ?? this.items,
      steps: steps ?? this.steps,
      kcalPerServ: kcalPerServ ?? this.kcalPerServ,
      proteinPerServ: proteinPerServ ?? this.proteinPerServ,
      carbsPerServ: carbsPerServ ?? this.carbsPerServ,
      fatPerServ: fatPerServ ?? this.fatPerServ,
      costPerServCents: costPerServCents ?? this.costPerServCents,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (servings.present) {
      map['servings'] = Variable<int>(servings.value);
    }
    if (timeMins.present) {
      map['time_mins'] = Variable<int>(timeMins.value);
    }
    if (cuisine.present) {
      map['cuisine'] = Variable<String>(cuisine.value);
    }
    if (dietFlags.present) {
      map['diet_flags'] = Variable<String>(dietFlags.value);
    }
    if (items.present) {
      map['items'] = Variable<String>(items.value);
    }
    if (steps.present) {
      map['steps'] = Variable<String>(steps.value);
    }
    if (kcalPerServ.present) {
      map['kcal_per_serv'] = Variable<double>(kcalPerServ.value);
    }
    if (proteinPerServ.present) {
      map['protein_per_serv'] = Variable<double>(proteinPerServ.value);
    }
    if (carbsPerServ.present) {
      map['carbs_per_serv'] = Variable<double>(carbsPerServ.value);
    }
    if (fatPerServ.present) {
      map['fat_per_serv'] = Variable<double>(fatPerServ.value);
    }
    if (costPerServCents.present) {
      map['cost_per_serv_cents'] = Variable<int>(costPerServCents.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('servings: $servings, ')
          ..write('timeMins: $timeMins, ')
          ..write('cuisine: $cuisine, ')
          ..write('dietFlags: $dietFlags, ')
          ..write('items: $items, ')
          ..write('steps: $steps, ')
          ..write('kcalPerServ: $kcalPerServ, ')
          ..write('proteinPerServ: $proteinPerServ, ')
          ..write('carbsPerServ: $carbsPerServ, ')
          ..write('fatPerServ: $fatPerServ, ')
          ..write('costPerServCents: $costPerServCents, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserTargetsTable extends UserTargets
    with TableInfo<$UserTargetsTable, UserTarget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _budgetCentsMeta = const VerificationMeta(
    'budgetCents',
  );
  @override
  late final GeneratedColumn<int> budgetCents = GeneratedColumn<int>(
    'budget_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mealsPerDayMeta = const VerificationMeta(
    'mealsPerDay',
  );
  @override
  late final GeneratedColumn<int> mealsPerDay = GeneratedColumn<int>(
    'meals_per_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeCapMinsMeta = const VerificationMeta(
    'timeCapMins',
  );
  @override
  late final GeneratedColumn<int> timeCapMins = GeneratedColumn<int>(
    'time_cap_mins',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dietFlagsMeta = const VerificationMeta(
    'dietFlags',
  );
  @override
  late final GeneratedColumn<String> dietFlags = GeneratedColumn<String>(
    'diet_flags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planningModeMeta = const VerificationMeta(
    'planningMode',
  );
  @override
  late final GeneratedColumn<String> planningMode = GeneratedColumn<String>(
    'planning_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kcal,
    proteinG,
    carbsG,
    fatG,
    budgetCents,
    mealsPerDay,
    timeCapMins,
    dietFlags,
    equipment,
    planningMode,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserTarget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('budget_cents')) {
      context.handle(
        _budgetCentsMeta,
        budgetCents.isAcceptableOrUnknown(
          data['budget_cents']!,
          _budgetCentsMeta,
        ),
      );
    }
    if (data.containsKey('meals_per_day')) {
      context.handle(
        _mealsPerDayMeta,
        mealsPerDay.isAcceptableOrUnknown(
          data['meals_per_day']!,
          _mealsPerDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mealsPerDayMeta);
    }
    if (data.containsKey('time_cap_mins')) {
      context.handle(
        _timeCapMinsMeta,
        timeCapMins.isAcceptableOrUnknown(
          data['time_cap_mins']!,
          _timeCapMinsMeta,
        ),
      );
    }
    if (data.containsKey('diet_flags')) {
      context.handle(
        _dietFlagsMeta,
        dietFlags.isAcceptableOrUnknown(data['diet_flags']!, _dietFlagsMeta),
      );
    } else if (isInserting) {
      context.missing(_dietFlagsMeta);
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    } else if (isInserting) {
      context.missing(_equipmentMeta);
    }
    if (data.containsKey('planning_mode')) {
      context.handle(
        _planningModeMeta,
        planningMode.isAcceptableOrUnknown(
          data['planning_mode']!,
          _planningModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_planningModeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserTarget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserTarget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      budgetCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_cents'],
      ),
      mealsPerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meals_per_day'],
      )!,
      timeCapMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_cap_mins'],
      ),
      dietFlags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diet_flags'],
      )!,
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      planningMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planning_mode'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserTargetsTable createAlias(String alias) {
    return $UserTargetsTable(attachedDatabase, alias);
  }
}

class UserTarget extends DataClass implements Insertable<UserTarget> {
  final String id;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int? budgetCents;
  final int mealsPerDay;
  final int? timeCapMins;
  final String dietFlags;
  final String equipment;
  final String planningMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserTarget({
    required this.id,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.budgetCents,
    required this.mealsPerDay,
    this.timeCapMins,
    required this.dietFlags,
    required this.equipment,
    required this.planningMode,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kcal'] = Variable<double>(kcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    if (!nullToAbsent || budgetCents != null) {
      map['budget_cents'] = Variable<int>(budgetCents);
    }
    map['meals_per_day'] = Variable<int>(mealsPerDay);
    if (!nullToAbsent || timeCapMins != null) {
      map['time_cap_mins'] = Variable<int>(timeCapMins);
    }
    map['diet_flags'] = Variable<String>(dietFlags);
    map['equipment'] = Variable<String>(equipment);
    map['planning_mode'] = Variable<String>(planningMode);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserTargetsCompanion toCompanion(bool nullToAbsent) {
    return UserTargetsCompanion(
      id: Value(id),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      budgetCents: budgetCents == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetCents),
      mealsPerDay: Value(mealsPerDay),
      timeCapMins: timeCapMins == null && nullToAbsent
          ? const Value.absent()
          : Value(timeCapMins),
      dietFlags: Value(dietFlags),
      equipment: Value(equipment),
      planningMode: Value(planningMode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserTarget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserTarget(
      id: serializer.fromJson<String>(json['id']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      budgetCents: serializer.fromJson<int?>(json['budgetCents']),
      mealsPerDay: serializer.fromJson<int>(json['mealsPerDay']),
      timeCapMins: serializer.fromJson<int?>(json['timeCapMins']),
      dietFlags: serializer.fromJson<String>(json['dietFlags']),
      equipment: serializer.fromJson<String>(json['equipment']),
      planningMode: serializer.fromJson<String>(json['planningMode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'budgetCents': serializer.toJson<int?>(budgetCents),
      'mealsPerDay': serializer.toJson<int>(mealsPerDay),
      'timeCapMins': serializer.toJson<int?>(timeCapMins),
      'dietFlags': serializer.toJson<String>(dietFlags),
      'equipment': serializer.toJson<String>(equipment),
      'planningMode': serializer.toJson<String>(planningMode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserTarget copyWith({
    String? id,
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    Value<int?> budgetCents = const Value.absent(),
    int? mealsPerDay,
    Value<int?> timeCapMins = const Value.absent(),
    String? dietFlags,
    String? equipment,
    String? planningMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserTarget(
    id: id ?? this.id,
    kcal: kcal ?? this.kcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    budgetCents: budgetCents.present ? budgetCents.value : this.budgetCents,
    mealsPerDay: mealsPerDay ?? this.mealsPerDay,
    timeCapMins: timeCapMins.present ? timeCapMins.value : this.timeCapMins,
    dietFlags: dietFlags ?? this.dietFlags,
    equipment: equipment ?? this.equipment,
    planningMode: planningMode ?? this.planningMode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserTarget copyWithCompanion(UserTargetsCompanion data) {
    return UserTarget(
      id: data.id.present ? data.id.value : this.id,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      budgetCents: data.budgetCents.present
          ? data.budgetCents.value
          : this.budgetCents,
      mealsPerDay: data.mealsPerDay.present
          ? data.mealsPerDay.value
          : this.mealsPerDay,
      timeCapMins: data.timeCapMins.present
          ? data.timeCapMins.value
          : this.timeCapMins,
      dietFlags: data.dietFlags.present ? data.dietFlags.value : this.dietFlags,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      planningMode: data.planningMode.present
          ? data.planningMode.value
          : this.planningMode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserTarget(')
          ..write('id: $id, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('budgetCents: $budgetCents, ')
          ..write('mealsPerDay: $mealsPerDay, ')
          ..write('timeCapMins: $timeCapMins, ')
          ..write('dietFlags: $dietFlags, ')
          ..write('equipment: $equipment, ')
          ..write('planningMode: $planningMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kcal,
    proteinG,
    carbsG,
    fatG,
    budgetCents,
    mealsPerDay,
    timeCapMins,
    dietFlags,
    equipment,
    planningMode,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserTarget &&
          other.id == this.id &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.budgetCents == this.budgetCents &&
          other.mealsPerDay == this.mealsPerDay &&
          other.timeCapMins == this.timeCapMins &&
          other.dietFlags == this.dietFlags &&
          other.equipment == this.equipment &&
          other.planningMode == this.planningMode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserTargetsCompanion extends UpdateCompanion<UserTarget> {
  final Value<String> id;
  final Value<double> kcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<int?> budgetCents;
  final Value<int> mealsPerDay;
  final Value<int?> timeCapMins;
  final Value<String> dietFlags;
  final Value<String> equipment;
  final Value<String> planningMode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserTargetsCompanion({
    this.id = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.budgetCents = const Value.absent(),
    this.mealsPerDay = const Value.absent(),
    this.timeCapMins = const Value.absent(),
    this.dietFlags = const Value.absent(),
    this.equipment = const Value.absent(),
    this.planningMode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserTargetsCompanion.insert({
    required String id,
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    this.budgetCents = const Value.absent(),
    required int mealsPerDay,
    this.timeCapMins = const Value.absent(),
    required String dietFlags,
    required String equipment,
    required String planningMode,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kcal = Value(kcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG),
       mealsPerDay = Value(mealsPerDay),
       dietFlags = Value(dietFlags),
       equipment = Value(equipment),
       planningMode = Value(planningMode);
  static Insertable<UserTarget> custom({
    Expression<String>? id,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<int>? budgetCents,
    Expression<int>? mealsPerDay,
    Expression<int>? timeCapMins,
    Expression<String>? dietFlags,
    Expression<String>? equipment,
    Expression<String>? planningMode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (budgetCents != null) 'budget_cents': budgetCents,
      if (mealsPerDay != null) 'meals_per_day': mealsPerDay,
      if (timeCapMins != null) 'time_cap_mins': timeCapMins,
      if (dietFlags != null) 'diet_flags': dietFlags,
      if (equipment != null) 'equipment': equipment,
      if (planningMode != null) 'planning_mode': planningMode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserTargetsCompanion copyWith({
    Value<String>? id,
    Value<double>? kcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<int?>? budgetCents,
    Value<int>? mealsPerDay,
    Value<int?>? timeCapMins,
    Value<String>? dietFlags,
    Value<String>? equipment,
    Value<String>? planningMode,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserTargetsCompanion(
      id: id ?? this.id,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      budgetCents: budgetCents ?? this.budgetCents,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      timeCapMins: timeCapMins ?? this.timeCapMins,
      dietFlags: dietFlags ?? this.dietFlags,
      equipment: equipment ?? this.equipment,
      planningMode: planningMode ?? this.planningMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (budgetCents.present) {
      map['budget_cents'] = Variable<int>(budgetCents.value);
    }
    if (mealsPerDay.present) {
      map['meals_per_day'] = Variable<int>(mealsPerDay.value);
    }
    if (timeCapMins.present) {
      map['time_cap_mins'] = Variable<int>(timeCapMins.value);
    }
    if (dietFlags.present) {
      map['diet_flags'] = Variable<String>(dietFlags.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (planningMode.present) {
      map['planning_mode'] = Variable<String>(planningMode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserTargetsCompanion(')
          ..write('id: $id, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('budgetCents: $budgetCents, ')
          ..write('mealsPerDay: $mealsPerDay, ')
          ..write('timeCapMins: $timeCapMins, ')
          ..write('dietFlags: $dietFlags, ')
          ..write('equipment: $equipment, ')
          ..write('planningMode: $planningMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PantryItemsTable extends PantryItems
    with TableInfo<$PantryItemsTable, PantryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PantryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
    'ingredient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ingredientId,
    qty,
    unit,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pantry_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PantryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PantryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PantryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_id'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}qty'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PantryItemsTable createAlias(String alias) {
    return $PantryItemsTable(attachedDatabase, alias);
  }
}

class PantryItem extends DataClass implements Insertable<PantryItem> {
  final String id;
  final String ingredientId;
  final double qty;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PantryItem({
    required this.id,
    required this.ingredientId,
    required this.qty,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ingredient_id'] = Variable<String>(ingredientId);
    map['qty'] = Variable<double>(qty);
    map['unit'] = Variable<String>(unit);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PantryItemsCompanion toCompanion(bool nullToAbsent) {
    return PantryItemsCompanion(
      id: Value(id),
      ingredientId: Value(ingredientId),
      qty: Value(qty),
      unit: Value(unit),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PantryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PantryItem(
      id: serializer.fromJson<String>(json['id']),
      ingredientId: serializer.fromJson<String>(json['ingredientId']),
      qty: serializer.fromJson<double>(json['qty']),
      unit: serializer.fromJson<String>(json['unit']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ingredientId': serializer.toJson<String>(ingredientId),
      'qty': serializer.toJson<double>(qty),
      'unit': serializer.toJson<String>(unit),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PantryItem copyWith({
    String? id,
    String? ingredientId,
    double? qty,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PantryItem(
    id: id ?? this.id,
    ingredientId: ingredientId ?? this.ingredientId,
    qty: qty ?? this.qty,
    unit: unit ?? this.unit,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PantryItem copyWithCompanion(PantryItemsCompanion data) {
    return PantryItem(
      id: data.id.present ? data.id.value : this.id,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      qty: data.qty.present ? data.qty.value : this.qty,
      unit: data.unit.present ? data.unit.value : this.unit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PantryItem(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('qty: $qty, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ingredientId, qty, unit, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PantryItem &&
          other.id == this.id &&
          other.ingredientId == this.ingredientId &&
          other.qty == this.qty &&
          other.unit == this.unit &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PantryItemsCompanion extends UpdateCompanion<PantryItem> {
  final Value<String> id;
  final Value<String> ingredientId;
  final Value<double> qty;
  final Value<String> unit;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PantryItemsCompanion({
    this.id = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.qty = const Value.absent(),
    this.unit = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PantryItemsCompanion.insert({
    required String id,
    required String ingredientId,
    required double qty,
    required String unit,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ingredientId = Value(ingredientId),
       qty = Value(qty),
       unit = Value(unit);
  static Insertable<PantryItem> custom({
    Expression<String>? id,
    Expression<String>? ingredientId,
    Expression<double>? qty,
    Expression<String>? unit,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (qty != null) 'qty': qty,
      if (unit != null) 'unit': unit,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PantryItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? ingredientId,
    Value<double>? qty,
    Value<String>? unit,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PantryItemsCompanion(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PantryItemsCompanion(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('qty: $qty, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlansTable extends Plans with TableInfo<$PlansTable, Plan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userTargetsIdMeta = const VerificationMeta(
    'userTargetsId',
  );
  @override
  late final GeneratedColumn<String> userTargetsId = GeneratedColumn<String>(
    'user_targets_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<String> days = GeneratedColumn<String>(
    'days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalKcalMeta = const VerificationMeta(
    'totalKcal',
  );
  @override
  late final GeneratedColumn<double> totalKcal = GeneratedColumn<double>(
    'total_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalProteinGMeta = const VerificationMeta(
    'totalProteinG',
  );
  @override
  late final GeneratedColumn<double> totalProteinG = GeneratedColumn<double>(
    'total_protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalCarbsGMeta = const VerificationMeta(
    'totalCarbsG',
  );
  @override
  late final GeneratedColumn<double> totalCarbsG = GeneratedColumn<double>(
    'total_carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalFatGMeta = const VerificationMeta(
    'totalFatG',
  );
  @override
  late final GeneratedColumn<double> totalFatG = GeneratedColumn<double>(
    'total_fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalCostCentsMeta = const VerificationMeta(
    'totalCostCents',
  );
  @override
  late final GeneratedColumn<int> totalCostCents = GeneratedColumn<int>(
    'total_cost_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    userTargetsId,
    days,
    totalKcal,
    totalProteinG,
    totalCarbsG,
    totalFatG,
    totalCostCents,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Plan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('user_targets_id')) {
      context.handle(
        _userTargetsIdMeta,
        userTargetsId.isAcceptableOrUnknown(
          data['user_targets_id']!,
          _userTargetsIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_userTargetsIdMeta);
    }
    if (data.containsKey('days')) {
      context.handle(
        _daysMeta,
        days.isAcceptableOrUnknown(data['days']!, _daysMeta),
      );
    } else if (isInserting) {
      context.missing(_daysMeta);
    }
    if (data.containsKey('total_kcal')) {
      context.handle(
        _totalKcalMeta,
        totalKcal.isAcceptableOrUnknown(data['total_kcal']!, _totalKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalKcalMeta);
    }
    if (data.containsKey('total_protein_g')) {
      context.handle(
        _totalProteinGMeta,
        totalProteinG.isAcceptableOrUnknown(
          data['total_protein_g']!,
          _totalProteinGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalProteinGMeta);
    }
    if (data.containsKey('total_carbs_g')) {
      context.handle(
        _totalCarbsGMeta,
        totalCarbsG.isAcceptableOrUnknown(
          data['total_carbs_g']!,
          _totalCarbsGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalCarbsGMeta);
    }
    if (data.containsKey('total_fat_g')) {
      context.handle(
        _totalFatGMeta,
        totalFatG.isAcceptableOrUnknown(data['total_fat_g']!, _totalFatGMeta),
      );
    } else if (isInserting) {
      context.missing(_totalFatGMeta);
    }
    if (data.containsKey('total_cost_cents')) {
      context.handle(
        _totalCostCentsMeta,
        totalCostCents.isAcceptableOrUnknown(
          data['total_cost_cents']!,
          _totalCostCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalCostCentsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      userTargetsId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_targets_id'],
      )!,
      days: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}days'],
      )!,
      totalKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_kcal'],
      )!,
      totalProteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_protein_g'],
      )!,
      totalCarbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_carbs_g'],
      )!,
      totalFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_fat_g'],
      )!,
      totalCostCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cost_cents'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class Plan extends DataClass implements Insertable<Plan> {
  final String id;
  final String name;
  final String userTargetsId;
  final String days;
  final double totalKcal;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final int totalCostCents;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Plan({
    required this.id,
    required this.name,
    required this.userTargetsId,
    required this.days,
    required this.totalKcal,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.totalCostCents,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['user_targets_id'] = Variable<String>(userTargetsId);
    map['days'] = Variable<String>(days);
    map['total_kcal'] = Variable<double>(totalKcal);
    map['total_protein_g'] = Variable<double>(totalProteinG);
    map['total_carbs_g'] = Variable<double>(totalCarbsG);
    map['total_fat_g'] = Variable<double>(totalFatG);
    map['total_cost_cents'] = Variable<int>(totalCostCents);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      name: Value(name),
      userTargetsId: Value(userTargetsId),
      days: Value(days),
      totalKcal: Value(totalKcal),
      totalProteinG: Value(totalProteinG),
      totalCarbsG: Value(totalCarbsG),
      totalFatG: Value(totalFatG),
      totalCostCents: Value(totalCostCents),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Plan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plan(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      userTargetsId: serializer.fromJson<String>(json['userTargetsId']),
      days: serializer.fromJson<String>(json['days']),
      totalKcal: serializer.fromJson<double>(json['totalKcal']),
      totalProteinG: serializer.fromJson<double>(json['totalProteinG']),
      totalCarbsG: serializer.fromJson<double>(json['totalCarbsG']),
      totalFatG: serializer.fromJson<double>(json['totalFatG']),
      totalCostCents: serializer.fromJson<int>(json['totalCostCents']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'userTargetsId': serializer.toJson<String>(userTargetsId),
      'days': serializer.toJson<String>(days),
      'totalKcal': serializer.toJson<double>(totalKcal),
      'totalProteinG': serializer.toJson<double>(totalProteinG),
      'totalCarbsG': serializer.toJson<double>(totalCarbsG),
      'totalFatG': serializer.toJson<double>(totalFatG),
      'totalCostCents': serializer.toJson<int>(totalCostCents),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Plan copyWith({
    String? id,
    String? name,
    String? userTargetsId,
    String? days,
    double? totalKcal,
    double? totalProteinG,
    double? totalCarbsG,
    double? totalFatG,
    int? totalCostCents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Plan(
    id: id ?? this.id,
    name: name ?? this.name,
    userTargetsId: userTargetsId ?? this.userTargetsId,
    days: days ?? this.days,
    totalKcal: totalKcal ?? this.totalKcal,
    totalProteinG: totalProteinG ?? this.totalProteinG,
    totalCarbsG: totalCarbsG ?? this.totalCarbsG,
    totalFatG: totalFatG ?? this.totalFatG,
    totalCostCents: totalCostCents ?? this.totalCostCents,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Plan copyWithCompanion(PlansCompanion data) {
    return Plan(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      userTargetsId: data.userTargetsId.present
          ? data.userTargetsId.value
          : this.userTargetsId,
      days: data.days.present ? data.days.value : this.days,
      totalKcal: data.totalKcal.present ? data.totalKcal.value : this.totalKcal,
      totalProteinG: data.totalProteinG.present
          ? data.totalProteinG.value
          : this.totalProteinG,
      totalCarbsG: data.totalCarbsG.present
          ? data.totalCarbsG.value
          : this.totalCarbsG,
      totalFatG: data.totalFatG.present ? data.totalFatG.value : this.totalFatG,
      totalCostCents: data.totalCostCents.present
          ? data.totalCostCents.value
          : this.totalCostCents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plan(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('userTargetsId: $userTargetsId, ')
          ..write('days: $days, ')
          ..write('totalKcal: $totalKcal, ')
          ..write('totalProteinG: $totalProteinG, ')
          ..write('totalCarbsG: $totalCarbsG, ')
          ..write('totalFatG: $totalFatG, ')
          ..write('totalCostCents: $totalCostCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    userTargetsId,
    days,
    totalKcal,
    totalProteinG,
    totalCarbsG,
    totalFatG,
    totalCostCents,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plan &&
          other.id == this.id &&
          other.name == this.name &&
          other.userTargetsId == this.userTargetsId &&
          other.days == this.days &&
          other.totalKcal == this.totalKcal &&
          other.totalProteinG == this.totalProteinG &&
          other.totalCarbsG == this.totalCarbsG &&
          other.totalFatG == this.totalFatG &&
          other.totalCostCents == this.totalCostCents &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlansCompanion extends UpdateCompanion<Plan> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> userTargetsId;
  final Value<String> days;
  final Value<double> totalKcal;
  final Value<double> totalProteinG;
  final Value<double> totalCarbsG;
  final Value<double> totalFatG;
  final Value<int> totalCostCents;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.userTargetsId = const Value.absent(),
    this.days = const Value.absent(),
    this.totalKcal = const Value.absent(),
    this.totalProteinG = const Value.absent(),
    this.totalCarbsG = const Value.absent(),
    this.totalFatG = const Value.absent(),
    this.totalCostCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlansCompanion.insert({
    required String id,
    required String name,
    required String userTargetsId,
    required String days,
    required double totalKcal,
    required double totalProteinG,
    required double totalCarbsG,
    required double totalFatG,
    required int totalCostCents,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       userTargetsId = Value(userTargetsId),
       days = Value(days),
       totalKcal = Value(totalKcal),
       totalProteinG = Value(totalProteinG),
       totalCarbsG = Value(totalCarbsG),
       totalFatG = Value(totalFatG),
       totalCostCents = Value(totalCostCents);
  static Insertable<Plan> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? userTargetsId,
    Expression<String>? days,
    Expression<double>? totalKcal,
    Expression<double>? totalProteinG,
    Expression<double>? totalCarbsG,
    Expression<double>? totalFatG,
    Expression<int>? totalCostCents,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (userTargetsId != null) 'user_targets_id': userTargetsId,
      if (days != null) 'days': days,
      if (totalKcal != null) 'total_kcal': totalKcal,
      if (totalProteinG != null) 'total_protein_g': totalProteinG,
      if (totalCarbsG != null) 'total_carbs_g': totalCarbsG,
      if (totalFatG != null) 'total_fat_g': totalFatG,
      if (totalCostCents != null) 'total_cost_cents': totalCostCents,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlansCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? userTargetsId,
    Value<String>? days,
    Value<double>? totalKcal,
    Value<double>? totalProteinG,
    Value<double>? totalCarbsG,
    Value<double>? totalFatG,
    Value<int>? totalCostCents,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      userTargetsId: userTargetsId ?? this.userTargetsId,
      days: days ?? this.days,
      totalKcal: totalKcal ?? this.totalKcal,
      totalProteinG: totalProteinG ?? this.totalProteinG,
      totalCarbsG: totalCarbsG ?? this.totalCarbsG,
      totalFatG: totalFatG ?? this.totalFatG,
      totalCostCents: totalCostCents ?? this.totalCostCents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (userTargetsId.present) {
      map['user_targets_id'] = Variable<String>(userTargetsId.value);
    }
    if (days.present) {
      map['days'] = Variable<String>(days.value);
    }
    if (totalKcal.present) {
      map['total_kcal'] = Variable<double>(totalKcal.value);
    }
    if (totalProteinG.present) {
      map['total_protein_g'] = Variable<double>(totalProteinG.value);
    }
    if (totalCarbsG.present) {
      map['total_carbs_g'] = Variable<double>(totalCarbsG.value);
    }
    if (totalFatG.present) {
      map['total_fat_g'] = Variable<double>(totalFatG.value);
    }
    if (totalCostCents.present) {
      map['total_cost_cents'] = Variable<int>(totalCostCents.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('userTargetsId: $userTargetsId, ')
          ..write('days: $days, ')
          ..write('totalKcal: $totalKcal, ')
          ..write('totalProteinG: $totalProteinG, ')
          ..write('totalCarbsG: $totalCarbsG, ')
          ..write('totalFatG: $totalFatG, ')
          ..write('totalCostCents: $totalCostCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PriceOverridesTable extends PriceOverrides
    with TableInfo<$PriceOverridesTable, PriceOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
    'ingredient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricePerUnitCentsMeta = const VerificationMeta(
    'pricePerUnitCents',
  );
  @override
  late final GeneratedColumn<int> pricePerUnitCents = GeneratedColumn<int>(
    'price_per_unit_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchasePackQtyMeta = const VerificationMeta(
    'purchasePackQty',
  );
  @override
  late final GeneratedColumn<double> purchasePackQty = GeneratedColumn<double>(
    'purchase_pack_qty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePackUnitMeta = const VerificationMeta(
    'purchasePackUnit',
  );
  @override
  late final GeneratedColumn<String> purchasePackUnit = GeneratedColumn<String>(
    'purchase_pack_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePackPriceCentsMeta =
      const VerificationMeta('purchasePackPriceCents');
  @override
  late final GeneratedColumn<int> purchasePackPriceCents = GeneratedColumn<int>(
    'purchase_pack_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ingredientId,
    pricePerUnitCents,
    purchasePackQty,
    purchasePackUnit,
    purchasePackPriceCents,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('price_per_unit_cents')) {
      context.handle(
        _pricePerUnitCentsMeta,
        pricePerUnitCents.isAcceptableOrUnknown(
          data['price_per_unit_cents']!,
          _pricePerUnitCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerUnitCentsMeta);
    }
    if (data.containsKey('purchase_pack_qty')) {
      context.handle(
        _purchasePackQtyMeta,
        purchasePackQty.isAcceptableOrUnknown(
          data['purchase_pack_qty']!,
          _purchasePackQtyMeta,
        ),
      );
    }
    if (data.containsKey('purchase_pack_unit')) {
      context.handle(
        _purchasePackUnitMeta,
        purchasePackUnit.isAcceptableOrUnknown(
          data['purchase_pack_unit']!,
          _purchasePackUnitMeta,
        ),
      );
    }
    if (data.containsKey('purchase_pack_price_cents')) {
      context.handle(
        _purchasePackPriceCentsMeta,
        purchasePackPriceCents.isAcceptableOrUnknown(
          data['purchase_pack_price_cents']!,
          _purchasePackPriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PriceOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceOverride(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_id'],
      )!,
      pricePerUnitCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_per_unit_cents'],
      )!,
      purchasePackQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_pack_qty'],
      ),
      purchasePackUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_pack_unit'],
      ),
      purchasePackPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_pack_price_cents'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PriceOverridesTable createAlias(String alias) {
    return $PriceOverridesTable(attachedDatabase, alias);
  }
}

class PriceOverride extends DataClass implements Insertable<PriceOverride> {
  final String id;
  final String ingredientId;
  final int pricePerUnitCents;
  final double? purchasePackQty;
  final String? purchasePackUnit;
  final int? purchasePackPriceCents;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PriceOverride({
    required this.id,
    required this.ingredientId,
    required this.pricePerUnitCents,
    this.purchasePackQty,
    this.purchasePackUnit,
    this.purchasePackPriceCents,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ingredient_id'] = Variable<String>(ingredientId);
    map['price_per_unit_cents'] = Variable<int>(pricePerUnitCents);
    if (!nullToAbsent || purchasePackQty != null) {
      map['purchase_pack_qty'] = Variable<double>(purchasePackQty);
    }
    if (!nullToAbsent || purchasePackUnit != null) {
      map['purchase_pack_unit'] = Variable<String>(purchasePackUnit);
    }
    if (!nullToAbsent || purchasePackPriceCents != null) {
      map['purchase_pack_price_cents'] = Variable<int>(purchasePackPriceCents);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PriceOverridesCompanion toCompanion(bool nullToAbsent) {
    return PriceOverridesCompanion(
      id: Value(id),
      ingredientId: Value(ingredientId),
      pricePerUnitCents: Value(pricePerUnitCents),
      purchasePackQty: purchasePackQty == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePackQty),
      purchasePackUnit: purchasePackUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePackUnit),
      purchasePackPriceCents: purchasePackPriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePackPriceCents),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PriceOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceOverride(
      id: serializer.fromJson<String>(json['id']),
      ingredientId: serializer.fromJson<String>(json['ingredientId']),
      pricePerUnitCents: serializer.fromJson<int>(json['pricePerUnitCents']),
      purchasePackQty: serializer.fromJson<double?>(json['purchasePackQty']),
      purchasePackUnit: serializer.fromJson<String?>(json['purchasePackUnit']),
      purchasePackPriceCents: serializer.fromJson<int?>(
        json['purchasePackPriceCents'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ingredientId': serializer.toJson<String>(ingredientId),
      'pricePerUnitCents': serializer.toJson<int>(pricePerUnitCents),
      'purchasePackQty': serializer.toJson<double?>(purchasePackQty),
      'purchasePackUnit': serializer.toJson<String?>(purchasePackUnit),
      'purchasePackPriceCents': serializer.toJson<int?>(purchasePackPriceCents),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PriceOverride copyWith({
    String? id,
    String? ingredientId,
    int? pricePerUnitCents,
    Value<double?> purchasePackQty = const Value.absent(),
    Value<String?> purchasePackUnit = const Value.absent(),
    Value<int?> purchasePackPriceCents = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PriceOverride(
    id: id ?? this.id,
    ingredientId: ingredientId ?? this.ingredientId,
    pricePerUnitCents: pricePerUnitCents ?? this.pricePerUnitCents,
    purchasePackQty: purchasePackQty.present
        ? purchasePackQty.value
        : this.purchasePackQty,
    purchasePackUnit: purchasePackUnit.present
        ? purchasePackUnit.value
        : this.purchasePackUnit,
    purchasePackPriceCents: purchasePackPriceCents.present
        ? purchasePackPriceCents.value
        : this.purchasePackPriceCents,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PriceOverride copyWithCompanion(PriceOverridesCompanion data) {
    return PriceOverride(
      id: data.id.present ? data.id.value : this.id,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      pricePerUnitCents: data.pricePerUnitCents.present
          ? data.pricePerUnitCents.value
          : this.pricePerUnitCents,
      purchasePackQty: data.purchasePackQty.present
          ? data.purchasePackQty.value
          : this.purchasePackQty,
      purchasePackUnit: data.purchasePackUnit.present
          ? data.purchasePackUnit.value
          : this.purchasePackUnit,
      purchasePackPriceCents: data.purchasePackPriceCents.present
          ? data.purchasePackPriceCents.value
          : this.purchasePackPriceCents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceOverride(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('pricePerUnitCents: $pricePerUnitCents, ')
          ..write('purchasePackQty: $purchasePackQty, ')
          ..write('purchasePackUnit: $purchasePackUnit, ')
          ..write('purchasePackPriceCents: $purchasePackPriceCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ingredientId,
    pricePerUnitCents,
    purchasePackQty,
    purchasePackUnit,
    purchasePackPriceCents,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceOverride &&
          other.id == this.id &&
          other.ingredientId == this.ingredientId &&
          other.pricePerUnitCents == this.pricePerUnitCents &&
          other.purchasePackQty == this.purchasePackQty &&
          other.purchasePackUnit == this.purchasePackUnit &&
          other.purchasePackPriceCents == this.purchasePackPriceCents &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PriceOverridesCompanion extends UpdateCompanion<PriceOverride> {
  final Value<String> id;
  final Value<String> ingredientId;
  final Value<int> pricePerUnitCents;
  final Value<double?> purchasePackQty;
  final Value<String?> purchasePackUnit;
  final Value<int?> purchasePackPriceCents;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PriceOverridesCompanion({
    this.id = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.pricePerUnitCents = const Value.absent(),
    this.purchasePackQty = const Value.absent(),
    this.purchasePackUnit = const Value.absent(),
    this.purchasePackPriceCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceOverridesCompanion.insert({
    required String id,
    required String ingredientId,
    required int pricePerUnitCents,
    this.purchasePackQty = const Value.absent(),
    this.purchasePackUnit = const Value.absent(),
    this.purchasePackPriceCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ingredientId = Value(ingredientId),
       pricePerUnitCents = Value(pricePerUnitCents);
  static Insertable<PriceOverride> custom({
    Expression<String>? id,
    Expression<String>? ingredientId,
    Expression<int>? pricePerUnitCents,
    Expression<double>? purchasePackQty,
    Expression<String>? purchasePackUnit,
    Expression<int>? purchasePackPriceCents,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (pricePerUnitCents != null) 'price_per_unit_cents': pricePerUnitCents,
      if (purchasePackQty != null) 'purchase_pack_qty': purchasePackQty,
      if (purchasePackUnit != null) 'purchase_pack_unit': purchasePackUnit,
      if (purchasePackPriceCents != null)
        'purchase_pack_price_cents': purchasePackPriceCents,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceOverridesCompanion copyWith({
    Value<String>? id,
    Value<String>? ingredientId,
    Value<int>? pricePerUnitCents,
    Value<double?>? purchasePackQty,
    Value<String?>? purchasePackUnit,
    Value<int?>? purchasePackPriceCents,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PriceOverridesCompanion(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      pricePerUnitCents: pricePerUnitCents ?? this.pricePerUnitCents,
      purchasePackQty: purchasePackQty ?? this.purchasePackQty,
      purchasePackUnit: purchasePackUnit ?? this.purchasePackUnit,
      purchasePackPriceCents:
          purchasePackPriceCents ?? this.purchasePackPriceCents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (pricePerUnitCents.present) {
      map['price_per_unit_cents'] = Variable<int>(pricePerUnitCents.value);
    }
    if (purchasePackQty.present) {
      map['purchase_pack_qty'] = Variable<double>(purchasePackQty.value);
    }
    if (purchasePackUnit.present) {
      map['purchase_pack_unit'] = Variable<String>(purchasePackUnit.value);
    }
    if (purchasePackPriceCents.present) {
      map['purchase_pack_price_cents'] = Variable<int>(
        purchasePackPriceCents.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceOverridesCompanion(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('pricePerUnitCents: $pricePerUnitCents, ')
          ..write('purchasePackQty: $purchasePackQty, ')
          ..write('purchasePackUnit: $purchasePackUnit, ')
          ..write('purchasePackPriceCents: $purchasePackPriceCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $IngredientsTable ingredients = $IngredientsTable(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $UserTargetsTable userTargets = $UserTargetsTable(this);
  late final $PantryItemsTable pantryItems = $PantryItemsTable(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $PriceOverridesTable priceOverrides = $PriceOverridesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ingredients,
    recipes,
    userTargets,
    pantryItems,
    plans,
    priceOverrides,
  ];
}

typedef $$IngredientsTableCreateCompanionBuilder =
    IngredientsCompanion Function({
      required String id,
      required String name,
      required String unit,
      required double kcalPer100g,
      required double proteinPer100g,
      required double carbsPer100g,
      required double fatPer100g,
      required int pricePerUnitCents,
      required double purchasePackQty,
      required String purchasePackUnit,
      Value<int?> purchasePackPriceCents,
      required String aisle,
      required String tags,
      required String source,
      Value<DateTime?> lastVerifiedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$IngredientsTableUpdateCompanionBuilder =
    IngredientsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> unit,
      Value<double> kcalPer100g,
      Value<double> proteinPer100g,
      Value<double> carbsPer100g,
      Value<double> fatPer100g,
      Value<int> pricePerUnitCents,
      Value<double> purchasePackQty,
      Value<String> purchasePackUnit,
      Value<int?> purchasePackPriceCents,
      Value<String> aisle,
      Value<String> tags,
      Value<String> source,
      Value<DateTime?> lastVerifiedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$IngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcalPer100g => $composableBuilder(
    column: $table.kcalPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pricePerUnitCents => $composableBuilder(
    column: $table.pricePerUnitCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchasePackQty => $composableBuilder(
    column: $table.purchasePackQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchasePackUnit => $composableBuilder(
    column: $table.purchasePackUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purchasePackPriceCents => $composableBuilder(
    column: $table.purchasePackPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aisle => $composableBuilder(
    column: $table.aisle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcalPer100g => $composableBuilder(
    column: $table.kcalPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pricePerUnitCents => $composableBuilder(
    column: $table.pricePerUnitCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchasePackQty => $composableBuilder(
    column: $table.purchasePackQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchasePackUnit => $composableBuilder(
    column: $table.purchasePackUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purchasePackPriceCents => $composableBuilder(
    column: $table.purchasePackPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aisle => $composableBuilder(
    column: $table.aisle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get kcalPer100g => $composableBuilder(
    column: $table.kcalPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pricePerUnitCents => $composableBuilder(
    column: $table.pricePerUnitCents,
    builder: (column) => column,
  );

  GeneratedColumn<double> get purchasePackQty => $composableBuilder(
    column: $table.purchasePackQty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchasePackUnit => $composableBuilder(
    column: $table.purchasePackUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purchasePackPriceCents => $composableBuilder(
    column: $table.purchasePackPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aisle =>
      $composableBuilder(column: $table.aisle, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$IngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientsTable,
          Ingredient,
          $$IngredientsTableFilterComposer,
          $$IngredientsTableOrderingComposer,
          $$IngredientsTableAnnotationComposer,
          $$IngredientsTableCreateCompanionBuilder,
          $$IngredientsTableUpdateCompanionBuilder,
          (
            Ingredient,
            BaseReferences<_$AppDatabase, $IngredientsTable, Ingredient>,
          ),
          Ingredient,
          PrefetchHooks Function()
        > {
  $$IngredientsTableTableManager(_$AppDatabase db, $IngredientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> kcalPer100g = const Value.absent(),
                Value<double> proteinPer100g = const Value.absent(),
                Value<double> carbsPer100g = const Value.absent(),
                Value<double> fatPer100g = const Value.absent(),
                Value<int> pricePerUnitCents = const Value.absent(),
                Value<double> purchasePackQty = const Value.absent(),
                Value<String> purchasePackUnit = const Value.absent(),
                Value<int?> purchasePackPriceCents = const Value.absent(),
                Value<String> aisle = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientsCompanion(
                id: id,
                name: name,
                unit: unit,
                kcalPer100g: kcalPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                pricePerUnitCents: pricePerUnitCents,
                purchasePackQty: purchasePackQty,
                purchasePackUnit: purchasePackUnit,
                purchasePackPriceCents: purchasePackPriceCents,
                aisle: aisle,
                tags: tags,
                source: source,
                lastVerifiedAt: lastVerifiedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String unit,
                required double kcalPer100g,
                required double proteinPer100g,
                required double carbsPer100g,
                required double fatPer100g,
                required int pricePerUnitCents,
                required double purchasePackQty,
                required String purchasePackUnit,
                Value<int?> purchasePackPriceCents = const Value.absent(),
                required String aisle,
                required String tags,
                required String source,
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientsCompanion.insert(
                id: id,
                name: name,
                unit: unit,
                kcalPer100g: kcalPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                pricePerUnitCents: pricePerUnitCents,
                purchasePackQty: purchasePackQty,
                purchasePackUnit: purchasePackUnit,
                purchasePackPriceCents: purchasePackPriceCents,
                aisle: aisle,
                tags: tags,
                source: source,
                lastVerifiedAt: lastVerifiedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientsTable,
      Ingredient,
      $$IngredientsTableFilterComposer,
      $$IngredientsTableOrderingComposer,
      $$IngredientsTableAnnotationComposer,
      $$IngredientsTableCreateCompanionBuilder,
      $$IngredientsTableUpdateCompanionBuilder,
      (
        Ingredient,
        BaseReferences<_$AppDatabase, $IngredientsTable, Ingredient>,
      ),
      Ingredient,
      PrefetchHooks Function()
    >;
typedef $$RecipesTableCreateCompanionBuilder =
    RecipesCompanion Function({
      required String id,
      required String name,
      required int servings,
      required int timeMins,
      Value<String?> cuisine,
      required String dietFlags,
      required String items,
      required String steps,
      required double kcalPerServ,
      required double proteinPerServ,
      required double carbsPerServ,
      required double fatPerServ,
      required int costPerServCents,
      required String source,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$RecipesTableUpdateCompanionBuilder =
    RecipesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> servings,
      Value<int> timeMins,
      Value<String?> cuisine,
      Value<String> dietFlags,
      Value<String> items,
      Value<String> steps,
      Value<double> kcalPerServ,
      Value<double> proteinPerServ,
      Value<double> carbsPerServ,
      Value<double> fatPerServ,
      Value<int> costPerServCents,
      Value<String> source,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMins => $composableBuilder(
    column: $table.timeMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cuisine => $composableBuilder(
    column: $table.cuisine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dietFlags => $composableBuilder(
    column: $table.dietFlags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcalPerServ => $composableBuilder(
    column: $table.kcalPerServ,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinPerServ => $composableBuilder(
    column: $table.proteinPerServ,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsPerServ => $composableBuilder(
    column: $table.carbsPerServ,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatPerServ => $composableBuilder(
    column: $table.fatPerServ,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costPerServCents => $composableBuilder(
    column: $table.costPerServCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMins => $composableBuilder(
    column: $table.timeMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cuisine => $composableBuilder(
    column: $table.cuisine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dietFlags => $composableBuilder(
    column: $table.dietFlags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcalPerServ => $composableBuilder(
    column: $table.kcalPerServ,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinPerServ => $composableBuilder(
    column: $table.proteinPerServ,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsPerServ => $composableBuilder(
    column: $table.carbsPerServ,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatPerServ => $composableBuilder(
    column: $table.fatPerServ,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costPerServCents => $composableBuilder(
    column: $table.costPerServCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  GeneratedColumn<int> get timeMins =>
      $composableBuilder(column: $table.timeMins, builder: (column) => column);

  GeneratedColumn<String> get cuisine =>
      $composableBuilder(column: $table.cuisine, builder: (column) => column);

  GeneratedColumn<String> get dietFlags =>
      $composableBuilder(column: $table.dietFlags, builder: (column) => column);

  GeneratedColumn<String> get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<String> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<double> get kcalPerServ => $composableBuilder(
    column: $table.kcalPerServ,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinPerServ => $composableBuilder(
    column: $table.proteinPerServ,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsPerServ => $composableBuilder(
    column: $table.carbsPerServ,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatPerServ => $composableBuilder(
    column: $table.fatPerServ,
    builder: (column) => column,
  );

  GeneratedColumn<int> get costPerServCents => $composableBuilder(
    column: $table.costPerServCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          Recipe,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (Recipe, BaseReferences<_$AppDatabase, $RecipesTable, Recipe>),
          Recipe,
          PrefetchHooks Function()
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> servings = const Value.absent(),
                Value<int> timeMins = const Value.absent(),
                Value<String?> cuisine = const Value.absent(),
                Value<String> dietFlags = const Value.absent(),
                Value<String> items = const Value.absent(),
                Value<String> steps = const Value.absent(),
                Value<double> kcalPerServ = const Value.absent(),
                Value<double> proteinPerServ = const Value.absent(),
                Value<double> carbsPerServ = const Value.absent(),
                Value<double> fatPerServ = const Value.absent(),
                Value<int> costPerServCents = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                name: name,
                servings: servings,
                timeMins: timeMins,
                cuisine: cuisine,
                dietFlags: dietFlags,
                items: items,
                steps: steps,
                kcalPerServ: kcalPerServ,
                proteinPerServ: proteinPerServ,
                carbsPerServ: carbsPerServ,
                fatPerServ: fatPerServ,
                costPerServCents: costPerServCents,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int servings,
                required int timeMins,
                Value<String?> cuisine = const Value.absent(),
                required String dietFlags,
                required String items,
                required String steps,
                required double kcalPerServ,
                required double proteinPerServ,
                required double carbsPerServ,
                required double fatPerServ,
                required int costPerServCents,
                required String source,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                name: name,
                servings: servings,
                timeMins: timeMins,
                cuisine: cuisine,
                dietFlags: dietFlags,
                items: items,
                steps: steps,
                kcalPerServ: kcalPerServ,
                proteinPerServ: proteinPerServ,
                carbsPerServ: carbsPerServ,
                fatPerServ: fatPerServ,
                costPerServCents: costPerServCents,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      Recipe,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (Recipe, BaseReferences<_$AppDatabase, $RecipesTable, Recipe>),
      Recipe,
      PrefetchHooks Function()
    >;
typedef $$UserTargetsTableCreateCompanionBuilder =
    UserTargetsCompanion Function({
      required String id,
      required double kcal,
      required double proteinG,
      required double carbsG,
      required double fatG,
      Value<int?> budgetCents,
      required int mealsPerDay,
      Value<int?> timeCapMins,
      required String dietFlags,
      required String equipment,
      required String planningMode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserTargetsTableUpdateCompanionBuilder =
    UserTargetsCompanion Function({
      Value<String> id,
      Value<double> kcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> fatG,
      Value<int?> budgetCents,
      Value<int> mealsPerDay,
      Value<int?> timeCapMins,
      Value<String> dietFlags,
      Value<String> equipment,
      Value<String> planningMode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $UserTargetsTable> {
  $$UserTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get budgetCents => $composableBuilder(
    column: $table.budgetCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealsPerDay => $composableBuilder(
    column: $table.mealsPerDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeCapMins => $composableBuilder(
    column: $table.timeCapMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dietFlags => $composableBuilder(
    column: $table.dietFlags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planningMode => $composableBuilder(
    column: $table.planningMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserTargetsTable> {
  $$UserTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get budgetCents => $composableBuilder(
    column: $table.budgetCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealsPerDay => $composableBuilder(
    column: $table.mealsPerDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeCapMins => $composableBuilder(
    column: $table.timeCapMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dietFlags => $composableBuilder(
    column: $table.dietFlags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planningMode => $composableBuilder(
    column: $table.planningMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserTargetsTable> {
  $$UserTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<int> get budgetCents => $composableBuilder(
    column: $table.budgetCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mealsPerDay => $composableBuilder(
    column: $table.mealsPerDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeCapMins => $composableBuilder(
    column: $table.timeCapMins,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dietFlags =>
      $composableBuilder(column: $table.dietFlags, builder: (column) => column);

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get planningMode => $composableBuilder(
    column: $table.planningMode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserTargetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserTargetsTable,
          UserTarget,
          $$UserTargetsTableFilterComposer,
          $$UserTargetsTableOrderingComposer,
          $$UserTargetsTableAnnotationComposer,
          $$UserTargetsTableCreateCompanionBuilder,
          $$UserTargetsTableUpdateCompanionBuilder,
          (
            UserTarget,
            BaseReferences<_$AppDatabase, $UserTargetsTable, UserTarget>,
          ),
          UserTarget,
          PrefetchHooks Function()
        > {
  $$UserTargetsTableTableManager(_$AppDatabase db, $UserTargetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserTargetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<int?> budgetCents = const Value.absent(),
                Value<int> mealsPerDay = const Value.absent(),
                Value<int?> timeCapMins = const Value.absent(),
                Value<String> dietFlags = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<String> planningMode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserTargetsCompanion(
                id: id,
                kcal: kcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                budgetCents: budgetCents,
                mealsPerDay: mealsPerDay,
                timeCapMins: timeCapMins,
                dietFlags: dietFlags,
                equipment: equipment,
                planningMode: planningMode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required double kcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                Value<int?> budgetCents = const Value.absent(),
                required int mealsPerDay,
                Value<int?> timeCapMins = const Value.absent(),
                required String dietFlags,
                required String equipment,
                required String planningMode,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserTargetsCompanion.insert(
                id: id,
                kcal: kcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                budgetCents: budgetCents,
                mealsPerDay: mealsPerDay,
                timeCapMins: timeCapMins,
                dietFlags: dietFlags,
                equipment: equipment,
                planningMode: planningMode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserTargetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserTargetsTable,
      UserTarget,
      $$UserTargetsTableFilterComposer,
      $$UserTargetsTableOrderingComposer,
      $$UserTargetsTableAnnotationComposer,
      $$UserTargetsTableCreateCompanionBuilder,
      $$UserTargetsTableUpdateCompanionBuilder,
      (
        UserTarget,
        BaseReferences<_$AppDatabase, $UserTargetsTable, UserTarget>,
      ),
      UserTarget,
      PrefetchHooks Function()
    >;
typedef $$PantryItemsTableCreateCompanionBuilder =
    PantryItemsCompanion Function({
      required String id,
      required String ingredientId,
      required double qty,
      required String unit,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$PantryItemsTableUpdateCompanionBuilder =
    PantryItemsCompanion Function({
      Value<String> id,
      Value<String> ingredientId,
      Value<double> qty,
      Value<String> unit,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PantryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PantryItemsTable> {
  $$PantryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PantryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PantryItemsTable> {
  $$PantryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PantryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PantryItemsTable> {
  $$PantryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PantryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PantryItemsTable,
          PantryItem,
          $$PantryItemsTableFilterComposer,
          $$PantryItemsTableOrderingComposer,
          $$PantryItemsTableAnnotationComposer,
          $$PantryItemsTableCreateCompanionBuilder,
          $$PantryItemsTableUpdateCompanionBuilder,
          (
            PantryItem,
            BaseReferences<_$AppDatabase, $PantryItemsTable, PantryItem>,
          ),
          PantryItem,
          PrefetchHooks Function()
        > {
  $$PantryItemsTableTableManager(_$AppDatabase db, $PantryItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PantryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PantryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PantryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ingredientId = const Value.absent(),
                Value<double> qty = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PantryItemsCompanion(
                id: id,
                ingredientId: ingredientId,
                qty: qty,
                unit: unit,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ingredientId,
                required double qty,
                required String unit,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PantryItemsCompanion.insert(
                id: id,
                ingredientId: ingredientId,
                qty: qty,
                unit: unit,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PantryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PantryItemsTable,
      PantryItem,
      $$PantryItemsTableFilterComposer,
      $$PantryItemsTableOrderingComposer,
      $$PantryItemsTableAnnotationComposer,
      $$PantryItemsTableCreateCompanionBuilder,
      $$PantryItemsTableUpdateCompanionBuilder,
      (
        PantryItem,
        BaseReferences<_$AppDatabase, $PantryItemsTable, PantryItem>,
      ),
      PantryItem,
      PrefetchHooks Function()
    >;
typedef $$PlansTableCreateCompanionBuilder =
    PlansCompanion Function({
      required String id,
      required String name,
      required String userTargetsId,
      required String days,
      required double totalKcal,
      required double totalProteinG,
      required double totalCarbsG,
      required double totalFatG,
      required int totalCostCents,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$PlansTableUpdateCompanionBuilder =
    PlansCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> userTargetsId,
      Value<String> days,
      Value<double> totalKcal,
      Value<double> totalProteinG,
      Value<double> totalCarbsG,
      Value<double> totalFatG,
      Value<int> totalCostCents,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userTargetsId => $composableBuilder(
    column: $table.userTargetsId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalKcal => $composableBuilder(
    column: $table.totalKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalProteinG => $composableBuilder(
    column: $table.totalProteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCarbsG => $composableBuilder(
    column: $table.totalCarbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalFatG => $composableBuilder(
    column: $table.totalFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCostCents => $composableBuilder(
    column: $table.totalCostCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userTargetsId => $composableBuilder(
    column: $table.userTargetsId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalKcal => $composableBuilder(
    column: $table.totalKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalProteinG => $composableBuilder(
    column: $table.totalProteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCarbsG => $composableBuilder(
    column: $table.totalCarbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalFatG => $composableBuilder(
    column: $table.totalFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCostCents => $composableBuilder(
    column: $table.totalCostCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get userTargetsId => $composableBuilder(
    column: $table.userTargetsId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);

  GeneratedColumn<double> get totalKcal =>
      $composableBuilder(column: $table.totalKcal, builder: (column) => column);

  GeneratedColumn<double> get totalProteinG => $composableBuilder(
    column: $table.totalProteinG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalCarbsG => $composableBuilder(
    column: $table.totalCarbsG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalFatG =>
      $composableBuilder(column: $table.totalFatG, builder: (column) => column);

  GeneratedColumn<int> get totalCostCents => $composableBuilder(
    column: $table.totalCostCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlansTable,
          Plan,
          $$PlansTableFilterComposer,
          $$PlansTableOrderingComposer,
          $$PlansTableAnnotationComposer,
          $$PlansTableCreateCompanionBuilder,
          $$PlansTableUpdateCompanionBuilder,
          (Plan, BaseReferences<_$AppDatabase, $PlansTable, Plan>),
          Plan,
          PrefetchHooks Function()
        > {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> userTargetsId = const Value.absent(),
                Value<String> days = const Value.absent(),
                Value<double> totalKcal = const Value.absent(),
                Value<double> totalProteinG = const Value.absent(),
                Value<double> totalCarbsG = const Value.absent(),
                Value<double> totalFatG = const Value.absent(),
                Value<int> totalCostCents = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion(
                id: id,
                name: name,
                userTargetsId: userTargetsId,
                days: days,
                totalKcal: totalKcal,
                totalProteinG: totalProteinG,
                totalCarbsG: totalCarbsG,
                totalFatG: totalFatG,
                totalCostCents: totalCostCents,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String userTargetsId,
                required String days,
                required double totalKcal,
                required double totalProteinG,
                required double totalCarbsG,
                required double totalFatG,
                required int totalCostCents,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion.insert(
                id: id,
                name: name,
                userTargetsId: userTargetsId,
                days: days,
                totalKcal: totalKcal,
                totalProteinG: totalProteinG,
                totalCarbsG: totalCarbsG,
                totalFatG: totalFatG,
                totalCostCents: totalCostCents,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlansTable,
      Plan,
      $$PlansTableFilterComposer,
      $$PlansTableOrderingComposer,
      $$PlansTableAnnotationComposer,
      $$PlansTableCreateCompanionBuilder,
      $$PlansTableUpdateCompanionBuilder,
      (Plan, BaseReferences<_$AppDatabase, $PlansTable, Plan>),
      Plan,
      PrefetchHooks Function()
    >;
typedef $$PriceOverridesTableCreateCompanionBuilder =
    PriceOverridesCompanion Function({
      required String id,
      required String ingredientId,
      required int pricePerUnitCents,
      Value<double?> purchasePackQty,
      Value<String?> purchasePackUnit,
      Value<int?> purchasePackPriceCents,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$PriceOverridesTableUpdateCompanionBuilder =
    PriceOverridesCompanion Function({
      Value<String> id,
      Value<String> ingredientId,
      Value<int> pricePerUnitCents,
      Value<double?> purchasePackQty,
      Value<String?> purchasePackUnit,
      Value<int?> purchasePackPriceCents,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PriceOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $PriceOverridesTable> {
  $$PriceOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pricePerUnitCents => $composableBuilder(
    column: $table.pricePerUnitCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchasePackQty => $composableBuilder(
    column: $table.purchasePackQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchasePackUnit => $composableBuilder(
    column: $table.purchasePackUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purchasePackPriceCents => $composableBuilder(
    column: $table.purchasePackPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PriceOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceOverridesTable> {
  $$PriceOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pricePerUnitCents => $composableBuilder(
    column: $table.pricePerUnitCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchasePackQty => $composableBuilder(
    column: $table.purchasePackQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchasePackUnit => $composableBuilder(
    column: $table.purchasePackUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purchasePackPriceCents => $composableBuilder(
    column: $table.purchasePackPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PriceOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceOverridesTable> {
  $$PriceOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pricePerUnitCents => $composableBuilder(
    column: $table.pricePerUnitCents,
    builder: (column) => column,
  );

  GeneratedColumn<double> get purchasePackQty => $composableBuilder(
    column: $table.purchasePackQty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchasePackUnit => $composableBuilder(
    column: $table.purchasePackUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purchasePackPriceCents => $composableBuilder(
    column: $table.purchasePackPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PriceOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceOverridesTable,
          PriceOverride,
          $$PriceOverridesTableFilterComposer,
          $$PriceOverridesTableOrderingComposer,
          $$PriceOverridesTableAnnotationComposer,
          $$PriceOverridesTableCreateCompanionBuilder,
          $$PriceOverridesTableUpdateCompanionBuilder,
          (
            PriceOverride,
            BaseReferences<_$AppDatabase, $PriceOverridesTable, PriceOverride>,
          ),
          PriceOverride,
          PrefetchHooks Function()
        > {
  $$PriceOverridesTableTableManager(
    _$AppDatabase db,
    $PriceOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PriceOverridesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ingredientId = const Value.absent(),
                Value<int> pricePerUnitCents = const Value.absent(),
                Value<double?> purchasePackQty = const Value.absent(),
                Value<String?> purchasePackUnit = const Value.absent(),
                Value<int?> purchasePackPriceCents = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceOverridesCompanion(
                id: id,
                ingredientId: ingredientId,
                pricePerUnitCents: pricePerUnitCents,
                purchasePackQty: purchasePackQty,
                purchasePackUnit: purchasePackUnit,
                purchasePackPriceCents: purchasePackPriceCents,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ingredientId,
                required int pricePerUnitCents,
                Value<double?> purchasePackQty = const Value.absent(),
                Value<String?> purchasePackUnit = const Value.absent(),
                Value<int?> purchasePackPriceCents = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceOverridesCompanion.insert(
                id: id,
                ingredientId: ingredientId,
                pricePerUnitCents: pricePerUnitCents,
                purchasePackQty: purchasePackQty,
                purchasePackUnit: purchasePackUnit,
                purchasePackPriceCents: purchasePackPriceCents,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PriceOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceOverridesTable,
      PriceOverride,
      $$PriceOverridesTableFilterComposer,
      $$PriceOverridesTableOrderingComposer,
      $$PriceOverridesTableAnnotationComposer,
      $$PriceOverridesTableCreateCompanionBuilder,
      $$PriceOverridesTableUpdateCompanionBuilder,
      (
        PriceOverride,
        BaseReferences<_$AppDatabase, $PriceOverridesTable, PriceOverride>,
      ),
      PriceOverride,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db, _db.ingredients);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$UserTargetsTableTableManager get userTargets =>
      $$UserTargetsTableTableManager(_db, _db.userTargets);
  $$PantryItemsTableTableManager get pantryItems =>
      $$PantryItemsTableTableManager(_db, _db.pantryItems);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$PriceOverridesTableTableManager get priceOverrides =>
      $$PriceOverridesTableTableManager(_db, _db.priceOverrides);
}
