import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/density_service.dart';

final densityCatalogProvider = FutureProvider((ref) => ref.read(densityServiceProvider).catalog());
final densityOverridesProvider = FutureProvider((ref) => ref.read(densityServiceProvider).overrides());

