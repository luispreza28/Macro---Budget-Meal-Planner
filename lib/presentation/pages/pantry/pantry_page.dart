import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../providers/pantry_providers.dart';
// import '../../providers/ingredient_providers.dart';
import '../../widgets/pantry_widgets/pantry_item_card.dart';
import '../../widgets/pantry_widgets/add_pantry_item_dialog.dart';
import '../../widgets/pro_feature_gate.dart';
import '../../../domain/entities/ingredient.dart';
import '../../../domain/entities/pantry_item.dart';

/// Comprehensive pantry management page (Pro feature)
class PantryPage extends ConsumerStatefulWidget {
  const PantryPage({super.key});

  @override
  ConsumerState<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends ConsumerState<PantryPage> {
  String _searchQuery = '';
  String _selectedAisle = 'all';
  bool _showExpiringOnly = false;
  List<PantryItem> _mockPantryItems = [];
  List<Ingredient> _mockIngredients = [];

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock ingredients data
    _mockIngredients = [
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
        id: '3',
        name: 'Olive Oil',
        unit: Unit.milliliters,
        macrosPer100g: const MacrosPerHundred(kcal: 884, proteinG: 0, carbsG: 0, fatG: 100),
        pricePerUnitCents: 899,
        purchasePack: const PurchasePack(qty: 500, unit: Unit.milliliters, priceCents: 899),
        aisle: Aisle.condiments,
        tags: ['healthy_fat'],
        source: IngredientSource.seed,
      ),
      Ingredient(
        id: '4',
        name: 'Milk',
        unit: Unit.milliliters,
        macrosPer100g: const MacrosPerHundred(kcal: 42, proteinG: 3.4, carbsG: 5, fatG: 1),
        pricePerUnitCents: 399,
        purchasePack: const PurchasePack(qty: 1000, unit: Unit.milliliters, priceCents: 399),
        aisle: Aisle.dairy,
        tags: ['expiring'],
        source: IngredientSource.seed,
      ),
    ];

    // Mock pantry items
    _mockPantryItems = [
      PantryItem(
        id: 'pantry_1',
        ingredientId: '1',
        qty: 500,
        unit: Unit.grams,
        addedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      PantryItem(
        id: 'pantry_2',
        ingredientId: '2',
        qty: 800,
        unit: Unit.grams,
        addedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      PantryItem(
        id: 'pantry_3',
        ingredientId: '4',
        qty: 250,
        unit: Unit.milliliters,
        addedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Pantry'),
            const SizedBox(width: 8),
            const ProBadge(),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ProFeatureGate(
        featureName: 'pantry',
        child: _buildPantryContent(context),
      ),
    );
  }

  Widget _buildPantryContent(BuildContext context) {
    final filteredItems = _getFilteredPantryItems();
    final totalItems = _mockPantryItems.length;
    final expiringItems = _getExpiringItemsCount();
    final totalValue = _calculateTotalValue();

    return Column(
        children: [
          // Action bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pantry-first planning saves money by using items you already have',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Item',
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'clear_expired',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep),
                          SizedBox(width: 8),
                          Text('Clear Expired'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text('Export List'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'clear_expired':
                        _clearExpiredItems();
                        break;
                      case 'export':
                        _exportPantryList();
                        break;
                    }
                  },
                ),
              ],
            ),
          ),

          // Summary cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Items',
                    value: totalItems.toString(),
                    icon: Icons.kitchen,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Expiring Soon',
                    value: expiringItems.toString(),
                    icon: Icons.warning,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Value',
                    value: '\$${totalValue.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filters
          _buildFilters(),

          const SizedBox(height: 8),

          // Pantry items list
          Expanded(
            child: filteredItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final pantryItem = filteredItems[index];
                      final ingredient = _getIngredientById(pantryItem.ingredientId);
                      
                      if (ingredient == null) return const SizedBox.shrink();
                      
                      return PantryItemCard(
                        pantryItem: pantryItem,
                        ingredient: ingredient,
                        onQuantityChanged: (quantity) {
                          _updateItemQuantity(pantryItem, quantity);
                        },
                        onRemove: () {
                          _removeItem(pantryItem);
                        },
                      );
                    },
                  ),
          ),
        ],
      );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: const InputDecoration(
              hintText: 'Search pantry items...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedAisle == 'all',
                  onSelected: (selected) {
                    setState(() => _selectedAisle = 'all');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Expiring Soon'),
                  selected: _showExpiringOnly,
                  onSelected: (selected) {
                    setState(() => _showExpiringOnly = selected);
                  },
                ),
                const SizedBox(width: 8),
                ..._getAvailableAisles().map((aisle) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getAisleDisplayName(aisle)),
                      selected: _selectedAisle == aisle,
                      onSelected: (selected) {
                        setState(() => _selectedAisle = selected ? aisle : 'all');
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.kitchen_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedAisle != 'all' || _showExpiringOnly
                ? 'No items match your filters'
                : 'Your pantry is empty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedAisle != 'all' || _showExpiringOnly
                ? 'Try adjusting your search or filters'
                : 'Add ingredients you have on hand to get started',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  List<PantryItem> _getFilteredPantryItems() {
    var filtered = _mockPantryItems;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final ingredient = _getIngredientById(item.ingredientId);
        return ingredient?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      }).toList();
    }

    // Filter by aisle
    if (_selectedAisle != 'all') {
      filtered = filtered.where((item) {
        final ingredient = _getIngredientById(item.ingredientId);
        return ingredient?.aisle.name == _selectedAisle;
      }).toList();
    }

    // Filter by expiring items
    if (_showExpiringOnly) {
      filtered = filtered.where((item) {
        final ingredient = _getIngredientById(item.ingredientId);
        return ingredient?.tags.contains('expiring') ?? false;
      }).toList();
    }

    return filtered;
  }

  Ingredient? _getIngredientById(String id) {
    try {
      return _mockIngredients.firstWhere((ingredient) => ingredient.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> _getAvailableAisles() {
    return _mockPantryItems
        .map((item) => _getIngredientById(item.ingredientId)?.aisle.name)
        .where((aisle) => aisle != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  int _getExpiringItemsCount() {
    return _mockPantryItems.where((item) {
      final ingredient = _getIngredientById(item.ingredientId);
      return ingredient?.tags.contains('expiring') ?? false;
    }).length;
  }

  double _calculateTotalValue() {
    return _mockPantryItems.fold<double>(0.0, (total, item) {
      final ingredient = _getIngredientById(item.ingredientId);
      if (ingredient == null) return total;
      return total + (item.qty * ingredient.pricePerUnitCents / 100);
    });
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPantryItemDialog(
        availableIngredients: _mockIngredients,
        onAdd: (ingredient, quantity) {
          setState(() {
            _mockPantryItems.add(PantryItem(
              id: 'pantry_${DateTime.now().millisecondsSinceEpoch}',
              ingredientId: ingredient.id,
              qty: quantity,
              unit: ingredient.unit,
              addedAt: DateTime.now(),
            ));
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${ingredient.name} to pantry'),
            ),
          );
        },
      ),
    );
  }

  void _updateItemQuantity(PantryItem item, double quantity) {
    setState(() {
      final index = _mockPantryItems.indexOf(item);
      if (index >= 0) {
        _mockPantryItems[index] = PantryItem(
          id: item.id,
          ingredientId: item.ingredientId,
          qty: quantity,
          unit: item.unit,
          addedAt: item.addedAt,
        );
      }
    });
  }

  void _removeItem(PantryItem item) {
    setState(() {
      _mockPantryItems.remove(item);
    });
    
    final ingredient = _getIngredientById(item.ingredientId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${ingredient?.name ?? 'item'} from pantry'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _mockPantryItems.add(item);
            });
          },
        ),
      ),
    );
  }

  void _clearExpiredItems() {
    final expiredItems = _mockPantryItems.where((item) {
      final ingredient = _getIngredientById(item.ingredientId);
      return ingredient?.tags.contains('expiring') ?? false;
    }).toList();

    if (expiredItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expired items to clear')),
      );
      return;
    }

    setState(() {
      _mockPantryItems.removeWhere((item) {
        final ingredient = _getIngredientById(item.ingredientId);
        return ingredient?.tags.contains('expiring') ?? false;
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleared ${expiredItems.length} expired items'),
      ),
    );
  }

  void _exportPantryList() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality will be available in Stage 5'),
      ),
    );
  }

  String _getAisleDisplayName(String aisle) {
    switch (aisle.toLowerCase()) {
      case 'produce':
        return 'Produce';
      case 'meat':
        return 'Meat';
      case 'dairy':
        return 'Dairy';
      case 'pantry':
        return 'Pantry';
      case 'frozen':
        return 'Frozen';
      case 'condiments':
        return 'Condiments';
      case 'bakery':
        return 'Bakery';
      case 'household':
        return 'Household';
      default:
        return aisle;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}