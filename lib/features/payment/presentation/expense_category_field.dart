import 'package:flutter/material.dart';

import '../../../shared/widgets/app_text_field.dart';
import '../data/payment_model.dart';

class ExpenseCategoryField extends StatelessWidget {
  const ExpenseCategoryField(
      {required this.value,
      required this.onChanged,
      this.categories = expenseCategories,
      super.key});
  final List<String> categories;
  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) => AppDropdownField<String>(
        key: ValueKey(categories.join('|') + (value ?? '')),
        initialValue: categories.contains(value) ? value : null,
        decoration: const AppInputDecoration(
            labelText: 'Expense Category',
            hintText: 'Choose an expense category'),
        items: [
          for (final category in categories)
            DropdownMenuItem(value: category, child: Text(category))
        ],
        onChanged: onChanged,
        validator: (value) => value == null || !categories.contains(value)
            ? 'Choose an expense category'
            : null,
      );
}
