import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/features/pocket/presentation/owner/employee_picker_dialog.dart';
import 'package:vire/shared/widgets/app_search_bar.dart';

void main() {
  testWidgets(
      'popup searches profile names, excludes current access, and returns selected employee',
      (tester) async {
    Map<String, dynamic>? selected;
    final employees = [
      {'id': '1', 'full_name': 'Rida Employee'},
      {'id': '2', 'full_name': 'Sari Employee'},
      {'id': '3', 'full_name': 'Already Assigned'},
    ];
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      selected = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (_) => EmployeePickerDialog(
                              employees: Future.value(employees),
                              excludedIds: const {'3'}));
                    },
                    child: const Text('Open picker'))))));
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(AppSearchBar), findsOneWidget);
    expect(find.text('Already Assigned'), findsNothing);
    expect(find.byType(EmployeeAvatar), findsNWidgets(2));
    await tester.enterText(find.byType(TextField), 'SARI');
    await tester.pumpAndSettle();
    expect(find.text('Rida Employee'), findsNothing);
    expect(find.text('Sari Employee'), findsOneWidget);
    await tester.tap(find.text('Sari Employee'));
    await tester.pumpAndSettle();
    expect(selected?['id'], '2');
  });
}
