import 'package:flutter/services.dart';

String formatIdrInput(int amount) {
  final digits = amount.toString();
  final grouped = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]}.');
  return 'IDR $grouped,00';
}

/// The backend accepts whole rupiah; the display always uses a fixed ,00 suffix.
int? parseIdrInput(String value) {
  final text =
      value.trim().replaceFirst(RegExp(r'^IDR\s*', caseSensitive: false), '');
  if (text.isEmpty) return null;
  final parts = text.split(',');
  if (parts.length > 2 ||
      (parts.length == 2 && !RegExp(r'^0{0,2}$').hasMatch(parts[1]))) {
    return null;
  }
  final integer = parts.first.replaceAll('.', '').replaceAll(' ', '');
  if (!RegExp(r'^\d+$').hasMatch(integer)) return null;
  return int.tryParse(integer);
}

class IdrInputFormatter extends TextInputFormatter {
  const IdrInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.composing.isCollapsed) return newValue;
    if (newValue.text.isEmpty) return const TextEditingValue();
    final integerPart = newValue.text
        .split(',')
        .first
        .replaceFirst(RegExp(r'^IDR\s*', caseSensitive: false), '')
        .replaceAll('.', '')
        .trim();
    if (integerPart.isEmpty) return const TextEditingValue();
    // Backspacing a thousands separator must still remove a digit, rather than
    // putting the separator back and trapping the caret in the same position.
    if (oldValue.selection.isCollapsed &&
        newValue.selection.isCollapsed &&
        oldValue.text.length == newValue.text.length + 1 &&
        parseIdrInput(oldValue.text) == parseIdrInput(newValue.text)) {
      final deletedAt = newValue.selection.extentOffset;
      if (deletedAt >= 4 &&
          deletedAt < oldValue.text.length &&
          oldValue.text[deletedAt] == '.') {
        final backspace = oldValue.selection.extentOffset > deletedAt;
        final digitAt = backspace ? deletedAt - 1 : deletedAt;
        if (digitAt >= 4 && digitAt < newValue.text.indexOf(',')) {
          final edited = newValue.text.replaceRange(digitAt, digitAt + 1, '');
          return formatEditUpdate(
              const TextEditingValue(),
              TextEditingValue(
                  text: edited,
                  selection: TextSelection.collapsed(offset: digitAt)));
        }
      }
    }
    final amount = parseIdrInput(newValue.text);
    if (amount == null || amount > 1000000000000000) return oldValue;
    final formatted = formatIdrInput(amount);
    final comma = formatted.indexOf(',');
    final sourceInteger = newValue.text.split(',').first;
    int mapOffset(int offset) {
      if (offset < 0) return comma;
      final sourceOffset = offset.clamp(0, sourceInteger.length);
      final digitsAfter = sourceInteger
          .substring(sourceOffset)
          .replaceAll(RegExp(r'\D'), '')
          .length;
      var remaining = digitsAfter;
      var target = comma;
      while (target > 4 && remaining > 0) {
        target--;
        if (RegExp(r'\d').hasMatch(formatted[target])) remaining--;
      }
      if (target > 4 && formatted[target - 1] == '.') target--;
      return target;
    }

    return TextEditingValue(
        text: formatted,
        selection: TextSelection(
          baseOffset: mapOffset(newValue.selection.baseOffset),
          extentOffset: mapOffset(newValue.selection.extentOffset),
        ));
  }
}
