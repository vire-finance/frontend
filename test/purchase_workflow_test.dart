import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:vire/core/network/api_client.dart';
import 'package:vire/features/document/presentation/purchase_requests_screen.dart';
import 'package:vire/features/document/presentation/request_document_list.dart';
import 'package:vire/features/document/presentation/purchase_requests_summary.dart';
import 'package:vire/shared/widgets/bottom_nav_shell.dart';
import 'package:vire/features/pin/presentation/pin_screen.dart';
import 'package:vire/features/document/presentation/employee/employee_request_confirmation_screen.dart';
import 'package:vire/features/document/data/employee_request_model.dart';
import 'package:vire/features/pocket/presentation/owner/owner_card_form.dart';
import 'package:vire/features/payment/presentation/employee/employee_payment_screen.dart';
import 'package:vire/features/history/data/transaction_repository.dart';

void main() {
  late Interceptor mock;
  Map<String, dynamic> row = {
    'id': 'request',
    'status': 'PENDING_APPROVAL',
    'workflow_status': 'PENDING_APPROVAL',
    'payment_executor': 'EMPLOYEE_PAYMENT',
    'party_name': 'Merchant',
    'explanation': 'Buy supplies',
    'category': 'Marketing',
    'total_amount': 50,
    'payment_method': 'BANK_TRANSFER',
    'recipient_account': 'BCA 123',
    'documents': []
  };
  setUp(() {
    row = {
      ...row,
      "status": "PENDING_APPROVAL",
      "workflow_status": "PENDING_APPROVAL"
    };
    FlutterSecureStorage.setMockInitialValues({});
    mock = InterceptorsWrapper(onRequest: (options, handler) {
      Object data = options.path == '/cards'
          ? [
              {
                'id': 'card',
                'pocket_id': 'pocket',
                'name': 'Advertising',
                'balance': 100,
                'monthly_limit': 100,
                'last_four_digits': '1234',
                'status': 'ACTIVE',
                'allowed_categories': ['Marketing']
              }
            ]
          : options.path == '/pockets'
              ? []
              : options.path == '/fund-requests'
                  ? {
                      'items': [row]
                    }
                  : row;
      handler.resolve(
          Response(requestOptions: options, data: data, statusCode: 200));
    });
    ApiClient.instance.dio.interceptors.add(mock);
  });
  tearDown(() => ApiClient.instance.dio.interceptors.remove(mock));
  for (final owner in [true, false]) {
    testWidgets(
        'direct request list always has a working navbar (owner=$owner)',
        (tester) async {
      await tester
          .pumpWidget(MaterialApp(home: RequestDocumentList(owner: owner)));
      await tester.pumpAndSettle();
      expect(find.byType(AppNavbar), findsOneWidget);
      expect(tester.widget<AppNavbar>(find.byType(AppNavbar)).selectedIndex, 2);
      expect(find.text(owner ? 'Document' : 'Request'), findsOneWidget);
      await tester.tap(find.text('Pocket'));
      await tester.pumpAndSettle();
      expect(tester.widget<AppNavbar>(find.byType(AppNavbar)).selectedIndex, 1);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('Home request shortcut preserves the bottom navbar',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PurchaseRequestsSummary())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('View all requests'));
    await tester.pumpAndSettle();
    expect(find.text('Your Documents'), findsOneWidget);
    expect(find.byType(AppNavbar), findsOneWidget);
    final navbar = tester.widget<AppNavbar>(find.byType(AppNavbar));
    expect(navbar.selectedIndex, 2);
    for (final label in ['Home', 'Pocket', 'History', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'employee request list has Add Document and the original status summary',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: RequestDocumentList(owner: false)));
    await tester.pumpAndSettle();
    expect(find.text('Your Requests'), findsOneWidget);
    expect(find.text('Add Document'), findsOneWidget);
    expect(find.text('Waiting'), findsNWidgets(2));
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Pending Payment'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('employee Payment shares the owner menu and transfer form',
      (tester) async {
    tester.view.physicalSize = const Size(480, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: EmployeePaymentScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Also Pay With'), findsOneWidget);
    expect(find.text('Show QR Code'), findsOneWidget);
    expect(find.text('Pending Payment'), findsNothing);
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('E-Wallet'), findsOneWidget);
    expect(find.textContaining('Choose Which Card to Pay With', findRichText: true), findsOneWidget);
    expect(find.textContaining('Transaction Title', findRichText: true), findsOneWidget);
    expect(find.textContaining('Expense Category', findRichText: true), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  test('direct bank payment sends recipient without an approval request',
      () async {
    ApiClient.instance.dio.interceptors.remove(mock);
    Map<String, dynamic>? payload;
    mock = InterceptorsWrapper(onRequest: (options, handler) {
      if (options.path == '/transactions') {
        payload = Map<String, dynamic>.from(options.data as Map);
        handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'id': 'transaction',
          'status': 'APPROVED',
          'fund_request_id': 'receipt-record',
          'amount': 50,
          'processed_at': '2026-10-09T12:00:00Z',
          'payment_method': 'BANK_TRANSFER',
        }));
      } else {
        handler.resolve(Response(
            requestOptions: options, statusCode: 200, data: {'items': []}));
      }
    });
    ApiClient.instance.dio.interceptors.add(mock);
    final result = await TransactionRepository.instance.createCardPayment(
        card: const VireCardData(
            id: 'card',
            name: 'Advertising',
            pocketId: 'pocket',
            balance: 100,
            limit: 100,
            lastFour: '1234',
            themeIndex: 0),
        title: 'Materials',
        amount: 50,
        actionToken: 'token',
        category: 'Marketing',
        paymentMethod: 'BANK_TRANSFER',
        recipientAccount: 'BCA 123456',
        idempotencyKey: 'payment-key');
    expect(payload!['payment_method'], 'BANK_TRANSFER');
    expect(payload!['recipient_account'], 'BCA 123456');
    expect(payload!.containsKey('request_id'), isFalse);
    expect(result.requestId, 'receipt-record');
  });
  testWidgets(
      'Add Document restores the original fields and category/date controls',
      (tester) async {
    tester.view.physicalSize = const Size(480, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(const MaterialApp(home: PurchaseRequestFormScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Input From Document'), findsOneWidget);
    expect(find.text('Scan Document'), findsOneWidget);
    expect(find.text('Add Request'), findsOneWidget);
    expect(find.text('Request Details'), findsOneWidget);
    expect(find.text('Save Document'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<VireCardData>), findsNothing);
    expect(find.text('Purchase Purpose'), findsNothing);
    expect(find.text('Payment Method'), findsNothing);
    await tester.tap(find.text('Add Request'));
    await tester.pump();
    final purpose =
        tester.widget<EditableText>(find.byType(EditableText).first);
    expect(purpose.focusNode.hasFocus, isTrue);
    final category = find.byType(DropdownButtonFormField<String>);
    await tester.tap(category);
    await tester.pumpAndSettle();
    for (final label in [
      'Operational',
      'Production',
      'Marketing',
      'Emergency',
      'Administration & Tax',
      'Others'
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Salary'), findsNothing);
    await tester.tap(find.text('Marketing'));
    await tester.pumpAndSettle();
    final deadline = find.widgetWithText(TextFormField, 'Input date and time');
    await tester.ensureVisible(deadline);
    await tester.tap(deadline);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Buy supplies');
    await tester.enterText(find.byType(TextFormField).at(1), 'Merchant');
    await tester.enterText(find.byType(TextFormField).at(2), '50000');
    await tester.tap(find.text('Save Document'));
    await tester.pumpAndSettle();
    expect(
        find.text('Scan or attach an invoice before saving.'), findsOneWidget);
    expect(find.text('Payment Details'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('legacy employee request never exposes a payment action',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: PurchaseRequestDetailScreen(id: 'request', owner: false)));
    await tester.pumpAndSettle();
    expect(find.text('Proceed to Payment'), findsNothing);
    row = {...row, 'status': 'APPROVED', 'workflow_status': 'AWAITING_PAYMENT'};
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MaterialApp(
        home: PurchaseRequestDetailScreen(id: 'request', owner: false)));
    await tester.pumpAndSettle();
    expect(find.text('Proceed to Payment'), findsNothing);
    await tester.scrollUntilVisible(find.text('Complete Invoice Request'), 160);
    expect(find.text('Complete Invoice Request'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'owner document review offers approve and pay, not separate approval',
      (tester) async {
    row = {
      ...row,
      'payment_executor': 'OWNER_PAYMENT',
      'status': 'PENDING_APPROVAL',
      'display_id': 'REQ-1234',
      'requester': {'name': 'Rida'},
      'ai_analysis': {'summary': 'Review the invoice manually.'}
    };
    await tester.pumpWidget(const MaterialApp(
        home: PurchaseRequestDetailScreen(id: 'request', owner: true)));
    await tester.pumpAndSettle();
    expect(find.text('Document Review'), findsOneWidget);
    expect(find.text('Approve & Pay Invoice'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Approve Request'), findsNothing);
    expect(find.text('Proceed to Payment'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('owner confirmation and decline dialogs gate the PIN screen',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    row = {
      ...row,
      'payment_executor': 'OWNER_PAYMENT',
      'card_id': 'card',
      'status': 'PENDING_APPROVAL'
    };
    await tester.pumpWidget(const MaterialApp(
        home: PurchaseRequestDetailScreen(id: 'request', owner: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve & Pay Invoice'));
    await tester.pumpAndSettle();
    expect(find.text('Are You Sure?'), findsOneWidget);
    expect(
        find.text(
            'Approving this will approve the request and pay the invoice from your main fund account.'),
        findsOneWidget);
    expect(find.byType(PinScreen), findsNothing);
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.byType(PinScreen), findsNothing);
    await tester.tap(find.text('Approve & Pay Invoice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.byType(PinScreen), findsOneWidget);
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(find.text('Reject This Request?'), findsOneWidget);
    final mascot = tester.widget<Image>(find
        .descendant(of: find.byType(Dialog), matching: find.byType(Image))
        .first);
    expect((mascot.image as AssetImage).assetName,
        'assets/images/Regular Images/Mascot - Unsure.png');
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.text('Please provide a reason.'), findsOneWidget);
    expect(find.byType(PinScreen), findsNothing);
    await tester.enterText(
        find.descendant(
            of: find.byType(Dialog), matching: find.byType(TextFormField)),
        'Wrong invoice');
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.byType(PinScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('sent confirmation shows waiting artwork and request details',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final request = EmployeePaymentRequest(
        id: 'request',
        reference: 'REQ-1234',
        explanation: 'Supplies',
        requestType: 'Invoice',
        partyName: 'Bakti Karya',
        amount: 300000,
        neededAt: DateTime(2026, 10, 20),
        createdAt: DateTime(2026, 10, 10, 11, 20));
    await tester.pumpWidget(
        MaterialApp(home: EmployeeRequestConfirmationScreen(request: request)));
    await tester.pumpAndSettle();
    expect(find.text('Your Request Has Been Sent'), findsOneWidget);
    expect(find.text('Bakti Karya'), findsOneWidget);
    expect(find.text('IDR 300,000'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName,
        'assets/images/Regular Images/Waiting For Approval.png');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('owner document list shows overdue receipt and status filters',
      (tester) async {
    row = {...row, 'status': 'APPROVED', 'workflow_status': 'RECEIPT_OVERDUE'};
    await tester
        .pumpWidget(const MaterialApp(home: RequestDocumentList(owner: true)));
    await tester.pumpAndSettle();
    expect(find.text('Your Documents'), findsOneWidget);
    expect(find.text('Add Document'), findsNothing);
    await tester.tap(find.text('Accepted').first);
    await tester.pumpAndSettle();
    expect(find.text('Receipt overdue'), findsOneWidget);
    await tester.tap(find.text('Rejected').first);
    await tester.pumpAndSettle();
    expect(find.text('Receipt overdue'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
