import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../providers/billing_providers.dart';
import '../../widgets/shopping_widgets/shopping_item_card.dart';
import '../../widgets/shopping_widgets/aisle_section.dart';
import '../../widgets/paywall_widget.dart';
import '../../../domain/entities/ingredient.dart';
import '../../../data/services/export_service.dart' as export_service;

/// Comprehensive shopping list page with aisle grouping and price editing
class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  Map<Aisle, bool> aisleExpansionState = {};
  List<ShoppingListItem> shoppingItems = [];
  bool showCheckedItems = true;

  @override
  void initState() {
    super.initState();
    _generateMockShoppingList();
  }

  void _generateMockShoppingList() {
    // Mock shopping list data (will be replaced with real data in Stage 3)
    final mockIngredients = [
      Ingredient(
        id: '1',
        name: 'Chicken Breast',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 165, proteinG: 31, carbsG: 0, fatG: 3.6),
        pricePerUnitCents: 899,
        purchasePack: const PurchasePack(qty: 1000, unit: Unit.grams, priceCents: 899),
        aisle: Aisle.meat,
        tags: ['high_protein', 'lean'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: '2',
        name: 'Broccoli',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 34, proteinG: 2.8, carbsG: 7, fatG: 0.4),
        pricePerUnitCents: 299,
        purchasePack: const PurchasePack(qty: 500, unit: Unit.grams, priceCents: 299),
        aisle: Aisle.produce,
        tags: ['vegetarian', 'high_volume'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: '3',
        name: 'Brown Rice',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 111, proteinG: 2.6, carbsG: 23, fatG: 0.9),
        pricePerUnitCents: 199,
        purchasePack: const PurchasePack(qty: 1000, unit: Unit.grams, priceCents: 199),
        aisle: Aisle.pantry,
        tags: ['cheap', 'bulk'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: '4',
        name: 'Greek Yogurt',
        unit: Unit.grams,
        macrosPer100g: const MacrosPerHundred(kcal: 59, proteinG: 10, carbsG: 3.6, fatG: 0.4),
        pricePerUnitCents: 549,
        purchasePack: const PurchasePack(qty: 500, unit: Unit.grams, priceCents: 549),
        aisle: Aisle.dairy,
        tags: ['high_protein'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: '5',
        name: 'Olive Oil',
        unit: Unit.milliliters,
        macrosPer100g: const MacrosPerHundred(kcal: 884, proteinG: 0, carbsG: 0, fatG: 100),
        pricePerUnitCents: 899,
        purchasePack: const PurchasePack(qty: 500, unit: Unit.milliliters, priceCents: 899),
        aisle: Aisle.condiments,
        tags: ['healthy_fat'],
        source: IngredientSource.seed,
      ),
    ];

    shoppingItems = mockIngredients.map((ingredient) {
      final neededQuantity = 300.0 + (ingredient.id.hashCode % 200);
      final purchaseQuantity = ingredient.purchasePack.qty.toDouble();
      final unitCost = ingredient.pricePerUnitCents;
      final totalCost = (purchaseQuantity * unitCost / 100).round();

      return ShoppingListItem(
        ingredient: ingredient,
        neededQuantity: neededQuantity,
        purchaseQuantity: purchaseQuantity,
        totalCostCents: totalCost,
        unitCostCents: unitCost,
        isChecked: false,
      );
    }).toList();

    // Initialize expansion state
    final aisles = shoppingItems.map((item) => item.ingredient.aisle).toSet();
    aisleExpansionState = {for (var aisle in aisles) aisle: true};
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItemsByAisle(shoppingItems);
    final totalCost = shoppingItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.totalCostCents / 100),
    );
    final checkedCount = shoppingItems.where((item) => item.isChecked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleCheckedItemsVisibility,
            icon: Icon(showCheckedItems ? Icons.visibility : Icons.visibility_off),
            tooltip: showCheckedItems ? 'Hide checked items' : 'Show checked items',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share_text',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share as Text'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export CSV (Pro)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Export PDF (Pro)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_checked',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Checked'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_prices',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reset Prices'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'share_text':
                  _shareShoppingListAsText();
                  break;
                case 'share_csv':
                  _shareShoppingListAsCSV();
                  break;
                case 'share_pdf':
                  _shareShoppingListAsPDF();
                  break;
                case 'clear_checked':
                  _clearCheckedItems();
                  break;
                case 'reset_prices':
                  _resetPrices();
                  break;
              }
            },
          ),
        ],
      ),
      body: shoppingItems.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Summary card
                _buildSummaryCard(totalCost, checkedCount, shoppingItems.length),
                
                // Shopping list
                Expanded(
                  child: ListView(
                    children: groupedItems.entries.map((entry) {
                      final aisle = entry.key;
                      final items = entry.value;
                      final filteredItems = showCheckedItems 
                          ? items 
                          : items.where((item) => !item.isChecked).toList();
                      
                      if (filteredItems.isEmpty) return const SizedBox.shrink();
                      
                      return AisleSection(
                        aisleName: aisle.value,
                        items: filteredItems,
                        isExpanded: aisleExpansionState[aisle] ?? true,
                        onToggleExpanded: () => _toggleAisleExpansion(aisle),
                        onItemQuantityChanged: (itemIndex, quantity) {
                          _updateItemQuantity(aisle, itemIndex, quantity);
                        },
                        onItemPriceChanged: (itemIndex, price) {
                          _updateItemPrice(aisle, itemIndex, price);
                        },
                        onItemCheckedChanged: (itemIndex, checked) {
                          _updateItemChecked(aisle, itemIndex, checked);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: checkedCount == shoppingItems.length
          ? FloatingActionButton.extended(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.check),
              label: const Text('Done Shopping'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Shopping List',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate a meal plan to create your shopping list.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Back to Plan'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalCost, int checkedCount, int totalCount) {
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Cost',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '\$${totalCost.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    '$checkedCount/$totalCount items',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Map<Aisle, List<ShoppingListItem>> _groupItemsByAisle(List<ShoppingListItem> items) {
    final grouped = <Aisle, List<ShoppingListItem>>{};
    for (final item in items) {
      final aisle = item.ingredient.aisle;
      grouped.putIfAbsent(aisle, () => []).add(item);
    }
    
    // Note: String aisle order defined but not used (enum version below is used)
    // Available for future string-based aisle sorting
    // const aisleOrder = ['produce', 'meat', 'dairy', 'frozen', 'pantry', 'condiments', 'bakery', 'household'];
    
    final sortedGrouped = <Aisle, List<ShoppingListItem>>{};
    final aisleOrderEnum = [
      Aisle.produce,
      Aisle.meat,
      Aisle.dairy,
      Aisle.pantry,
      Aisle.frozen,
      Aisle.condiments,
      Aisle.bakery,
      Aisle.household,
    ];
    
    for (final aisle in aisleOrderEnum) {
      if (grouped.containsKey(aisle)) {
        sortedGrouped[aisle] = grouped[aisle]!;
      }
    }
    
    // Add any remaining aisles
    for (final entry in grouped.entries) {
      if (!sortedGrouped.containsKey(entry.key)) {
        sortedGrouped[entry.key] = entry.value;
      }
    }
    
    return sortedGrouped;
  }

  void _toggleAisleExpansion(Aisle aisle) {
    setState(() {
      aisleExpansionState[aisle] = !(aisleExpansionState[aisle] ?? true);
    });
  }

  void _updateItemQuantity(Aisle aisle, int itemIndex, double quantity) {
    // TODO: Implement quantity update logic in Stage 3
    HapticFeedback.lightImpact();
  }

  void _updateItemPrice(Aisle aisle, int itemIndex, double price) {
    final groupedItems = _groupItemsByAisle(shoppingItems);
    final aisleItems = groupedItems[aisle] ?? [];
    
    if (itemIndex < aisleItems.length) {
      final item = aisleItems[itemIndex];
      final globalIndex = shoppingItems.indexOf(item);
      
      if (globalIndex >= 0) {
        setState(() {
          shoppingItems[globalIndex] = item.copyWith(
            totalCostCents: (price * 100).round(),
          );
        });
        
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${item.ingredient.name} price to \$${price.toStringAsFixed(2)}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _updateItemChecked(Aisle aisle, int itemIndex, bool checked) {
    final groupedItems = _groupItemsByAisle(shoppingItems);
    final aisleItems = groupedItems[aisle] ?? [];
    
    if (itemIndex < aisleItems.length) {
      final item = aisleItems[itemIndex];
      final globalIndex = shoppingItems.indexOf(item);
      
      if (globalIndex >= 0) {
        setState(() {
          shoppingItems[globalIndex] = item.copyWith(isChecked: checked);
        });
        
        HapticFeedback.lightImpact();
      }
    }
  }

  void _toggleCheckedItemsVisibility() {
    setState(() {
      showCheckedItems = !showCheckedItems;
    });
  }

  Future<void> _shareShoppingListAsText() async {
    try {
      final exportItems = shoppingItems.map((item) => export_service.ShoppingListItem(
        name: item.ingredient.name,
        quantity: item.neededQuantity,
        unit: item.ingredient.unit.value,
        aisle: item.ingredient.aisle,
        estimatedPrice: item.totalCostCents / 100,
        isCompleted: item.isChecked,
      )).toList();

      final content = export_service.ExportService.exportShoppingListAsText(exportItems);
      await export_service.ExportService.shareContent(
        content: content,
        filename: 'shopping_list.txt',
        subject: 'Shopping List',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share shopping list: $e')),
      );
    }
  }

  Future<void> _shareShoppingListAsCSV() async {
    final proStatus = await ref.read(proStatusProvider.future);
    
    if (!proStatus) {
      _showProRequiredDialog('CSV Export');
      return;
    }

    try {
      final exportItems = shoppingItems.map((item) => export_service.ShoppingListItem(
        name: item.ingredient.name,
        quantity: item.neededQuantity,
        unit: item.ingredient.unit.value,
        aisle: item.ingredient.aisle,
        estimatedPrice: item.totalCostCents / 100,
        isCompleted: item.isChecked,
      )).toList();

      final content = export_service.ExportService.exportShoppingListAsCSV(exportItems);
      await export_service.ExportService.shareContent(
        content: content,
        filename: 'shopping_list.csv',
        subject: 'Shopping List (CSV)',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }

  Future<void> _shareShoppingListAsPDF() async {
    final proStatus = await ref.read(proStatusProvider.future);
    
    if (!proStatus) {
      _showProRequiredDialog('PDF Export');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF export will be available in a future update'),
      ),
    );
  }

  void _showProRequiredDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pro Feature Required'),
        content: Text('$feature is a Pro feature. Upgrade to unlock this functionality.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showPaywall();
            },
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: const PaywallWidget(highlightFeature: 'export'),
      ),
    );
  }

  void _clearCheckedItems() {
    setState(() {
      shoppingItems = shoppingItems.where((item) => !item.isChecked).toList();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cleared checked items'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
  }

  void _resetPrices() {
    setState(() {
      shoppingItems = shoppingItems.map((item) {
        return item.copyWith(
          totalCostCents: item.ingredient.purchasePack.priceCents ?? item.totalCostCents,
        );
      }).toList();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset all prices to defaults'),
      ),
    );
  }
}
