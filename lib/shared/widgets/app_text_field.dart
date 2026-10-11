import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

abstract final class AppInputStyles {
  // Keep the existing dense dropdown's content height and shared input padding.
  static const contentHeight = 24.0;
  static const horizontalPadding = 14.0;
  static const verticalPadding = 13.0;
  static const fieldHeight = contentHeight + verticalPadding * 2;
  static const valueFontSize = 14.0;
  static const hintFontSize = 12.0;
  static const value = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    fontSize: valueFontSize,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: contentHeight / valueFontSize,
    leadingDistribution: TextLeadingDistribution.even,
    color: AppColors.grey800,
  );
  static const label = TextStyle(fontSize: 14, color: AppColors.blue500);
  static const hint = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    fontSize: hintFontSize,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: contentHeight / hintFontSize,
    leadingDistribution: TextLeadingDistribution.even,
    color: AppColors.grey300,
  );
  static const strut = StrutStyle(
    fontFamily: AppTextStyles.fontFamily,
    fontSize: valueFontSize,
    fontWeight: FontWeight.w400,
    height: contentHeight / valueFontSize,
    forceStrutHeight: true,
  );
  static const radius = BorderRadius.all(Radius.circular(13));
  static const border = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: AppColors.blue500),
  );
  static const errorBorder = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: AppColors.red500),
  );
  static const padding = EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalPadding,
  );
  static const dropdownArrow = Icon(
    Icons.arrow_drop_down,
    size: contentHeight,
    color: AppColors.grey500,
  );
  // Match the existing Material dropdown's outlined-field suffix layout.
  static const dropdownEndPadding = 12.0;
  static const dropdownSuffix = Padding(
    padding: EdgeInsetsDirectional.only(end: dropdownEndPadding),
    child: dropdownArrow,
  );
  static const dropdownSuffixConstraints = BoxConstraints(
    minWidth: contentHeight + dropdownEndPadding,
    minHeight: contentHeight,
  );
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
          constraints: const BoxConstraints(minHeight: AppInputStyles.fieldHeight),
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
        strutStyle: AppInputStyles.strut,
        textAlignVertical: TextAlignVertical.center,
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
        strutStyle: AppInputStyles.strut,
        textAlignVertical: TextAlignVertical.center,
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
        hint: hint ??
            (decoration.hintText == null
                ? null
                : Text(decoration.hintText!,
                    style: AppInputStyles.hint,
                    strutStyle: AppInputStyles.strut,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
        icon: icon ?? AppInputStyles.dropdownArrow,
        iconSize: AppInputStyles.contentHeight,
        validator: validator,
        style: AppInputStyles.value,
        isExpanded: true,
        isDense: true,
        alignment: AlignmentDirectional.centerStart,
        padding: EdgeInsets.zero,
      ),
      requiredField: validator != null);
}

/// Shared input appearance for selectors that open a sheet instead of a menu.
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    this.value,
    required this.onTap,
    this.decoration = const AppInputDecoration(),
    super.key,
  });

  final String? value;
  final VoidCallback? onTap;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    final selected = value;
    return _withLabel(
        decoration,
        InkWell(
          onTap: onTap,
          borderRadius: AppInputStyles.radius,
          child: InputDecorator(
            decoration: decoration.copyWith(
              enabled: onTap != null,
              suffixIcon: AppInputStyles.dropdownSuffix,
              suffixIconConstraints: AppInputStyles.dropdownSuffixConstraints,
            ),
            // Let InputDecorator render the hint (decoration.hintText) only.
            // Rendering the hint string as a child Text as well duplicates
            // the visible string and breaks exact-text finders.
            isEmpty: selected == null,
            baseStyle: AppInputStyles.value,
            textAlignVertical: TextAlignVertical.center,
            child: selected == null
                ? null
                : ConstrainedBox(
                    constraints: const BoxConstraints(
                        minHeight: AppInputStyles.contentHeight),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      heightFactor: 1,
                      child: Text(
                        selected,
                        style: AppInputStyles.value,
                        strutStyle: AppInputStyles.strut,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
          ),
        ));
  }
}
