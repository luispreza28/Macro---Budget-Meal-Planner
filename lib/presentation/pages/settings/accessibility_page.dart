import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/services/accessibility_service.dart';
import '../../providers/accessibility_providers.dart';

class AccessibilityPage extends ConsumerWidget {
  const AccessibilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(a11ySettingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (s) {
          return FocusTraversalGroup(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Text Size', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _TextScaleSelector(current: s.textScale, onChanged: (v) async {
                  final next = A11ySettings(
                    textScale: v,
                    highContrast: s.highContrast,
                    reduceMotion: s.reduceMotion,
                    reducedHaptics: s.reducedHaptics,
                    showFocusRect: s.showFocusRect,
                  );
                  await ref.read(accessibilityServiceProvider).save(next);
                  ref.invalidate(a11ySettingsProvider);
                  ref.invalidate(a11yTextScaleProvider);
                }),

                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  title: const Text('High Contrast'),
                  subtitle: const Text('Increase color contrast'),
                  value: s.highContrast,
                  onChanged: (v) async {
                    final next = A11ySettings(
                      textScale: s.textScale,
                      highContrast: v,
                      reduceMotion: s.reduceMotion,
                      reducedHaptics: s.reducedHaptics,
                      showFocusRect: s.showFocusRect,
                    );
                    await ref.read(accessibilityServiceProvider).save(next);
                    ref.invalidate(a11ySettingsProvider);
                  },
                ),

                const Divider(height: 24),
                SwitchListTile.adaptive(
                  title: const Text('Reduce Motion'),
                  subtitle: const Text('Minimize animations'),
                  value: s.reduceMotion,
                  onChanged: (v) async {
                    final next = A11ySettings(
                      textScale: s.textScale,
                      highContrast: s.highContrast,
                      reduceMotion: v,
                      reducedHaptics: s.reducedHaptics,
                      showFocusRect: s.showFocusRect,
                    );
                    await ref.read(accessibilityServiceProvider).save(next);
                    ref.invalidate(a11ySettingsProvider);
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Reduced Haptics'),
                  subtitle: const Text('Gentler taps & vibrations'),
                  value: s.reducedHaptics,
                  onChanged: (v) async {
                    final next = A11ySettings(
                      textScale: s.textScale,
                      highContrast: s.highContrast,
                      reduceMotion: s.reduceMotion,
                      reducedHaptics: v,
                      showFocusRect: s.showFocusRect,
                    );
                    await ref.read(accessibilityServiceProvider).save(next);
                    ref.invalidate(a11ySettingsProvider);
                  },
                ),

                const Divider(height: 24),
                SwitchListTile.adaptive(
                  title: const Text('Show Focus Rect (dev)'),
                  subtitle: const Text('Draw outline around primary focus'),
                  value: s.showFocusRect,
                  onChanged: (v) async {
                    final next = A11ySettings(
                      textScale: s.textScale,
                      highContrast: s.highContrast,
                      reduceMotion: s.reduceMotion,
                      reducedHaptics: s.reducedHaptics,
                      showFocusRect: v,
                    );
                    await ref.read(accessibilityServiceProvider).save(next);
                    ref.invalidate(a11ySettingsProvider);
                  },
                ),

                const SizedBox(height: 24),
                _PreviewCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TextScaleSelector extends StatelessWidget {
  const _TextScaleSelector({required this.current, required this.onChanged});
  final TextScalePreset current;
  final ValueChanged<TextScalePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<TextScalePreset>(
          title: const Text('System'),
          value: TextScalePreset.system,
          groupValue: current,
          onChanged: (v) => onChanged(v ?? TextScalePreset.system),
        ),
        RadioListTile<TextScalePreset>(
          title: const Text('Large'),
          value: TextScalePreset.large,
          groupValue: current,
          onChanged: (v) => onChanged(v ?? TextScalePreset.large),
        ),
        RadioListTile<TextScalePreset>(
          title: const Text('Extra Large'),
          value: TextScalePreset.xlarge,
          groupValue: current,
          onChanged: (v) => onChanged(v ?? TextScalePreset.xlarge),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preview Title', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Body text preview at minimum 16sp.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(onPressed: () {}, child: const Text('Button')),
                const SizedBox(width: 12),
                Checkbox(value: true, onChanged: (_) {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

