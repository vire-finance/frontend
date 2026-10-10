import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/shared/widgets/expense_category_multi_select.dart';
import 'package:vire/shared/widgets/expense_category_tags.dart';
import 'package:vire/features/payment/presentation/expense_category_field.dart';

void main() {
  testWidgets('owner dropdown keeps multiple selections', (tester) async {
    List<String> selected = [];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Form(child: ExpenseCategoryMultiSelect(onChanged: (value) => selected = value)))));
    await tester.tap(find.text('Choose one or more categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marketing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Operational'));
    await tester.pumpAndSettle();
    expect(selected, containsAll(['Marketing', 'Operational']));
    expect(selected.length, 2);
  });

  testWidgets('payment hides disallowed categories and resets invalid previous value', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ExpenseCategoryField(value: 'Salary', categories: ['Marketing', 'Operational'], onChanged: null))));
    expect(find.text('Salary'), findsNothing);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ExpenseCategoryField(value: null, categories: const ['Marketing', 'Operational'], onChanged: (_) {}))));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Marketing'), findsOneWidget);
    expect(find.text('Operational'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);
    expect(find.text('Others'), findsNothing);
  });

  testWidgets('tags stay in one horizontally scrolling row', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox(width: 150, child: ExpenseCategoryTags(categories: ['Operational', 'Marketing', 'Administration & Tax'])))));
    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    expect(scroll.scrollDirection, Axis.horizontal);
    expect(find.byType(Wrap), findsNothing);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels, greaterThan(0));
  });
}
