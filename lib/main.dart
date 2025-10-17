import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/errors/error_handler.dart';
import 'core/utils/logger.dart';
import 'core/utils/app_lifecycle_manager.dart';
import 'core/utils/performance_monitor.dart';
import 'presentation/router/app_router.dart';
import 'presentation/providers/database_providers.dart';
import 'domain/services/reminder_scheduler.dart';
import 'l10n/l10n.dart';
import 'presentation/providers/locale_units_providers.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling
  ErrorHandler.initialize();
  AppLogger.i('Application starting up');

  // Initialize performance monitoring
  PerformanceMonitor.initialize();

  try {
    // Initialize SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();
    AppLogger.d('SharedPreferences initialized');

    // Create provider container
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
    );

    await container.read(dataIntegrityInitializationProvider.future);

    // Initialize lifecycle management
    AppLifecycleManager.initialize(container);
    AppLogger.d('App lifecycle manager initialized');

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const MacroBudgetMealPlannerApp(),
      ),
    );

    // Schedule reminders after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      container.read(reminderSchedulerProvider).rescheduleAll();
    });

    AppLogger.i('Application launched successfully');
  } catch (e, stackTrace) {
    AppLogger.wtf(
      'Failed to initialize application',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

class MacroBudgetMealPlannerApp extends ConsumerStatefulWidget {
  const MacroBudgetMealPlannerApp({super.key});

  @override
  ConsumerState<MacroBudgetMealPlannerApp> createState() =>
      _MacroBudgetMealPlannerAppState();
}

class _MacroBudgetMealPlannerAppState
    extends ConsumerState<MacroBudgetMealPlannerApp> {
  @override
  void dispose() {
    AppLifecycleManager.dispose();
    PerformanceMonitor.dispose();
    AppLogger.i('Application disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);
    final localeAsync = ref.watch(localeProvider);

    final t = AppLocalizations.of(context);
    return MaterialApp.router(
      title: t?.appTitle ?? 'Macro + Budget Meal Planner',
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeAsync.valueOrNull,
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
