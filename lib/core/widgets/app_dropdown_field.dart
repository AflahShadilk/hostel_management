import 'package:flutter/material.dart';

class AppDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final FormFieldValidator<T>? validator;

  const AppDropdownField({
    super.key,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
    this.value,
    this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      validator: validator,
      // Expands to fill available width and prevents horizontal overflow.
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabelBuilder(item),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
