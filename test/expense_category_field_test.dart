import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/features/payment/data/payment_model.dart';
import 'package:vire/features/payment/presentation/expense_category_field.dart';

void main() {
  testWidgets('payment requires a category and provides all seven choices',
      (tester) async {
    final form = GlobalKey<FormState>();
    String? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Form(
      key: form,
      child: StatefulBuilder(
          builder: (context, setState) => Padding(
                padding: const EdgeInsets.all(20),
                child: ExpenseCategoryField(
                    value: selected,
                    onChanged: (value) => setState(() => selected = value)),
              )),
    ))));
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    for (final category in expenseCategories) {
      expect(find.text(category).last, findsOneWidget);
    }
    await tester.tap(find.text('Marketing').last);
    await tester.pumpAndSettle();
    expect(selected, 'Marketing');
    expect(form.currentState!.validate(), isTrue);
    expect(tester.takeException(), isNull);
  });
}
