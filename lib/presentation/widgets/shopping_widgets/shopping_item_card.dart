import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/ingredient.dart';

/// Card for individual shopping list item with quantity and price editing
class ShoppingItemCard extends StatefulWidget {
  const ShoppingItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onCheckedChanged,
  });

  final ShoppingListItem item;
  final Function(double quantity) onQuantityChanged;
  final Function(double price) onPriceChanged;
  final Function(bool checked) onCheckedChanged;

  @override
  State<ShoppingItemCard> createState() => _ShoppingItemCardState();
}

class _ShoppingItemCardState extends State<ShoppingItemCard> {
  late TextEditingController _priceController;
  bool _isPriceEditing = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: (widget.item.totalCostCents / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredient = widget.item.ingredient;
    final totalCost = widget.item.totalCostCents / 100;
    final unitCost = widget.item.unitCostCents / 100;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: widget.item.isChecked,
              onChanged: (checked) => widget.onCheckedChanged(checked ?? false),
            ),
            
            const SizedBox(width: 12),
            
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and aisle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ingredient.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: widget.item.isChecked 
                                ? TextDecoration.lineThrough 
                                : null,
                            color: widget.item.isChecked
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getAisleColor(ingredient.aisle).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getAisleDisplayName(ingredient.aisle),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getAisleColor(ingredient.aisle),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Quantity and unit
                  Row(
                    children: [
                      Text(
                        'Need: ${widget.item.neededQuantity.toStringAsFixed(widget.item.neededQuantity.truncateToDouble() == widget.item.neededQuantity ? 0 : 1)} ${ingredient.unit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (widget.item.purchaseQuantity > widget.item.neededQuantity) ...[
                        const Text(' • '),
                        Text(
                          'Buy: ${widget.item.purchaseQuantity.toStringAsFixed(widget.item.purchaseQuantity.truncateToDouble() == widget.item.purchaseQuantity ? 0 : 1)} ${ingredient.unit}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // Leftover indicator
                  if (widget.item.leftoverQuantity > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Leftover: ${widget.item.leftoverQuantity.toStringAsFixed(widget.item.leftoverQuantity.truncateToDouble() == widget.item.leftoverQuantity ? 0 : 1)} ${ingredient.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Price section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Total price (editable)
                GestureDetector(
                  onTap: () => setState(() => _isPriceEditing = true),
                  child: _isPriceEditing
                      ? SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              border: OutlineInputBorder(),
                              prefixText: '\$',
                            ),
                            onFieldSubmitted: (value) {
                              final price = double.tryParse(value);
                              if (price != null) {
                                widget.onPriceChanged(price);
                              }
                              setState(() => _isPriceEditing = false);
                            },
                            onTapOutside: (_) {
                              final price = double.tryParse(_priceController.text);
                              if (price != null) {
                                widget.onPriceChanged(price);
                              }
                              setState(() => _isPriceEditing = false);
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
                                '\$${totalCost.toStringAsFixed(2)}',
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
                
                const SizedBox(height: 2),
                
                // Unit price
                Text(
                  '\$${unitCost.toStringAsFixed(2)}/${ingredient.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

/// Data class for shopping list items
class ShoppingListItem {
  const ShoppingListItem({
    required this.ingredient,
    required this.neededQuantity,
    required this.purchaseQuantity,
    required this.totalCostCents,
    required this.unitCostCents,
    this.isChecked = false,
  });

  final Ingredient ingredient;
  final double neededQuantity;
  final double purchaseQuantity;
  final int totalCostCents;
  final int unitCostCents;
  final bool isChecked;

  double get leftoverQuantity => purchaseQuantity - neededQuantity;

  ShoppingListItem copyWith({
    Ingredient? ingredient,
    double? neededQuantity,
    double? purchaseQuantity,
    int? totalCostCents,
    int? unitCostCents,
    bool? isChecked,
  }) {
    return ShoppingListItem(
      ingredient: ingredient ?? this.ingredient,
      neededQuantity: neededQuantity ?? this.neededQuantity,
      purchaseQuantity: purchaseQuantity ?? this.purchaseQuantity,
      totalCostCents: totalCostCents ?? this.totalCostCents,
      unitCostCents: unitCostCents ?? this.unitCostCents,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
