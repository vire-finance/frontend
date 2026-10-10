import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/features/document/presentation/employee/employee_document_upload_screen.dart';

void main() {
  testWidgets('request category dropdown and deadline calendar work',
      (tester) async {
    tester.view.physicalSize = const Size(480, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(const MaterialApp(home: EmployeeDocumentUploadScreen()));
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    for (final category in [
      'Operational',
      'Production',
      'Marketing',
      'Emergency',
      'Administration & Tax',
      'Others'
    ]) {
      expect(find.text(category), findsOneWidget);
    }
    expect(find.text('Salary'), findsNothing);
    await tester.tap(find.text('Marketing'));
    await tester.pumpAndSettle();
    expect(find.text('Marketing'), findsOneWidget);
    final deadline = find.widgetWithText(TextFormField, 'Choose a date');
    await tester.ensureVisible(deadline);
    await tester.tap(deadline);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.byType(TimePickerDialog), findsNothing);
  });
}
