import 'package:flutter/material.dart';
import '../../core/constants/expense_categories.dart';
import 'app_text_field.dart';

class ExpenseCategoryMultiSelect extends StatelessWidget {
  const ExpenseCategoryMultiSelect({required this.onChanged, super.key});
  final ValueChanged<List<String>> onChanged;
  @override
  Widget build(BuildContext context) => FormField<List<String>>(
        initialValue: const [],
        validator: (value) => value == null || value.isEmpty
            ? 'Choose at least one expense category'
            : null,
        builder: (field) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppInputLabel('Allowed Expense Categories',
              requiredField: true),
          const SizedBox(height: 8),
          MenuAnchor(
              menuChildren: [
                for (final category in expenseCategories)
                  CheckboxMenuButton(
                      value: field.value!.contains(category),
                      closeOnActivate: false,
                      onChanged: (checked) {
                        final selected = [...field.value!];
                        checked == true
                            ? selected.add(category)
                            : selected.remove(category);
                        field.didChange(selected);
                        onChanged(List.unmodifiable(selected));
                      },
                      child: Text(category)),
              ],
              builder: (context, controller, child) => InkWell(
                  onTap: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  borderRadius: BorderRadius.circular(13),
                  child: InputDecorator(
                      decoration: AppInputDecoration(
                          errorText: field.errorText,
                          suffixIcon: const Icon(Icons.keyboard_arrow_down)),
                      child: Text(
                          field.value!.isEmpty
                              ? 'Choose one or more categories'
                              : field.value!.join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: field.value!.isEmpty
                              ? AppInputStyles.hint
                              : AppInputStyles.value)))),
        ]),
      );
}
