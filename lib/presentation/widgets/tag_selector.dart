import 'package:flutter/material.dart';

/// Multi-select chip widget for diet flags and equipment
class TagSelector extends StatelessWidget {
  const TagSelector({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.onChanged,
    this.maxSelection,
  });

  final String title;
  final Map<String, String> options; // key -> display name
  final Set<String> selectedOptions;
  final ValueChanged<Set<String>> onChanged;
  final int? maxSelection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final isSelected = selectedOptions.contains(entry.key);
            final canSelect = maxSelection == null || 
                selectedOptions.length < maxSelection! || 
                isSelected;

            return FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: canSelect
                  ? (selected) {
                      final newSelection = Set<String>.from(selectedOptions);
                      if (selected) {
                        newSelection.add(entry.key);
                      } else {
                        newSelection.remove(entry.key);
                      }
                      onChanged(newSelection);
                    }
                  : null,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }
}
