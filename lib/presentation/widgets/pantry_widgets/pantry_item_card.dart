import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/ingredient.dart';
import '../../../domain/entities/pantry_item.dart';

/// Card for individual pantry item with quantity editing
class PantryItemCard extends StatefulWidget {
  const PantryItemCard({
    super.key,
    required this.pantryItem,
    required this.ingredient,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final PantryItem pantryItem;
  final Ingredient ingredient;
  final Function(double quantity) onQuantityChanged;
  final VoidCallback onRemove;

  @override
  State<PantryItemCard> createState() => _PantryItemCardState();
}

class _PantryItemCardState extends State<PantryItemCard> {
  late TextEditingController _quantityController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.pantryItem.qty.toStringAsFixed(
        widget.pantryItem.qty.truncateToDouble() == widget.pantryItem.qty ? 0 : 1,
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredient = widget.ingredient;
    final isExpiring = _isExpiringSoon();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Ingredient icon/image placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getAisleColor(ingredient.aisle).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIngredientIcon(ingredient.aisle),
                color: _getAisleColor(ingredient.aisle),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and expiration warning
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ingredient.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isExpiring)
                        Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 16,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Aisle and tags
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getAisleColor(ingredient.aisle).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getAisleDisplayName(ingredient.aisle),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getAisleColor(ingredient.aisle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (ingredient.tags.contains('expiring'))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Expiring Soon',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Quantity section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quantity (editable)
                GestureDetector(
                  onTap: () => setState(() => _isEditing = true),
                  child: _isEditing
                      ? SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                            ],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              border: const OutlineInputBorder(),
                              suffixText: ingredient.unit.value,
                            ),
                            onFieldSubmitted: (value) {
                              final quantity = double.tryParse(value);
                              if (quantity != null && quantity > 0) {
                                widget.onQuantityChanged(quantity);
                              }
                              setState(() => _isEditing = false);
                            },
                            onTapOutside: (_) {
                              final quantity = double.tryParse(_quantityController.text);
                              if (quantity != null && quantity > 0) {
                                widget.onQuantityChanged(quantity);
                              }
                              setState(() => _isEditing = false);
                            },
                            autofocus: true,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${widget.pantryItem.qty.toStringAsFixed(widget.pantryItem.qty.truncateToDouble() == widget.pantryItem.qty ? 0 : 1)} ${ingredient.unit}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit,
                                size: 14,
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                ),
                
                const SizedBox(height: 4),
                
                // Remove button
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isExpiringSoon() {
    // Mock expiration logic - in real app would check actual expiration dates
    return widget.ingredient.tags.contains('expiring') || 
           widget.ingredient.name.toLowerCase().contains('milk') ||
           widget.ingredient.name.toLowerCase().contains('bread');
  }

  Color _getAisleColor(Aisle aisle) {
    switch (aisle) {
      case Aisle.produce:
        return Colors.green;
      case Aisle.meat:
        return Colors.red;
      case Aisle.dairy:
        return Colors.blue;
      case Aisle.pantry:
        return Colors.orange;
      case Aisle.frozen:
        return Colors.cyan;
      case Aisle.condiments:
        return Colors.purple;
      case Aisle.bakery:
        return Colors.brown;
      case Aisle.household:
        return Colors.grey;
    }
  }

  IconData _getIngredientIcon(Aisle aisle) {
    switch (aisle) {
      case Aisle.produce:
        return Icons.local_grocery_store;
      case Aisle.meat:
        return Icons.set_meal;
      case Aisle.dairy:
        return Icons.local_drink;
      case Aisle.pantry:
        return Icons.kitchen;
      case Aisle.frozen:
        return Icons.ac_unit;
      case Aisle.condiments:
        return Icons.liquor;
      case Aisle.bakery:
        return Icons.bakery_dining;
      case Aisle.household:
        return Icons.home;
    }
  }

  String _getAisleDisplayName(Aisle aisle) {
    switch (aisle) {
      case Aisle.produce:
        return 'Produce';
      case Aisle.meat:
        return 'Meat';
      case Aisle.dairy:
        return 'Dairy';
      case Aisle.pantry:
        return 'Pantry';
      case Aisle.frozen:
        return 'Frozen';
      case Aisle.condiments:
        return 'Condiments';
      case Aisle.bakery:
        return 'Bakery';
      case Aisle.household:
        return 'Household';
    }
  }
}
