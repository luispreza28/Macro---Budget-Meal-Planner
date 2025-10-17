import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/sync/auth_service.dart';
import '../../providers/cloud_sync_providers.dart';

class CloudSyncPage extends ConsumerWidget {
  const CloudSyncPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserProvider);
    final list = ref.watch(listBackupsProvider);
    final autoDaily = ref.watch(cloudAutoDailyProvider);
    final autoPlan = ref.watch(cloudAutoOnPlanSaveProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Sync & Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Auth section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud, size: 22),
                      const SizedBox(width: 8),
                      Text('Account', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  auth.when(
                    loading: () => const Text('Checking sign-in...'),
                    error: (e, _) => Text('Auth error: $e'),
                    data: (user) => Row(
                      children: [
                        Expanded(
                          child: Text(
                            user?.email ?? 'Guest',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (user == null)
                          FilledButton.icon(
                            onPressed: () async {
                              await ref.read(authServiceProvider).signInWithGoogle();
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('Sign in with Google'),
                          )
                        else
                          TextButton.icon(
                            onPressed: () async {
                              await ref.read(authServiceProvider).signOut();
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign out'),
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Backup section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.backup, size: 22),
                      const SizedBox(width: 8),
                      Text('Backups', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: auth.asData?.value == null
                            ? null
                            : () async {
                                final res = await ref.read(backupNowProvider.future);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res == null
                                            ? 'Backup failed'
                                            : 'Backup complete • ${res.records} records',
                                      ),
                                    ),
                                  );
                                  ref.invalidate(listBackupsProvider);
                                }
                              },
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Backup Now'),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  list.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) => Text('Failed to load: $e'),
                    data: (xs) => xs.isEmpty
                        ? const Text('No backups yet')
                        : Column(
                            children: [
                              for (final m in xs)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('${DateFormat.yMMMd().add_jm().format(m.createdAt)} · v${m.appVersion}')
                                      ,
                                  subtitle: Text('${m.records} records · ${m.sections.entries.map((e) => '${e.key}:${e.value}').take(4).join(', ')}'),
                                  trailing: TextButton(
                                    onPressed: () async {
                                      final ok = await ref.read(restoreFromManifestProvider(m.id).future);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(ok ? 'Restore complete' : 'Restore failed')),
                                        );
                                      }
                                    },
                                    child: const Text('Restore'),
                                  ),
                                )
                            ],
                          ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Auto-backup toggles
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 22),
                      const SizedBox(width: 8),
                      Text('Auto-backup', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<bool>(
                    future: ref.read(cloudAutoDailyProvider.future),
                    builder: (context, snap) {
                      final enabled = snap.data ?? true;
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Backup daily at first open'),
                        value: enabled,
                        onChanged: (v) async {
                          final sp = await SharedPreferences.getInstance();
                          await sp.setBool('cloud.auto.daily', v);
                          ref.invalidate(cloudAutoDailyProvider);
                        },
                      );
                    },
                  ),
                  FutureBuilder<bool>(
                    future: ref.read(cloudAutoOnPlanSaveProvider.future),
                    builder: (context, snap) {
                      final enabled = snap.data ?? true;
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Backup after saving a plan'),
                        value: enabled,
                        onChanged: (v) async {
                          final sp = await SharedPreferences.getInstance();
                          await sp.setBool('cloud.auto.onPlanSave', v);
                          ref.invalidate(cloudAutoOnPlanSaveProvider);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
