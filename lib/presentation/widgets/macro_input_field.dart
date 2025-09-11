import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Input field for macro values with label and unit
class MacroInputField extends StatelessWidget {
  const MacroInputField({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.suffix,
    this.helperText,
  });

  final String label;
  final String unit;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double? max;
  final String? suffix;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
          ],
          decoration: InputDecoration(
            suffixText: unit,
            helperText: helperText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (text) {
            final parsed = double.tryParse(text);
            if (parsed != null) {
              final clamped = parsed.clamp(min, max ?? double.infinity);
              onChanged(clamped);
            }
          },
          validator: (text) {
            final parsed = double.tryParse(text ?? '');
            if (parsed == null) return 'Please enter a valid number';
            if (parsed < min) return 'Minimum value is $min';
            if (max != null && parsed > max!) return 'Maximum value is $max';
            return null;
          },
        ),
        if (suffix != null) ...[
          const SizedBox(height: 4),
          Text(
            suffix!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
