import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/ingredient.dart';

/// Dialog for adding new pantry items
class AddPantryItemDialog extends StatefulWidget {
  const AddPantryItemDialog({
    super.key,
    required this.availableIngredients,
    required this.onAdd,
  });

  final List<Ingredient> availableIngredients;
  final Function(Ingredient ingredient, double quantity) onAdd;

  @override
  State<AddPantryItemDialog> createState() => _AddPantryItemDialogState();
}

class _AddPantryItemDialogState extends State<AddPantryItemDialog> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  Ingredient? _selectedIngredient;
  List<Ingredient> _filteredIngredients = [];

  @override
  void initState() {
    super.initState();
    _filteredIngredients = widget.availableIngredients;
    _searchController.addListener(_filterIngredients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _filterIngredients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredIngredients = widget.availableIngredients
          .where((ingredient) =>
              ingredient.name.toLowerCase().contains(query) ||
              ingredient.aisle.value.toLowerCase().contains(query) ||
              ingredient.tags.any((tag) => tag.toLowerCase().contains(query)))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add to Pantry',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Search field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search ingredients...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Ingredients list
            Expanded(
              child: _filteredIngredients.isEmpty
                  ? const Center(
                      child: Text('No ingredients found'),
                    )
                  : ListView.builder(
                      itemCount: _filteredIngredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _filteredIngredients[index];
                        final isSelected = _selectedIngredient?.id == ingredient.id;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            selected: isSelected,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getAisleColor(ingredient.aisle).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getIngredientIcon(ingredient.aisle),
                                color: _getAisleColor(ingredient.aisle),
                                size: 20,
                              ),
                            ),
                            title: Text(ingredient.name),
                            subtitle: Row(
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
                                Text(
                                  '\$${(ingredient.pricePerUnitCents / 100).toStringAsFixed(2)}/${ingredient.unit}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedIngredient = ingredient;
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // Quantity input
            if (_selectedIngredient != null) ...[
              Text(
                'Quantity',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                      ],
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        suffixText: _selectedIngredient!.unit.value,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _canAdd() ? _addItem : null,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'Select an ingredient above to add it to your pantry.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canAdd() {
    if (_selectedIngredient == null) return false;
    final quantity = double.tryParse(_quantityController.text);
    return quantity != null && quantity > 0;
  }

  void _addItem() {
    if (_selectedIngredient != null && _canAdd()) {
      final quantity = double.parse(_quantityController.text);
      widget.onAdd(_selectedIngredient!, quantity);
      Navigator.of(context).pop();
    }
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
