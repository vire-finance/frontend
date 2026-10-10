import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:vire/core/network/api_client.dart';
import 'package:vire/features/document/presentation/purchase_requests_screen.dart';
import 'package:vire/features/document/presentation/request_document_list.dart';
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
  testWidgets('employee Payment opens the direct form and bank transfer',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EmployeePaymentScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Scan QRIS'), findsOneWidget);
    expect(find.text('Show Code'), findsOneWidget);
    expect(find.text('Pending Payment'), findsNothing);
    await tester.tap(find.text('Transfer to Bank / E-Wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('E-Wallet'), findsOneWidget);
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
      'invoice request includes all categories and no employee approval option',
      (tester) async {
    tester.view.physicalSize = const Size(480, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(const MaterialApp(home: PurchaseRequestFormScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<VireCardData>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advertising · 1234').last);
    await tester.pumpAndSettle();
    expect(find.text('Attach Invoice (Required)'), findsOneWidget);
    expect(find.text('Employee Payment Request'), findsNothing);
    final category = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(category);
    await tester.tap(category);
    await tester.pumpAndSettle();
    expect(find.text('Marketing'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
  });
  testWidgets('employee only sees payment action after approval',
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
    await tester.scrollUntilVisible(find.text('Proceed to Payment'), 160);
    expect(find.text('Proceed to Payment'), findsOneWidget);
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
