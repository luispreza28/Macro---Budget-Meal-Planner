import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/locale_units_service.dart';

final localeUnitsSettingsProvider = FutureProvider<LocaleUnitsSettings>((ref) async {
  return ref.read(localeUnitsServiceProvider).get();
});

final localeProvider = FutureProvider<Locale?>((ref) async {
  final s = await ref.read(localeUnitsServiceProvider).get();
  if (s.localeCode == null) return null; // system default
  if (s.localeCode!.contains('_')) {
    final parts = s.localeCode!.split('_');
    return Locale(parts[0], parts[1]);
  }
  return Locale(s.localeCode!);
});

