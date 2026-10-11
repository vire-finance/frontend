import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/shared/widgets/app_text_field.dart';

void main() {
  testWidgets('AppPickerField renders its hint exactly once',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppPickerField(
          value: null,
          onTap: () {},
          decoration: const AppInputDecoration(
              hintText: 'Select destination bank'),
        ),
      ),
    ));
    expect(find.text('Select destination bank'), findsOneWidget);
  });

  testWidgets('AppPickerField renders a selected value exactly once',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppPickerField(
          value: 'BCA',
          onTap: () {},
          decoration: const AppInputDecoration(
              hintText: 'Select destination bank'),
        ),
      ),
    ));
    expect(find.text('BCA'), findsOneWidget);
  });
}
