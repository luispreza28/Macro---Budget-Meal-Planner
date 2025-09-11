import 'package:flutter/material.dart';
import 'shopping_item_card.dart';

/// Section widget for grouping shopping items by aisle
class AisleSection extends StatelessWidget {
  const AisleSection({
    super.key,
    required this.aisleName,
    required this.items,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onItemQuantityChanged,
    required this.onItemPriceChanged,
    required this.onItemCheckedChanged,
  });

  final String aisleName;
  final List<ShoppingListItem> items;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final Function(int itemIndex, double quantity) onItemQuantityChanged;
  final Function(int itemIndex, double price) onItemPriceChanged;
  final Function(int itemIndex, bool checked) onItemCheckedChanged;

  @override
  Widget build(BuildContext context) {
    final checkedCount = items.where((item) => item.isChecked).length;
    final totalCost = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.totalCostCents / 100),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getAisleColor(aisleName).withOpacity(0.1),
                borderRadius: isExpanded 
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Aisle icon and name
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAisleColor(aisleName).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAisleIcon(aisleName),
                      color: _getAisleColor(aisleName),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getAisleDisplayName(aisleName),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getAisleColor(aisleName),
                          ),
                        ),
                        Text(
                          '$checkedCount/${items.length} items • \$${totalCost.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Progress indicator
                  if (checkedCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: CircularProgressIndicator(
                        value: checkedCount / items.length,
                        strokeWidth: 3,
                        backgroundColor: _getAisleColor(aisleName).withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(_getAisleColor(aisleName)),
                      ),
                    ),
                  
                  // Expand/collapse icon
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _getAisleColor(aisleName),
                  ),
                ],
              ),
            ),
          ),
          
          // Items list
          if (isExpanded)
            Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                
                return ShoppingItemCard(
                  item: item,
                  onQuantityChanged: (quantity) => onItemQuantityChanged(index, quantity),
                  onPriceChanged: (price) => onItemPriceChanged(index, price),
                  onCheckedChanged: (checked) => onItemCheckedChanged(index, checked),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Color _getAisleColor(String aisle) {
    switch (aisle.toLowerCase()) {
      case 'produce':
        return Colors.green;
      case 'meat':
        return Colors.red;
      case 'dairy':
        return Colors.blue;
      case 'pantry':
        return Colors.orange;
      case 'frozen':
        return Colors.cyan;
      case 'condiments':
        return Colors.purple;
      case 'bakery':
        return Colors.brown;
      case 'household':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getAisleIcon(String aisle) {
    switch (aisle.toLowerCase()) {
      case 'produce':
        return Icons.local_grocery_store;
      case 'meat':
        return Icons.set_meal;
      case 'dairy':
        return Icons.local_drink;
      case 'pantry':
        return Icons.kitchen;
      case 'frozen':
        return Icons.ac_unit;
      case 'condiments':
        return Icons.liquor;
      case 'bakery':
        return Icons.bakery_dining;
      case 'household':
        return Icons.home;
      default:
        return Icons.shopping_basket;
    }
  }

  String _getAisleDisplayName(String aisle) {
    switch (aisle.toLowerCase()) {
      case 'produce':
        return 'Produce';
      case 'meat':
        return 'Meat & Seafood';
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
        return aisle.split('_').map((word) => 
          word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }
}
