import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/meal_log_service.dart';

final mealLogProvider = FutureProvider<List<MealLogEntry>>(
  (ref) async => ref.read(mealLogServiceProvider).list(),
);

