import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/services/telemetry_settings_service.dart';
import '../../../domain/services/telemetry_service.dart';

class TelemetrySettingsPage extends ConsumerStatefulWidget {
  const TelemetrySettingsPage({super.key});

  @override
  ConsumerState<TelemetrySettingsPage> createState() => _TelemetrySettingsPageState();
}

class _TelemetrySettingsPageState extends ConsumerState<TelemetrySettingsPage> {
  TelemetrySettings _settings = const TelemetrySettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(telemetrySettingsServiceProvider);
    final s = await svc.get();
    if (!mounted) return;
    setState(() { _settings = s; _loading = false; });
  }

  Future<void> _save() async {
    final svc = ref.read(telemetrySettingsServiceProvider);
    await svc.save(_settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telemetry settings updated')));
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.read(telemetryServiceProvider);
    final ringLen = telemetry.ringDump().length;
    final sessionId = telemetry.sessionId();
    final device = telemetry.deviceHint();

    return Scaffold(
      appBar: AppBar(title: const Text('Telemetry Settings')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Telemetry'),
            subtitle: const Text('Master switch for all telemetry'),
            value: _settings.enabled,
            onChanged: (v) => setState(() => _settings = TelemetrySettings(
              enabled: v,
              crashReporting: _settings.crashReporting,
              analytics: _settings.analytics,
              performance: _settings.performance,
              breadcrumbs: _settings.breadcrumbs,
            )),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Crash reporting'),
            value: _settings.crashReporting,
            onChanged: !_settings.enabled ? null : (v) => setState(() => _settings = TelemetrySettings(
              enabled: _settings.enabled,
              crashReporting: v,
              analytics: _settings.analytics,
              performance: _settings.performance,
              breadcrumbs: _settings.breadcrumbs,
            )),
          ),
          SwitchListTile(
            title: const Text('Analytics'),
            value: _settings.analytics,
            onChanged: !_settings.enabled ? null : (v) => setState(() => _settings = TelemetrySettings(
              enabled: _settings.enabled,
              crashReporting: _settings.crashReporting,
              analytics: v,
              performance: _settings.performance,
              breadcrumbs: _settings.breadcrumbs,
            )),
          ),
          SwitchListTile(
            title: const Text('Performance traces'),
            value: _settings.performance,
            onChanged: !_settings.enabled ? null : (v) => setState(() => _settings = TelemetrySettings(
              enabled: _settings.enabled,
              crashReporting: _settings.crashReporting,
              analytics: _settings.analytics,
              performance: v,
              breadcrumbs: _settings.breadcrumbs,
            )),
          ),
          SwitchListTile(
            title: const Text('Breadcrumbs'),
            value: _settings.breadcrumbs,
            onChanged: !_settings.enabled ? null : (v) => setState(() => _settings = TelemetrySettings(
              enabled: _settings.enabled,
              crashReporting: _settings.crashReporting,
              analytics: _settings.analytics,
              performance: _settings.performance,
              breadcrumbs: v,
            )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session: $sessionId'),
                Text('Device: $device'),
                Text('Log entries: $ringLen'),
              ],
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.start,
            children: [
              FilledButton.tonal(
                onPressed: () async {
                  try {
                    throw StateError('Test crash (user-initiated)');
                  } catch (e, st) {
                    await telemetry.recordError(e, st, reason: 'test_crash');
                  }
                },
                child: const Text('Send test crash'),
              ),
              OutlinedButton(
                onPressed: () => telemetry.event('test_event', params: {'ts': DateTime.now().millisecondsSinceEpoch}),
                child: const Text('Test event'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final bundle = await telemetry.buildLogBundle();
                  if (bundle != null && await bundle.exists()) {
                    await Share.shareXFiles([XFile(bundle.path)], text: 'Telemetry logs');
                  }
                },
                child: const Text('Export logs'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
