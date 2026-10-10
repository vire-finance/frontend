import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/core/utils/money_formatter.dart';
import 'package:vire/shared/widgets/app_text_field.dart';

TextEditingValue edit(String text, [int? cursor]) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor ?? text.length));

void main() {
  const formatter = IdrInputFormatter();

  test(
      'IDR formatting round-trips whole rupiah without treating cents as digits',
      () {
    for (final amount in [0, 1, 50000, 1234567, 1000000000000000]) {
      expect(parseIdrInput(formatIdrInput(amount)), amount);
    }
    expect(formatIdrInput(1234567), 'IDR 1.234.567,00');
    expect(parseIdrInput('50000'), 50000);
    expect(parseIdrInput(''), isNull);
    expect(parseIdrInput('IDR 50.000,50'), isNull);
    expect(parseIdrInput('-500'), isNull);
  });

  test('typing appends digits before the fixed decimal suffix', () {
    var value = const TextEditingValue();
    for (final digit in '1234567'.split('')) {
      final cursor =
          value.selection.extentOffset < 0 ? 0 : value.selection.extentOffset;
      value = formatter.formatEditUpdate(value,
          edit(value.text.replaceRange(cursor, cursor, digit), cursor + 1));
    }
    expect(value.text, 'IDR 1.234.567,00');
    expect(value.selection.extentOffset, value.text.indexOf(','));
  });

  test('paste, clear, and middle edits preserve the intended amount', () {
    final pasted = formatter.formatEditUpdate(
        const TextEditingValue(), edit('IDR 50.000,00'));
    expect(parseIdrInput(pasted.text), 50000);
    expect(
        formatter.formatEditUpdate(pasted, const TextEditingValue()).text, '');
    final inserted = formatter.formatEditUpdate(
        edit('IDR 1.000,00', 6), edit('IDR 1.9000,00', 7));
    expect(inserted.text, 'IDR 19.000,00');
    expect(inserted.selection.extentOffset, 6);
    expect(
        formatter
            .formatEditUpdate(edit('IDR 1,00', 5), edit('IDR ,00', 4))
            .text,
        '');
  });

  test('backspace at a group separator removes the adjacent digit', () {
    final result = formatter.formatEditUpdate(
        edit('IDR 1.000,00', 6), edit('IDR 1000,00', 5));
    expect(result.text, 'IDR 0,00');
  });

  test('fractional rupiah and excessively large values are rejected', () {
    final previous = edit('IDR 1.000,00', 9);
    expect(
        formatter.formatEditUpdate(previous, edit('IDR 1.000,10')), previous);
    expect(formatter.formatEditUpdate(previous, edit('1000000000000001')),
        previous);
  });

  testWidgets(
      'form input displays an outside label and validates the formatted amount',
      (tester) async {
    final key = GlobalKey<FormState>();
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Form(
                key: key,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: AppFormField(
                      controller: controller,
                      decoration: const AppInputDecoration(labelText: 'Amount'),
                      inputFormatters: const [IdrInputFormatter()],
                      validator: (value) => parseIdrInput(value ?? '') == 50000
                          ? null
                          : 'Wrong amount'),
                )))));
    await tester.enterText(find.byType(TextFormField), '50000');
    await tester.pump();
    expect(controller.text, 'IDR 50.000,00');
    expect(key.currentState!.validate(), isTrue);
    final label = tester.getRect(find.byType(AppInputLabel));
    final field = tester.getRect(find.byType(TextFormField));
    expect(label.bottom, lessThan(field.top));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
