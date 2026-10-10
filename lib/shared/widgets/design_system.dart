export 'app_search_bar.dart';
export 'app_text_field.dart'
    show
        AppFormField,
        AppInputField,
        AppDropdownField,
        AppInputDecoration,
        AppInputLabel,
        AppInputStyles;
import 'app_text_field.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// BUTTON

enum AppButtonType { primary, secondary, tertiary, ghost }

enum AppButtonSize { large, medium, small }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    final background = switch (type) {
      AppButtonType.primary => AppColors.blue300,
      AppButtonType.secondary => AppColors.blue50,
      AppButtonType.tertiary => AppColors.orange400,
      AppButtonType.ghost => Colors.transparent,
    };

    final foreground = switch (type) {
      AppButtonType.primary || AppButtonType.tertiary => AppColors.white,
      AppButtonType.secondary => AppColors.blue700,
      AppButtonType.ghost => AppColors.basicBlack,
    };

    final horizontalPadding = switch (size) {
      AppButtonSize.large => 24.0,
      AppButtonSize.medium => 20.0,
      AppButtonSize.small => 14.0,
    };

    final verticalPadding = switch (size) {
      AppButtonSize.large => 16.0,
      AppButtonSize.medium => 12.0,
      AppButtonSize.small => 8.0,
    };

    final labelStyle = switch (size) {
      AppButtonSize.large => AppTextStyles.l1.semiBold,
      AppButtonSize.medium => AppTextStyles.l2.semiBold,
      AppButtonSize.small => AppTextStyles.l3.medium,
    };

    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return AppColors.grey50;
          }
          if (states.contains(MaterialState.pressed)) {
            return type == AppButtonType.primary
                ? AppColors.blue500
                : background;
          }
          if (states.contains(MaterialState.hovered)) {
            return type == AppButtonType.primary
                ? AppColors.blue400
                : background;
          }
          return background;
        }),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return AppColors.grey300;
          return foreground;
        }),
        elevation: MaterialStateProperty.all(0),
        padding: MaterialStateProperty.all(
          EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: labelStyle.copyWith(
              color: isDisabled ? AppColors.grey300 : foreground,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(trailingIcon, size: 18),
          ],
        ],
      ),
    );
  }
}

// CHIPS

enum AppChipIconPosition { none, left, right, both }

class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.selected,
    this.onSelected,
    this.icon,
    this.iconPosition = AppChipIconPosition.none,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final AppChipIconPosition iconPosition;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.blue300 : AppColors.basicWhite;
    final foreground = selected ? AppColors.white : AppColors.grey700;
    final border = selected ? AppColors.blue300 : AppColors.grey100;

    Widget chipIcon() => Icon(icon, size: 16, color: foreground);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onSelected == null ? null : () => onSelected!(!selected),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null &&
                  (iconPosition == AppChipIconPosition.left ||
                      iconPosition == AppChipIconPosition.both)) ...[
                chipIcon(),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.l3.medium.copyWith(color: foreground),
              ),
              if (icon != null &&
                  (iconPosition == AppChipIconPosition.right ||
                      iconPosition == AppChipIconPosition.both)) ...[
                const SizedBox(width: 6),
                chipIcon(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// TEXT FIELD

class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.enabled = true,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppInputField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        enabled: enabled,
        decoration: AppInputDecoration(
            labelText: label,
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon));
  }
}

// SEARCH BAR

// DROPDOWN

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    super.key,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        icon: const Icon(Icons.keyboard_arrow_down),
        decoration: AppInputDecoration(hintText: hint));
  }
}

// CARD

enum AppCardTheme { white, purple }

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.theme = AppCardTheme.white,
    this.image,
    this.actions = const [],
    super.key,
  }) : assert(actions.length <= 2, 'AppCard supports up to two actions.');

  final Widget child;
  final AppCardTheme theme;
  final Widget? image;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final background = switch (theme) {
      AppCardTheme.white => AppColors.basicWhite,
      AppCardTheme.purple => AppColors.blue300,
    };

    final contentColor =
        theme == AppCardTheme.purple ? AppColors.white : AppColors.basicBlack;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DefaultTextStyle(
        style: AppTextStyles.p2.copyWith(color: contentColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image!,
              ),
              const SizedBox(height: 12),
            ],
            child,
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

// RADIO

class AppRadio<T> extends StatelessWidget {
  const AppRadio({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.label,
    super.key,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final radio = Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.blue300,
    );

    if (label == null) return radio;

    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          radio,
          Text(label!, style: AppTextStyles.p2),
        ],
      ),
    );
  }
}

// CHECKBOX

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    required this.value,
    required this.onChanged,
    this.label,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final checkbox = Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.blue300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );

    if (label == null) return checkbox;

    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          checkbox,
          Text(label!, style: AppTextStyles.p2),
        ],
      ),
    );
  }
}
