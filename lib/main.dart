import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'domain/services/telemetry_settings_service.dart';
import 'domain/services/telemetry_service.dart';
import 'presentation/providers/telemetry_observer.dart';
import 'presentation/providers/accessibility_providers.dart';
import 'presentation/theme/high_contrast_theme.dart';

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
import 'presentation/providers/offline_daemon_provider.dart';
import 'presentation/widgets/offline_banner.dart';

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

    // Temporary container for early telemetry init and pre-app tasks
    final tempContainer = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
    );

    final telemetry = tempContainer.read(telemetryServiceProvider);
    await telemetry.init();

    // Patch global error handling in release only
    if (!kDebugMode) {
      FlutterError.onError = (details) {
        telemetry.recordError(details.exception, details.stack ?? StackTrace.current, reason: 'FlutterError');
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        telemetry.recordError(error, stack, reason: 'ZoneError');
        return true;
      };
    }

    await tempContainer.read(dataIntegrityInitializationProvider.future);

    // Initialize lifecycle management
    AppLifecycleManager.initialize(tempContainer);
    AppLogger.d('App lifecycle manager initialized');

    await telemetry.event('app_start');

    runApp(
      ProviderScope(
        observers: [TelemetryRiverpodObserver(telemetry)],
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          telemetryServiceProvider.overrideWithValue(telemetry),
        ],
        child: const MacroBudgetMealPlannerApp(),
      ),
    );

    // Schedule reminders after first frame using temp container
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tempContainer.read(reminderSchedulerProvider).rescheduleAll();
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
  void initState() {
    super.initState();
    // Start offline daemon once
    ref.read(offlineDaemonProvider);
  }
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
    final textScaleAsync = ref.watch(a11yTextScaleProvider);
    final a11yAsync = ref.watch(a11ySettingsProvider);

    final t = AppLocalizations.of(context);
    return MaterialApp.router(
      title: t?.appTitle ?? 'Macro + Budget Meal Planner',
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: ThemeMode.system,
      highContrastTheme: buildHighContrastLight(),
      highContrastDarkTheme: ThemeData.dark(useMaterial3: true),
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
        final preset = textScaleAsync.valueOrNull ?? 1.0;
        final mq = MediaQuery.of(context);
        final system = mq.textScaleFactor;
        final combined = (preset == 1.0) ? system : (system * preset);
        final a11y = a11yAsync.valueOrNull;
        final effectiveHighContrast = mq.highContrast || (a11y?.highContrast == true);
        final baseTheme = Theme.of(context);
        final txt = baseTheme.textTheme;
        TextTheme withMinSizes(TextTheme b) {
          return b.copyWith(
            bodyMedium: (b.bodyMedium ?? txt.bodyMedium)?.copyWith(fontSize: (b.bodyMedium?.fontSize ?? txt.bodyMedium?.fontSize ?? 16).clamp(16, double.infinity)),
            bodyLarge: (b.bodyLarge ?? txt.bodyLarge)?.copyWith(fontSize: (b.bodyLarge?.fontSize ?? txt.bodyLarge?.fontSize ?? 18).clamp(16, double.infinity)),
            titleMedium: (b.titleMedium ?? txt.titleMedium)?.copyWith(fontSize: (b.titleMedium?.fontSize ?? txt.titleMedium?.fontSize ?? 20).clamp(20, double.infinity)),
            titleLarge: (b.titleLarge ?? txt.titleLarge)?.copyWith(fontSize: (b.titleLarge?.fontSize ?? txt.titleLarge?.fontSize ?? 22).clamp(20, double.infinity)),
            labelLarge: (b.labelLarge ?? txt.labelLarge)?.copyWith(fontSize: (b.labelLarge?.fontSize ?? txt.labelLarge?.fontSize ?? 16).clamp(16, double.infinity)),
          );
        }
        final themedChild = Theme(
          data: baseTheme.copyWith(textTheme: withMinSizes(baseTheme.textTheme)),
          child: child ?? const SizedBox.shrink(),
        );
        final mediaWrapped = MediaQuery(
          data: mq.copyWith(
            textScaleFactor: combined.clamp(1.0, 1.6),
            highContrast: effectiveHighContrast,
          ),
          child: themedChild,
        );
        // Overlay a persistent offline banner at the top
        return Stack(
          children: [
            mediaWrapped,
            // Safe area to avoid status bar
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(top: true, bottom: false, child: OfflineBanner()),
            ),
          ],
        );
      },
    );
  }
}
