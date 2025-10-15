import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/diet_allergen_prefs_service.dart';

final allergensPrefProvider = FutureProvider<List<String>>((ref) async =>
  ref.read(dietAllergenPrefsServiceProvider).allergens());

final strictModePrefProvider = FutureProvider<bool>((ref) async =>
  ref.read(dietAllergenPrefsServiceProvider).strictMode());

final dietFlagsPrefProvider = FutureProvider<List<String>>((ref) async =>
  ref.read(dietAllergenPrefsServiceProvider).dietFlags());

