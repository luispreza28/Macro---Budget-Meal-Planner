import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/ingredient.dart';
import '../../../domain/repositories/ingredient_repository.dart';
import '../../../domain/repositories/pantry_repository.dart';
import '../../../domain/services/unit_align.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/pantry_providers.dart';
import '../../providers/barcode_providers.dart';
import '../../providers/store_providers.dart';
import '../../../domain/services/barcode_mapping_service.dart';
import '../../../domain/services/store_profile_service.dart';
import '../../providers/shopping_list_providers.dart';

class BarcodeScanPage extends ConsumerStatefulWidget {
  const BarcodeScanPage({super.key});

  @override
  ConsumerState<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends ConsumerState<BarcodeScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanLock = false;
  String? _lastBarcode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture cap) async {
    if (_scanLock) return;
    final codes = cap.barcodes;
    if (codes.isEmpty) return;
    final value = codes.first.rawValue ?? '';
    final normalized = value.replaceAll(RegExp(r'\D'), '');
    if (normalized.isEmpty) return;
    if (_lastBarcode == normalized && _scanLock) return;

    _scanLock = true;
    _lastBarcode = normalized;
    try {
      await _controller.stop();
    } catch (_) {}

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ScanConfirmSheet(
        barcode: normalized,
        onDone: () async {
          if (!mounted) return;
          Navigator.of(ctx).pop();
        },
      ),
    );

    // Resume camera and unlock
    if (mounted) {
      try {
        await _controller.start();
      } catch (_) {}
      _scanLock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentAsync = ref.watch(recentScansProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: recentAsync.when(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (ctx, i) {
                      final s = list[i];
                      final label = s.label?.trim().isNotEmpty == true
                          ? s.label!
                          : '…${s.barcode.substring(s.barcode.length - 5)}';
                      return GestureDetector(
                        onLongPress: () async {
                          await ref
                              .read(barcodeMappingServiceProvider)
                              .removeRecent(s.id);
                          ref.invalidate(recentScansProvider);
                        },
                        child: ActionChip(
                          label: Text(label),
                          onPressed: () async {
                            // Open prefilled sheet
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (ctx) => ScanConfirmSheet(
                                barcode: s.barcode,
                                presetIngredientId: s.ingredientId,
                                presetLabel: s.label,
                                onDone: () => Navigator.of(ctx).pop(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: list.length,
                  ),
                );
              },
              error: (e, st) => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanConfirmSheet extends ConsumerStatefulWidget {
  const ScanConfirmSheet({
    super.key,
    required this.barcode,
    this.presetIngredientId,
    this.presetLabel,
    required this.onDone,
  });

  final String barcode;
  final String? presetIngredientId;
  final String? presetLabel;
  final VoidCallback onDone;

  @override
  ConsumerState<ScanConfirmSheet> createState() => _ScanConfirmSheetState();
}

class _ScanConfirmSheetState extends ConsumerState<ScanConfirmSheet> {
  final _nameCtrl = TextEditingController(text: 'Scanned item');
  final _qtyCtrl = TextEditingController(text: '1');
  final _packQtyCtrl = TextEditingController();
  final _packPriceCtrl = TextEditingController();
  final _ppuCtrl = TextEditingController();
  Unit _baseUnit = Unit.piece;
  Unit _qtyUnit = Unit.piece;
  Unit _packUnit = Unit.piece;
  Aisle _aisle = Aisle.pantry;
  String? _selectedIngredientId;
  bool _saveOverride = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.presetLabel != null && widget.presetLabel!.isNotEmpty) {
      _nameCtrl.text = widget.presetLabel!;
    }
    // If barcode maps to an ingredient, preselect and collapse stub section.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final map = await ref.read(barcodeMapProvider.future);
      final mapped = map[widget.barcode];
      setState(() {
        _selectedIngredientId = widget.presetIngredientId ?? mapped;
      });
      // If mapped, try to set units based on ingredient
      if (_selectedIngredientId != null) {
        final ing = await ref
            .read(ingredientRepositoryProvider)
            .getIngredientById(_selectedIngredientId!);
        if (ing != null) {
          setState(() {
            _baseUnit = ing.unit;
            _qtyUnit = ing.unit;
            _packUnit = ing.unit;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _packQtyCtrl.dispose();
    _packPriceCtrl.dispose();
    _ppuCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    if (_saving) return;
    setState(() => _saving = true);

    final ingredientRepo = ref.read(ingredientRepositoryProvider);
    final pantryRepo = ref.read(pantryRepositoryProvider);
    final storeSvc = ref.read(storeProfileServiceProvider);
    final barcodeSvc = ref.read(barcodeMappingServiceProvider);

    // Resolve ingredientId
    String? ingredientId = _selectedIngredientId;
    Ingredient? ing;

    if (ingredientId == null) {
      // Create stub
      final id = 'upc_${widget.barcode}';
      final name = _nameCtrl.text.trim().isEmpty
          ? 'Scanned item'
          : _nameCtrl.text.trim();

      // Compute price per unit cents from PPU field or pack
      int pricePerUnitCents = int.tryParse(_ppuCtrl.text.trim()) ?? 0;
      final packQty = double.tryParse(_packQtyCtrl.text.trim()) ?? 0;
      final packPrice = int.tryParse(_packPriceCtrl.text.trim());

      final stub = Ingredient(
        id: id,
        name: name,
        unit: _baseUnit,
        macrosPer100g:
            const MacrosPerHundred(kcal: 0, proteinG: 0, carbsG: 0, fatG: 0),
        pricePerUnitCents: pricePerUnitCents,
        purchasePack: PurchasePack(
          qty: packQty > 0 ? packQty : 0,
          unit: _packUnit,
          priceCents: packPrice,
        ),
        aisle: _aisle,
        tags: ['barcode:${widget.barcode}'],
        source: IngredientSource.manual,
        lastVerifiedAt: null,
      );
      await ingredientRepo.addIngredient(stub);
      ingredientId = id;
      ing = stub;
    } else {
      ing = await ingredientRepo.getIngredientById(ingredientId);
    }

    if (ingredientId == null || ing == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resolve ingredient.')),
        );
      }
      setState(() => _saving = false);
      return;
    }

    // Quantity to add
    final enteredQty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (enteredQty <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a quantity greater than 0.')),
        );
      }
      setState(() => _saving = false);
      return;
    }

    // Convert to base unit if possible per rules
    double qtyToAdd = enteredQty;
    Unit unitToAdd = _qtyUnit;
    final aligned = alignQty(
      qty: enteredQty,
      from: _qtyUnit,
      to: ing.unit,
      ing: ing,
      allowPiece: true,
      allowDensity: true,
    );
    if (aligned != null) {
      qtyToAdd = aligned;
      unitToAdd = ing.unit;
    } else if (_qtyUnit != ing.unit) {
      // Mismatch and cannot convert — warn and add in base with same numeric qty
      qtyToAdd = enteredQty;
      unitToAdd = ing.unit;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Unit mismatch; added in base unit qty=$qtyToAdd ${ing.unit.name}')),
        );
      }
    } else {
      // Same unit
      unitToAdd = ing.unit;
    }

    // Add to pantry
    await pantryRepo.addOnHandDeltas([
      (ingredientId: ingredientId, qty: qtyToAdd, unit: unitToAdd),
    ]);

    // Optional: store price override if selected
    int? overrideCents;
    String? storeId;
    if (_saveOverride) {
      final selected = await storeSvc.getSelected();
      if (selected != null) {
        storeId = selected.id;
        // Prefer PPU field; else compute from pack if possible and same unit
        final ppu = int.tryParse(_ppuCtrl.text.trim());
        int? cents = ppu;
        if (cents == null) {
          final packQty = double.tryParse(_packQtyCtrl.text.trim()) ?? 0;
          final packPrice = int.tryParse(_packPriceCtrl.text.trim());
          if (packPrice != null && packQty > 0) {
            // Only if pack unit convertible to base
            final conv = alignQty(
              qty: packQty,
              from: _packUnit,
              to: ing.unit,
              ing: ing,
              allowPiece: true,
              allowDensity: true,
            );
            if (conv != null && conv > 0) {
              cents = (packPrice / conv).round();
            }
          }
        }
        if (cents != null) {
          overrideCents = cents;
          await storeSvc.upsertPriceOverride(
            storeId: storeId,
            ingredientId: ingredientId,
            cents: cents,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not compute price override for base unit.'),
              ),
            );
          }
        }
      }
    }

    // Save barcode mapping
    await barcodeSvc.upsert(widget.barcode, ingredientId);

    // Push recent
    final recent = RecentScan(
      id: 'scan_${DateTime.now().microsecondsSinceEpoch}',
      barcode: widget.barcode,
      ingredientId: ingredientId,
      label: _nameCtrl.text.trim(),
      at: DateTime.now(),
    );
    await barcodeSvc.pushRecent(recent);

    // Invalidate providers
    ref.invalidate(recentScansProvider);
    ref.invalidate(barcodeMapProvider);
    ref.invalidate(selectedStoreProvider);
    ref.invalidate(shoppingListItemsProvider);
    ref.invalidate(allPantryItemsProvider);

    // Snackbar with UNDO
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Added ${NumberFormat.compact().format(qtyToAdd)} ${ing.unit.name} ${ing.name} • Undo'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              // Undo pantry add
              try {
                await pantryRepo.useIngredientsFromPantry({
                  ingredientId!: qtyToAdd,
                });
              } catch (_) {}
              // Clear override if we just created it
              if (overrideCents != null && storeId != null) {
                await storeSvc.clearPriceOverride(
                  storeId: storeId,
                  ingredientId: ingredientId!,
                );
              }
              ref.invalidate(allPantryItemsProvider);
              ref.invalidate(shoppingListItemsProvider);
              ref.invalidate(selectedStoreProvider);
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    setState(() => _saving = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(allIngredientsProvider);
    final mappedAsync = ref.watch(barcodeMapProvider);
    final currency = NumberFormat.currency(symbol: '\$');
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Confirm Scan',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onDone,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Barcode: ${widget.barcode}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            // Match existing
            ingredientsAsync.when(
              data: (ings) {
                final mapped = mappedAsync.value ?? const {};
                final pre = _selectedIngredientId ?? mapped[widget.barcode];
                final items = ings
                    .map((e) => DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(e.name),
                        ))
                    .toList();
                return DropdownButtonFormField<String>(
                  value: pre,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Link to existing ingredient',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('— None —'),
                    ),
                    ...items,
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedIngredientId = val;
                    });
                  },
                );
              },
              error: (_, __) => const SizedBox.shrink(),
              loading: () => const LinearProgressIndicator(),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('Or create stub',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Unit>(
                    value: _baseUnit,
                    decoration: const InputDecoration(labelText: 'Base unit'),
                    items: Unit.values
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.name),
                            ))
                        .toList(),
                    onChanged: (u) {
                      if (u == null) return;
                      setState(() {
                        _baseUnit = u;
                        // Default qty unit to base
                        _qtyUnit = u;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Aisle>(
                    value: _aisle,
                    decoration: const InputDecoration(labelText: 'Aisle'),
                    items: Aisle.values
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text(a.name),
                            ))
                        .toList(),
                    onChanged: (a) {
                      if (a == null) return;
                      setState(() => _aisle = a);
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text('Purchase pack (optional)',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _packQtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Pack qty'),
                    onChanged: (_) => _maybeComputePPU(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<Unit>(
                    value: _packUnit,
                    items: Unit.values
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.name),
                            ))
                        .toList(),
                    onChanged: (u) {
                      if (u == null) return;
                      setState(() => _packUnit = u);
                      _maybeComputePPU();
                    },
                    decoration: const InputDecoration(labelText: 'Pack unit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _packPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Pack price (cents)',
                        hintText: currency.format(0)),
                    onChanged: (_) => _maybeComputePPU(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Add to Pantry row
            Text('Add to Pantry',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<Unit>(
                    value: _qtyUnit,
                    items: Unit.values
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.name),
                            ))
                        .toList(),
                    onChanged: (u) {
                      if (u == null) return;
                      setState(() => _qtyUnit = u);
                    },
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Store price override
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Save price override for store'),
                    value: _saveOverride,
                    onChanged: (v) => setState(() => _saveOverride = v),
                  ),
                ),
              ],
            ),
            if (_saveOverride) ...[
              TextField(
                controller: _ppuCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Price per base unit (cents)'),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _handleAdd,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add to Pantry'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () async {
                    // Save mapping only
                    final ingId = _selectedIngredientId;
                    if (ingId != null) {
                      await ref
                          .read(barcodeMappingServiceProvider)
                          .upsert(widget.barcode, ingId);
                      ref.invalidate(barcodeMapProvider);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mapping saved.')),
                        );
                      }
                    }
                  },
                  child: const Text('Save Mapping'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _maybeComputePPU() {
    // If base == pack unit and price present, compute simple ppu
    final packQty = double.tryParse(_packQtyCtrl.text.trim()) ?? 0;
    final priceCents = int.tryParse(_packPriceCtrl.text.trim() == ''
        ? '0'
        : _packPriceCtrl.text.trim());
    if (priceCents == null || priceCents <= 0 || packQty <= 0) return;
    if (_packUnit == _baseUnit) {
      final ppu = (priceCents / packQty).round();
      _ppuCtrl.text = ppu.toString();
      setState(() {});
    }
  }
}

