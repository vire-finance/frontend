import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_text_field.dart';

/// The shared History-style search input used throughout the application.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar(
      {this.controller,
      this.hint = 'Search...',
      this.onChanged,
      this.onClear,
      super.key});
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 42,
      child: AppInputField(
        controller: controller,
        onChanged: onChanged,
        decoration: AppInputDecoration(
            hintText: hint,
            suffixIcon: onClear == null
                ? const Icon(Icons.search, color: AppColors.blue500)
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close, size: 18)),
                    const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.search, color: AppColors.blue500))
                  ])),
      ));
}
