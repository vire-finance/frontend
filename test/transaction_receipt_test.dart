import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/features/payment/presentation/transaction_complete_screen.dart';
import 'package:vire/features/payment/presentation/receipt_export_service.dart';
import 'package:vire/features/payment/data/payment_model.dart';
import 'package:vire/features/pocket/presentation/owner/owner_card_form.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final fonts = FontLoader('InterTight')
      ..addFont(rootBundle.load('assets/fonts/InterTight-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/InterTight-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/InterTight-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/InterTight-Bold.ttf'));
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  testWidgets(
    'receipt keeps original screen and exports all content without controls',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final screenKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'InterTight'),
          home: RepaintBoundary(
            key: screenKey,
            child: TransactionCompleteScreen.topUp(
              sourceAccount: 'Operating Account',
              transactionId: '2e58c2ce-8386-4cc9-93fa-c870e9a8df9e',
              completedAt: DateTime(2026, 10, 12, 16, 10),
              amount: 10000,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Transaction Receipt'), findsNothing);
      expect(find.text('Share'), findsOneWidget);
      final receipt = find.byWidgetPredicate(
        (w) => w is RepaintBoundary && w.child is Material,
      );
      expect(receipt, findsOneWidget);
      expect(
        find.descendant(
          of: receipt,
          matching: find.text('Transaction Complete!'),
        ),
        findsOneWidget,
      );
      for (final label in ['Share', 'Print', 'Back', 'Attach Receipt']) {
        expect(
          find.descendant(of: receipt, matching: find.text(label)),
          findsNothing,
        );
      }
      final key = tester.widget<RepaintBoundary>(receipt).key! as GlobalKey;
      final pngFuture = ReceiptExportService.buildPng(key);
      await tester.pump();
      final png = await tester.runAsync(() => pngFuture);
      expect(png!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      await tester.runAsync(() async {
        final previewPath = Platform.environment['VIRE_RECEIPT_PREVIEW_DIR'];
        final dir = previewPath == null
            ? null
            : (Directory(previewPath)..createSync(recursive: true));
        if (dir != null) {
          File('${dir.path}/receipt.png').writeAsBytesSync(png);
        }
        final boundary = screenKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (dir != null) {
          File('${dir.path}/screen.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
        }
        final pdf = await ReceiptExportService.buildPdf(
          account: 'Operating Account',
          id: '2e58c2ce-8386-4cc9-93fa-c870e9a8df9e',
          date: '12 Oct 2026, 16:10',
          amount: 'IDR 10,000',
          isTopUp: true,
          recipient: 'Business Account',
        );
        expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
        if (dir != null) File('${dir.path}/receipt.pdf').writeAsBytesSync(pdf);
      });
      // Also exercise a short viewport without clipping the exported content.
      tester.view.physicalSize = const Size(320, 568);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(receipt).height, greaterThan(0));
    },
  );
  testWidgets(
    'payment export excludes receipt upload and supports stacked screens',
    (tester) async {
      const card = VireCardData(
        id: 'card',
        name: 'Business Card',
        pocketId: 'pocket',
        balance: 100000,
        limit: 100000,
        lastFour: '1234',
        themeIndex: 0,
      );
      final payment = PaymentDraft(
        kind: PaymentKind.bank,
        title: 'Office supplies',
        amount: 10000,
        sourceCard: card,
        transactionId: 'payment-123',
        completedAt: DateTime(2026, 10, 12, 16, 10),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: TransactionCompleteScreen(
            payment: payment,
            receiptRequestId: 'request-123',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final export = find.byWidgetPredicate(
        (w) => w is RepaintBoundary && w.child is Material,
      );
      expect(
        find.descendant(of: export, matching: find.text('-IDR 10,000')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: export, matching: find.text('Attach Receipt')),
        findsNothing,
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => TransactionCompleteScreen(payment: payment),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
