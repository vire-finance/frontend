import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/features/payment/data/payment_destination.dart';
import 'package:vire/features/payment/presentation/payment_destination_fields.dart';

void main() {
  testWidgets('bank search, leading zeros and structured submission',
      (tester) async {
    final form = GlobalKey<FormState>();
    PaymentDestination? destination;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Form(
                key: form,
                child: PaymentDestinationFields(
                    bank: true, onChanged: (v) => destination = v)))));
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Select a destination bank'), findsOneWidget);
    await tester.tap(find.text('Select destination bank'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'BCA');
    await tester.pump();
    expect(find.text('Mandiri'), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, 'BCA'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '000123');
    expect(form.currentState!.validate(), isTrue);
    expect(destination!.toJson(), {
      'payment_type': 'BANK',
      'destination_name': 'BCA',
      'destination_account_number': '000123'
    });
  });

  testWidgets('Other requires a bank name', (tester) async {
    final form = GlobalKey<FormState>();
    PaymentDestination? destination;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Form(
                key: form,
                child: PaymentDestinationFields(
                    bank: true, onChanged: (v) => destination = v)))));
    await tester.tap(find.text('Select destination bank'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Other');
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'Other'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '001');
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Enter the bank name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Bank Jago');
    expect(form.currentState!.validate(), isTrue);
    expect(destination!.toJson()['destination_bank_name'], 'Bank Jago');
  });

  testWidgets('wallet selection and switching clears incompatible values',
      (tester) async {
    final form = GlobalKey<FormState>();
    PaymentDestination? destination;
    var bank = false;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
      update = setState;
      return Form(
          key: form,
          child: PaymentDestinationFields(
              key: ValueKey(bank),
              bank: bank,
              onChanged: (v) => destination = v));
    }))));
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GoPay').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '008123');
    expect(form.currentState!.validate(), isTrue);
    expect(destination!.toJson()['payment_type'], 'E_WALLET');
    expect(destination!.accountNumber, '008123');
    update(() {
      bank = true;
      destination = null;
    });
    await tester.pumpAndSettle();
    expect(destination, isNull);
    expect(find.text('Select destination bank'), findsOneWidget);
    expect(find.text('008123'), findsNothing);
    expect(form.currentState!.validate(), isFalse);
  });
}
