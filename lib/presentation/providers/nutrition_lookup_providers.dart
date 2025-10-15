import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/nutrition_lookup_service.dart';

final nutritionSearchSourceProvider = StateProvider<String>((_) => 'fdc'); // 'fdc' | 'off'
final nutritionSearchResultsProvider = StateProvider<List<NutritionRecord>>((_) => const []);
final recentNutritionQueriesProvider = StateProvider<List<String>>((_) => const []);

