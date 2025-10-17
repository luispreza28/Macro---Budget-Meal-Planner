import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ingredient.dart' as domain;
import '../services/locale_units_service.dart';
import 'package:intl/intl.dart';

final unitsFormatterProvider = Provider<UnitsFormatter>((ref) => UnitsFormatter(ref));

class UnitsFormatter {
  UnitsFormatter(this.ref);
  final Ref ref;

  Future<String> formatQty({
    required double qty,
    required domain.Unit baseUnit,
    double? densityGPerMl,
    double? gramsPerPiece,
    double? mlPerPiece,
    int decimals = 1,
  }) async {
    final settings = await ref.read(localeUnitsServiceProvider).get();
    return formatQtySync(
      qty: qty,
      baseUnit: baseUnit,
      settings: settings,
      decimals: decimals,
    );
  }

  String formatQtySync({
    required double qty,
    required domain.Unit baseUnit,
    required LocaleUnitsSettings settings,
    int decimals = 1,
  }) {
    final sys = settings.unitSystem;

    if (baseUnit == domain.Unit.piece) {
      final v = _round(qty, decimals);
      return '$v pc';
    }

    if (baseUnit == domain.Unit.grams) {
      if (sys == UnitSystem.us && settings.showOzLb) {
        final lb = qty / 453.59237;
        if (lb >= 1) return '${_round(lb, 2)} lb';
        final oz = qty / 28.349523125;
        return '${_round(oz, 1)} oz';
      }
      return '${_round(qty, decimals)} g';
    }

    if (baseUnit == domain.Unit.milliliters) {
      if (sys == UnitSystem.us && settings.showFlOzCups) {
        final cups = qty / 240.0; // US kitchen cup approximation
        if (cups >= 1) return '${_round(cups, 2)} cup';
        final floz = qty / 29.5735295625;
        return '${_round(floz, 1)} fl oz';
      }
      return '${_round(qty, decimals)} ml';
    }

    return '${_round(qty, decimals)}';
  }

  Future<String> formatCurrency(num cents, {String? currencyCode}) async {
    final settings = await ref.read(localeUnitsServiceProvider).get();
    return formatCurrencySync(cents, currencyCode: currencyCode, settings: settings);
  }

  String formatCurrencySync(num cents, {String? currencyCode, required LocaleUnitsSettings settings}) {
    final loc = settings.localeCode ?? Intl.getCurrentLocale();
    final cur = currencyCode ?? settings.regionCurrency ?? 'USD';
    final f = NumberFormat.simpleCurrency(locale: loc, name: cur);
    final value = cents / 100.0;
    final s = f.format(value);
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Units] format currency cents=$cents -> $s (loc=$loc cur=$cur)');
    }
    return s;
  }

  double _round(double x, int decimals) {
    final p = pow(10, decimals).toDouble();
    return (x * p).round() / p;
  }
}

