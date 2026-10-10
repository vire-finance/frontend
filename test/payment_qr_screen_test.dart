import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/features/payment/data/payment_model.dart';
import 'package:vire/features/payment/presentation/show_qr_code_screen.dart';
import 'package:vire/features/pocket/presentation/owner/owner_card_form.dart';

void main() {
  testWidgets('payment QR opens as a full screen and returns confirmation',
      (tester) async {
    bool? confirmed;
    const draft = PaymentDraft(
        kind: PaymentKind.qris,
        title: 'Poster',
        amount: 200000,
        category: 'Marketing',
        sourceCard: VireCardData(
            id: 'card',
            name: 'proc',
            pocketId: 'pocket',
            balance: 700000,
            limit: 700000,
            lastFour: '8377',
            themeIndex: 1));
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  onPressed: () async {
                    confirmed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                            builder: (_) => const ShowQrCodeScreen(
                                code: 'simulation', payment: draft)));
                  },
                  child: const Text('Open QR'),
                )))));
    await tester.tap(find.text('Open QR'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('proc • Marketing'), findsOneWidget);
    expect(find.text('IDR 200.000,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Confirm Payment'));
    await tester.tap(find.text('Confirm Payment'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
    expect(find.text('Open QR'), findsOneWidget);
  });
}
