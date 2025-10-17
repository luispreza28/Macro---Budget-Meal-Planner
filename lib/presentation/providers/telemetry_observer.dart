import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/telemetry_service.dart';

class TelemetryRiverpodObserver extends ProviderObserver {
  final TelemetryService telemetry;
  TelemetryRiverpodObserver(this.telemetry);

  @override
  void providerDidFail(ProviderBase provider, Object error, StackTrace stackTrace, ProviderContainer container) {
    telemetry.log('[providerError] ${provider.name ?? provider.runtimeType} $error');
  }

  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue, Object? newValue, ProviderContainer container) {
    telemetry.log('[providerUpdate] ${provider.name ?? provider.runtimeType}');
  }
}
