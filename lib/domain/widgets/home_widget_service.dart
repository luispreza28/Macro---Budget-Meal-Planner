import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../domain/entities/plan.dart';
import '../../presentation/providers/recipe_providers.dart';

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) => HomeWidgetService(ref));

class HomeWidgetService {
  HomeWidgetService(this.ref);
  final Ref ref;

  static const _widgetProvider = 'MealPlannerWidgetProvider';
  static const _widgetIOSName = 'MealPlannerWidget';

  Future<void> updateToday({required Plan plan}) async {
    final day = plan.days.isNotEmpty ? plan.days[0] : null;
    String t1 = '';
    String t2 = '';
    if (day != null) {
      if (day.meals.isNotEmpty) {
        final r1 = await ref.read(recipeByIdProvider(day.meals[0].recipeId).future);
        if (r1 != null) t1 = '${r1.name} • ${r1.macrosPerServ.kcal.toStringAsFixed(0)} kcal';
      }
      if (day.meals.length > 1) {
        final r2 = await ref.read(recipeByIdProvider(day.meals[1].recipeId).future);
        if (r2 != null) t2 = '${r2.name} • ${r2.macrosPerServ.kcal.toStringAsFixed(0)} kcal';
      }
    }
    await HomeWidget.saveWidgetData<String>('today_line1', t1);
    await HomeWidget.saveWidgetData<String>('today_line2', t2);
    await HomeWidget.updateWidget(name: _widgetProvider, iOSName: _widgetIOSName);
  }
}

