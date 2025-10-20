import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/ingredient.dart' as domain;
import '../../../domain/entities/recipe.dart' as domain;
import '../../../domain/services/ocr_service.dart';
import '../../../domain/services/ingredient_line_parser.dart' as parser;
import '../../providers/import/import_session_providers.dart';
import '../../providers/import/mapping_providers.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/database_providers.dart';
import '../../../domain/services/telemetry_service.dart';
import '../../router/app_router.dart';

class RecipeImportPage extends ConsumerStatefulWidget {
  const RecipeImportPage({super.key});

  @override
  ConsumerState<RecipeImportPage> createState() => _RecipeImportPageState();
}

class _RecipeImportPageState extends ConsumerState<RecipeImportPage> {
  final _titleCtrl = TextEditingController();
  final _servingsCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController();

  bool _busy = false;

  // Per-row selections
  final Map<int, domain.Ingredient?> _selected = {};
  final Map<int, TextEditingController> _qtyCtrls = {};
  final Map<int, domain.Unit> _unitSelections = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryServiceProvider).event('import_open');
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _servingsCtrl.dispose();
    _stepsCtrl.dispose();
    for (final c in _qtyCtrls.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(importSessionProvider);
    final ingsAsync = ref.watch(allIngredientsProvider);

    if (!_titleCtrl.text.trim().isNotEmpty && (session.title ?? '').isNotEmpty) {
      _titleCtrl.text = session.title ?? '';
    }
    if (!_servingsCtrl.text.trim().isNotEmpty && (session.servingsHint ?? 0) > 0) {
      _servingsCtrl.text = (session.servingsHint ?? 0).toString();
    }
    if (!_stepsCtrl.text.trim().isNotEmpty && session.steps.isNotEmpty) {
      _stepsCtrl.text = session.steps.join('\n');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Import Recipe')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _captureCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _pickGallery,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Pick PDF'),
                ),
                if (_busy) ...[
                  const SizedBox(width: 12),
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ],
            ),
          ),
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : (session.parsingDone
                    ? _buildParsedPreview(context, session, ingsAsync)
                    : _buildEmptyState()),
          ),
        ],
      ),
      bottomNavigationBar: session.parsingDone
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _busy ? null : () {
                        ref.read(importSessionProvider.notifier).reset();
                        setState(() {
                          _selected.clear();
                          _qtyCtrls.clear();
                          _unitSelections.clear();
                          _titleCtrl.clear();
                          _servingsCtrl.clear();
                          _stepsCtrl.clear();
                        });
                      },
                      child: const Text('Discard'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _busy ? null : () => _createDraftAndOpen(),
                      child: const Text('Create Draft'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Take a photo, pick an image or PDF to import.'),
    );
  }

  Widget _buildParsedPreview(BuildContext context, ImportSession session, AsyncValue<List<domain.Ingredient>> ingsAsync) {
    return ingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load ingredients: $e')),
      data: (catalog) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _servingsCtrl,
                    decoration: const InputDecoration(labelText: 'Servings'),
                    keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...List.generate(session.ingredients.length, (i) {
                final pi = session.ingredients[i];
                _qtyCtrls.putIfAbsent(i, () => TextEditingController(text: (pi.qty ?? 0).toString()));
                final selected = _selected[i];
                final unitSel = _unitSelections[i] ?? selected?.unit ?? domain.Unit.grams;
                _unitSelections[i] = unitSel;
                final mismatch = _unitMismatch(pi.unitToken, unitSel);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(pi.raw, style: Theme.of(context).textTheme.bodyMedium),
                            ),
                            if (mismatch)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Chip(
                                  label: const Text('unit mismatch'),
                                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _qtyCtrls[i],
                                decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<domain.Unit>(
                              value: unitSel,
                              onChanged: (u) { if (u==null) return; setState(()=> _unitSelections[i] = u); },
                              items: domain.Unit.values.map((u)=> DropdownMenuItem(value: u, child: Text(_unitLabel(u)))).toList(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FutureBuilder(
                                future: ref.read(ingredientSuggestionsProvider(pi.nameGuess).future),
                                builder: (context, snap) {
                                  final opts = snap.data ?? const [];
                                  return DropdownButton<domain.Ingredient>(
                                    isExpanded: true,
                                    value: selected ?? (opts.isNotEmpty ? opts.first.ingredient : null),
                                    hint: const Text('Match ingredient'),
                                    onChanged: (ing) { setState(()=> _selected[i] = ing); },
                                    items: opts.take(3).map((s) => DropdownMenuItem(
                                      value: s.ingredient,
                                      child: Text('${s.ingredient.name}  (${_unitLabel(s.ingredient.unit)})'),
                                    )).toList(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text('Steps', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              TextField(
                controller: _stepsCtrl,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Optional instructions...'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _captureCamera() async {
    final telemetry = ref.read(telemetryServiceProvider);
    setState(()=> _busy = true);
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.camera);
      if (img == null) { setState(()=> _busy = false); return; }
      final text = await ref.read(ocrServiceProvider).ocrImage(File(img.path));
      telemetry.event('import_ocr_ok', params: {'pages': 1});
      await _parseAndPopulate([text]);
    } catch (e, st) {
      await ref.read(telemetryServiceProvider).recordError(e, st, reason: 'import_camera');
    } finally { if (mounted) setState(()=> _busy = false); }
  }

  Future<void> _pickGallery() async {
    final telemetry = ref.read(telemetryServiceProvider);
    setState(()=> _busy = true);
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (img == null) { setState(()=> _busy = false); return; }
      final text = await ref.read(ocrServiceProvider).ocrImage(File(img.path));
      telemetry.event('import_ocr_ok', params: {'pages': 1});
      await _parseAndPopulate([text]);
    } catch (e, st) {
      await ref.read(telemetryServiceProvider).recordError(e, st, reason: 'import_gallery');
    } finally { if (mounted) setState(()=> _busy = false); }
  }

  Future<void> _pickPdf() async {
    final telemetry = ref.read(telemetryServiceProvider);
    setState(()=> _busy = true);
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (res == null || res.files.isEmpty) { setState(()=> _busy = false); return; }
      final file = File(res.files.single.path!);
      final pages = await ref.read(ocrServiceProvider).ocrPdf(file, maxPages: 4);
      telemetry.event('import_ocr_ok', params: {'pages': pages.length});
      await _parseAndPopulate(pages);
    } catch (e, st) {
      await ref.read(telemetryServiceProvider).recordError(e, st, reason: 'import_pdf');
    } finally { if (mounted) setState(()=> _busy = false); }
  }

  Future<void> _parseAndPopulate(List<String> pages) async {
    ref.read(importSessionProvider.notifier).setOCR(pages);
    final joined = pages.join('\n');
    final res = parser.IngredientLineParser.parse(joined);
    final parsed = res.ingredients
        .map((p) => ParsedIngredient(
              raw: p.raw,
              qty: p.qty,
              unitToken: p.unitToken,
              nameGuess: p.nameGuess,
              confidence: p.confidence,
            ))
        .toList();
    ref.read(importSessionProvider.notifier).setParse(
          title: res.title,
          servings: res.servingsHint,
          ings: parsed,
          steps: res.steps,
        );
    ref.read(telemetryServiceProvider).event('import_parse_ok', params: {'ings': parsed.length});
    setState(() {});
  }

  Future<void> _createDraftAndOpen() async {
    final session = ref.read(importSessionProvider);
    final title = _titleCtrl.text.trim().isEmpty ? (session.title ?? 'Imported Recipe') : _titleCtrl.text.trim();
    final servings = int.tryParse(_servingsCtrl.text.trim());
    final chosen = <domain.RecipeItem>[];
    for (var i = 0; i < session.ingredients.length; i++) {
      final sel = _selected[i];
      if (sel == null) continue;
      final qty = double.tryParse(_qtyCtrls[i]?.text.trim() ?? '') ?? (session.ingredients[i].qty ?? 0) ;
      final unit = sel.unit; // Always use ingredient base unit
      if (qty <= 0) continue;
      chosen.add(domain.RecipeItem(ingredientId: sel.id, qty: qty, unit: unit));
    }

    final draft = domain.Recipe(
      id: const Uuid().v4(),
      name: title,
      servings: servings ?? session.servingsHint ?? 2,
      timeMins: 15,
      cuisine: null,
      dietFlags: const [],
      items: chosen,
      steps: _stepsCtrl.text.trim().isEmpty ? session.steps : _stepsCtrl.text.split('\n'),
      macrosPerServ: const domain.MacrosPerServing(kcal: 0, proteinG: 0, carbsG: 0, fatG: 0),
      costPerServCents: 0,
      source: domain.RecipeSource.manual,
    );

    if (!mounted) return;
    ref.read(telemetryServiceProvider).event('import_create_draft');
    context.go(AppRouter.recipeDetails.replaceFirst(':id', draft.id), extra: draft);
  }

  String _unitLabel(domain.Unit u) {
    switch (u) {
      case domain.Unit.grams: return 'g';
      case domain.Unit.milliliters: return 'ml';
      case domain.Unit.piece: return 'pc';
    }
  }

  bool _unitMismatch(String? token, domain.Unit base) {
    if (token == null || token.isEmpty) return false;
    final fam = _tokenFamily(token);
    final baseFam = _baseFamily(base);
    return fam != baseFam;
  }

  String _tokenFamily(String t) {
    t = t.toLowerCase();
    if (['g','gram','grams','oz','ounce','ounces','lb','pound','pounds'].contains(t)) return 'mass';
    if (['ml','milliliter','milliliters','cup','cups','tbsp','tsp','teaspoon','tablespoon','fl oz'].contains(t)) return 'vol';
    if (['pc','piece','pieces'].contains(t)) return 'piece';
    return 'unknown';
    }

  String _baseFamily(domain.Unit u) {
    switch (u) {
      case domain.Unit.grams: return 'mass';
      case domain.Unit.milliliters: return 'vol';
      case domain.Unit.piece: return 'piece';
    }
  }
}

