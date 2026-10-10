import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

abstract final class AppInputStyles {
  static const value = TextStyle(fontSize: 14, color: AppColors.grey800);
  static const label = TextStyle(fontSize: 14, color: AppColors.blue500);
  static const hint = TextStyle(fontSize: 12, color: AppColors.grey300);
  static const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(13)),
    borderSide: BorderSide(color: AppColors.blue500),
  );
  static const errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(13)),
    borderSide: BorderSide(color: AppColors.red500),
  );
  static const padding = EdgeInsets.symmetric(horizontal: 14, vertical: 13);
}

class AppInputDecoration extends InputDecoration {
  const AppInputDecoration({
    String? labelText,
    String? hintText,
    super.errorText,
    super.counterText,
    super.prefixIcon,
    super.suffixIcon,
  })  : fieldLabel = labelText,
        super(
          hintText: hintText ?? 'Type here',
          hintStyle: AppInputStyles.hint,
          filled: true,
          fillColor: AppColors.inputFill,
          isDense: true,
          contentPadding: AppInputStyles.padding,
          border: AppInputStyles.border,
          enabledBorder: AppInputStyles.border,
          focusedBorder: AppInputStyles.border,
          disabledBorder: AppInputStyles.border,
          errorBorder: AppInputStyles.errorBorder,
          focusedErrorBorder: AppInputStyles.errorBorder,
        );

  final String? fieldLabel;
}

class AppInputLabel extends StatelessWidget {
  const AppInputLabel(this.text, {this.requiredField = false, super.key});
  final String text;
  final bool requiredField;

  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(
        style: AppInputStyles.label,
        children: [
          TextSpan(text: text),
          if (requiredField)
            const TextSpan(
                text: ' *',
                style: TextStyle(
                    color: AppColors.red500, fontWeight: FontWeight.w700)),
        ],
      ));
}

Widget _withLabel(InputDecoration decoration, Widget field,
    {bool requiredField = false}) {
  final label = decoration is AppInputDecoration ? decoration.fieldLabel : null;
  if (label == null) return field;
  return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppInputLabel(label, requiredField: requiredField),
        const SizedBox(height: 8),
        field,
      ]);
}

class AppFormField extends StatelessWidget {
  const AppFormField(
      {this.controller,
      this.focusNode,
      this.decoration = const AppInputDecoration(),
      this.validator,
      this.keyboardType,
      this.inputFormatters,
      this.enabled = true,
      this.obscureText = false,
      this.autocorrect = true,
      this.enableSuggestions = true,
      this.maxLength,
      this.maxLines = 1,
      this.textInputAction,
      this.onFieldSubmitted,
      super.key});
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled, obscureText, autocorrect, enableSuggestions;
  final int? maxLength, maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) => _withLabel(
      decoration,
      TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: decoration,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        enabled: enabled,
        obscureText: obscureText,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        maxLength: maxLength,
        maxLines: maxLines,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        style: AppInputStyles.value,
      ),
      requiredField: validator != null);
}

class AppInputField extends StatelessWidget {
  const AppInputField(
      {this.controller,
      this.decoration = const AppInputDecoration(),
      this.keyboardType,
      this.inputFormatters,
      this.enabled = true,
      this.obscureText = false,
      this.autocorrect = true,
      this.maxLength,
      this.onChanged,
      this.textCapitalization = TextCapitalization.none,
      super.key});
  final TextEditingController? controller;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled, obscureText, autocorrect;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => _withLabel(
      decoration,
      TextField(
        controller: controller,
        decoration: decoration,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        enabled: enabled,
        obscureText: obscureText,
        autocorrect: autocorrect,
        maxLength: maxLength,
        onChanged: onChanged,
        textCapitalization: textCapitalization,
        style: AppInputStyles.value,
      ));
}

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField(
      {this.value,
      this.initialValue,
      required this.items,
      required this.onChanged,
      this.decoration = const AppInputDecoration(),
      this.hint,
      this.icon,
      this.validator,
      super.key});
  final T? value, initialValue;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final Widget? hint, icon;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) => _withLabel(
      decoration,
      DropdownButtonFormField<T>(
        initialValue: initialValue ?? value,
        items: items,
        onChanged: onChanged,
        decoration: decoration,
        hint: hint,
        icon: icon,
        validator: validator,
        style: AppInputStyles.value,
        isExpanded: true,
      ),
      requiredField: validator != null);
}
