import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../providers/store_providers.dart';
import '../../providers/scan_providers.dart';
import '../../router/app_router.dart';

class BatchScannerPage extends ConsumerStatefulWidget {
  const BatchScannerPage({super.key});

  @override
  ConsumerState<BatchScannerPage> createState() => _BatchScannerPageState();
}

class _BatchScannerPageState extends ConsumerState<BatchScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _paused = false;
  String? _selectedStoreId;
  final Map<String, DateTime> _recent = {};
  final List<String> _log = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture cap) async {
    if (_paused) return;
    if (cap.barcodes.isEmpty) return;
    final raw = cap.barcodes.first.rawValue ?? '';
    final ean = raw.replaceAll(RegExp(r'\D'), '');
    if (ean.isEmpty) return;

    final now = DateTime.now();
    final last = _recent[ean];
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return; // debounce same EAN within 2s
    }
    _recent[ean] = now;

    unawaited(ref.read(enqueueScanProvider((ean, storeId: _selectedStoreId)).future).then((_) {
      if (kDebugMode) debugPrint('[Scan] enqueue $ean store=${_selectedStoreId ?? '-'}');
      setState(() {
        _log.insert(0, '$ean — Added to queue');
        if (_log.length > 6) _log.removeLast();
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storeProfilesProvider);
    final selectedStore = ref.watch(selectedStoreProvider).value;
    _selectedStoreId ??= selectedStore?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Scanner'),
        actions: [
          TextButton(
            onPressed: () => context.push('/scanner/queue'),
            child: const Text('Open Queue'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: storesAsync.when(
                    data: (stores) {
                      return DropdownButtonFormField<String?>(
                        value: _selectedStoreId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Store'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('No Store')),
                          ...stores.map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.emoji ?? ''} ${s.name}'),
                            ),
                          )
                        ],
                        onChanged: (v) => setState(() => _selectedStoreId = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Stores unavailable: $e'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _paused ? 'Resume' : 'Pause',
                  onPressed: () async {
                    setState(() => _paused = !_paused);
                    if (_paused) {
                      await _controller.stop();
                    } else {
                      await _controller.start();
                    }
                  },
                  icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                if (_log.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _log.take(5).map((e) => Text(e)).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/scanner/queue'),
                  child: const Text('Open Queue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

