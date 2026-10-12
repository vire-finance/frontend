import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/core/network/api_client.dart';
import 'package:vire/core/session/session_cache.dart';
import 'package:vire/features/auth/data/auth_repository.dart';
import 'package:vire/features/document/data/document_repository.dart';
import 'package:vire/features/document/data/employee_request_model.dart';
import 'package:vire/features/document/data/employee_request_repository.dart';
import 'package:vire/features/history/data/transaction_repository.dart';
import 'package:vire/features/payment/data/payment_model.dart';
import 'package:vire/features/payment/data/payment_repository.dart';
import 'package:vire/features/pocket/data/employee_pocket_repository.dart';
import 'package:vire/features/pocket/data/pocket_repository.dart';
import 'package:vire/features/pocket/presentation/owner/owner_card_form.dart';

Map<String, dynamic> historyRow(String id, String title) => {
      'id': id,
      'party_name': title,
      'description': title,
      'amount': 1000,
      'card_name': 'Card',
      'category': 'Others',
      'processed_at': '2026-10-01T12:00:00Z',
      'payment_method': 'QRIS',
      'status': 'APPROVED',
    };

Map<String, dynamic> requestRow(String id) => {
      'id': id,
      'display_id': 'REQ-$id',
      'status': 'PENDING_APPROVAL',
      'pocket_id': 'pocket',
      'total_amount': 500,
      'needed_by': '2026-10-20T00:00:00Z',
      'request_type': 'PURCHASE',
      'category': 'Operational',
      'explanation': 'Supplies',
      'party_name': 'Merchant',
      'requester': {'name': 'Employee'},
      'documents': [],
    };

/// Programmable HTTP adapter: route Dio requests to canned responses.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);
  Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object data, [int status = 200]) =>
    ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late HttpClientAdapter previousAdapter;
  late List<Interceptor> previousInterceptors;
  late VoidCallback? previousHook;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SessionCaches.clearAll();
    // Touch AuthRepository so the session-invalidation hook is registered.
    // ignore: unnecessary_statements
    AuthRepository.instance;
    dio = ApiClient.instance.dio;
    previousAdapter = dio.httpClientAdapter;
    previousInterceptors = dio.interceptors.toList();
    previousHook = ApiClient.instance.onSessionInvalidated;
  });

  tearDown(() {
    dio.httpClientAdapter = previousAdapter;
    dio.interceptors
      ..clear()
      ..addAll(previousInterceptors);
    ApiClient.instance.onSessionInvalidated = previousHook;
    SessionCaches.clearAll();
    FlutterSecureStorage.setMockInitialValues({});
  });

  void useAdapter(Future<ResponseBody> Function(RequestOptions) handler) {
    dio.httpClientAdapter = FakeAdapter(handler);
  }

  Future<void> seedCaches() async {
    useAdapter((options) async {
      return switch (options.path) {
        '/history' => jsonResponse({
            'total': 1,
            'offset': 0,
            'limit': 100,
            'items': [historyRow('tx-a', 'User A coffee')]
          }),
        '/pockets' => jsonResponse([
            {
              'id': 'pocket',
              'name': 'Pocket',
              'remaining_amount': 100,
              'monthly_limit': 100,
              'theme': 'BLUE'
            }
          ]),
        '/cards' => jsonResponse([
            {
              'id': 'card',
              'pocket_id': 'pocket',
              'name': 'Card',
              'balance': 100,
              'monthly_limit': 100,
              'status': 'ACTIVE'
            }
          ]),
        '/fund-requests' => jsonResponse({
            'items': [requestRow('req-a')]
          }),
        '/notifications' => jsonResponse({'items': []}),
        _ => jsonResponse({}, 404),
      };
    });
    await TransactionRepository.instance.load();
    await PocketRepository.instance.load();
    await EmployeePocketRepository.instance.load();
    await DocumentRepository.instance.loadDocuments();
    await EmployeeRequestRepository.instance.load();
    PaymentRepository.instance.complete(const PaymentDraft(
      kind: PaymentKind.qris,
      title: 'User A payment',
      amount: 100,
      sourceCard: VireCardData(
          id: 'card',
          name: 'Card',
          pocketId: 'pocket',
          balance: 100,
          limit: 100,
          lastFour: '1234',
          themeIndex: 0),
    ));
  }

  test('logout clears cached financial data', () async {
    await seedCaches();
    expect(TransactionRepository.instance.transactions, hasLength(1));
    expect(PocketRepository.instance.pockets, hasLength(1));
    expect(EmployeePocketRepository.instance.accessibleCards, hasLength(1));
    expect(DocumentRepository.instance.documents, isNotEmpty);
    expect(EmployeeRequestRepository.instance.requests, hasLength(1));
    expect(PaymentRepository.instance.lastCompletedPayment, isNotNull);

    await ApiClient.instance.saveSession(
        accessToken: 'a', refreshToken: 'r', role: 'OWNER');
    useAdapter((options) async => jsonResponse({}));
    await AuthRepository.instance.logout();

    expect(TransactionRepository.instance.transactions, isEmpty);
    expect(PocketRepository.instance.pockets, isEmpty);
    expect(PocketRepository.instance.cards, isEmpty);
    expect(EmployeePocketRepository.instance.accessibleCards, isEmpty);
    expect(EmployeePocketRepository.instance.accessiblePockets, isEmpty);
    expect(DocumentRepository.instance.documents, isEmpty);
    expect(EmployeeRequestRepository.instance.requests, isEmpty);
    expect(PaymentRepository.instance.lastCompletedPayment, isNull);
    expect(await ApiClient.instance.hasSession, isFalse);
  });

  test('user B never sees user A data after logout/login', () async {
    await ApiClient.instance.saveSession(
        accessToken: 'a-access', refreshToken: 'a-refresh', role: 'OWNER');
    await seedCaches();
    expect(TransactionRepository.instance.transactions.first.title,
        contains('User A'));

    useAdapter((options) async => jsonResponse({}));
    await AuthRepository.instance.logout();

    useAdapter((options) async {
      if (options.path == '/auth/login') {
        return jsonResponse({
          'access_token': 'b-access',
          'refresh_token': 'b-refresh',
          'role': 'OWNER',
        });
      }
      if (options.path == '/history') {
        return jsonResponse({
          'total': 1,
          'offset': 0,
          'limit': 100,
          'items': [historyRow('tx-b', 'User B supplies')]
        });
      }
      return jsonResponse({}, 404);
    });
    await AuthRepository.instance
        .login(email: 'b@example.test', password: 'secret');
    // Caches are empty before B's data loads: no stale frame is possible.
    expect(TransactionRepository.instance.transactions, isEmpty);
    await TransactionRepository.instance.load();
    final titles = TransactionRepository.instance.transactions
        .map((t) => t.title)
        .toList();
    expect(titles, contains('User B supplies'));
    expect(titles.any((t) => t.contains('User A')), isFalse);
  });

  test('in-flight response from previous session cannot repopulate cache',
      () async {
    final gate = Completer<void>();
    useAdapter((options) async {
      if (options.path == '/history') {
        await gate.future;
        return jsonResponse({
          'total': 1,
          'offset': 0,
          'limit': 100,
          'items': [historyRow('tx-stale', 'Stale session data')]
        });
      }
      return jsonResponse({}, 404);
    });

    final pending = TransactionRepository.instance.load();
    SessionCaches.clearAll();
    gate.complete();
    await pending;

    expect(TransactionRepository.instance.transactions, isEmpty);
    expect(TransactionRepository.instance.isLoading, isFalse);
  });

  test('failed logout API call still clears local session state', () async {
    await seedCaches();
    await ApiClient.instance.saveSession(
        accessToken: 'a', refreshToken: 'r', role: 'OWNER');
    useAdapter((options) async {
      if (options.path == '/auth/logout') {
        return jsonResponse({'detail': 'upstream unavailable'}, 500);
      }
      return jsonResponse({}, 404);
    });

    await AuthRepository.instance.logout();

    expect(await ApiClient.instance.hasSession, isFalse);
    expect(TransactionRepository.instance.transactions, isEmpty);
    expect(DocumentRepository.instance.documents, isEmpty);
    expect(PaymentRepository.instance.lastCompletedPayment, isNull);
  });

  test('normal session loading still works after isolation changes', () async {
    await ApiClient.instance.saveSession(
        accessToken: 'a', refreshToken: 'r', role: 'OWNER');
    useAdapter((options) async {
      return switch (options.path) {
        '/history' => jsonResponse({
            'total': 2,
            'offset': 0,
            'limit': 100,
            'items': [
              historyRow('tx-1', 'Coffee'),
              historyRow('tx-2', 'Supplies'),
            ]
          }),
        _ => jsonResponse({}, 404),
      };
    });
    await TransactionRepository.instance.load();
    expect(TransactionRepository.instance.transactions, hasLength(2));
    expect(TransactionRepository.instance.isLoading, isFalse);
  });

  test('token refresh persistence path does not clear caches', () async {
    // Successful refresh persists via saveSession (never clearSession);
    // a fresh Dio is used for the network call, so assert the seam here.
    await seedCaches();
    await ApiClient.instance.saveSession(
        accessToken: 'new-access', refreshToken: 'new-refresh', role: 'OWNER');
    expect(TransactionRepository.instance.transactions, hasLength(1));
    expect(DocumentRepository.instance.documents, isNotEmpty);
    expect(await ApiClient.instance.accessToken, 'new-access');
  });

  test('stale createPocket/loadDetail/submit responses are discarded',
      () async {
    final gate = Completer<void>();
    useAdapter((options) async {
      await gate.future;
      if (options.path == '/pockets' && options.method == 'POST') {
        return jsonResponse({
          'id': 'pocket-stale',
          'name': 'Stale',
          'remaining_amount': 1,
          'monthly_limit': 1,
          'theme': 'BLUE',
        });
      }
      if (options.path == '/fund-requests/req-stale') {
        return jsonResponse(requestRow('req-stale'));
      }
      if (options.path == '/fund-requests' && options.method == 'POST') {
        return jsonResponse({'id': 'draft-stale'});
      }
      if (options.path == '/fund-requests/draft-stale/submit') {
        return jsonResponse(requestRow('sub-stale'));
      }
      return jsonResponse({}, 404);
    });

    final pocketFuture = PocketRepository.instance.createPocket(
        const VirePocketData(
            id: 'x',
            name: 'X',
            balance: 0,
            limit: 1,
            source: 's',
            themeIndex: 1));
    final detailFuture =
        DocumentRepository.instance.loadDetail('req-stale');
    final submitFuture = EmployeeRequestRepository.instance.submit(
        EmployeePaymentRequest(
            id: 'tmp',
            reference: 'tmp',
            explanation: 'e',
            requestType: 'Purchase',
            partyName: 'p',
            amount: 1,
            neededAt: DateTime(2026, 10, 20),
            createdAt: DateTime(2026, 10, 10)));
    SessionCaches.clearAll();
    gate.complete();

    // Server-confirmed values are still returned to their callers...
    expect((await pocketFuture).id, 'pocket-stale');
    expect((await detailFuture).id, 'req-stale');
    expect((await submitFuture).id, 'sub-stale');
    // ...but nothing repopulates the cleared caches (incl. submit's
    // mirror into DocumentRepository).
    expect(PocketRepository.instance.pockets, isEmpty);
    expect(DocumentRepository.instance.documents, isEmpty);
    expect(EmployeeRequestRepository.instance.requests, isEmpty);
  });

  test('stale card mutation responses are discarded', () async {
    await seedCaches();
    expect(
        PocketRepository.instance.cards.map((card) => card.id), contains('card'));
    final gate = Completer<void>();
    useAdapter((options) async {
      await gate.future;
      return jsonResponse({
        'id': 'card',
        'pocket_id': 'pocket',
        'name': 'Mutated by stale session',
        'balance': 999,
        'monthly_limit': 999,
        'status': 'ACTIVE',
      });
    });

    final card = PocketRepository.instance.cards
        .firstWhere((item) => item.id == 'card');
    final pending =
        PocketRepository.instance.updateCardStatus(card, locked: true);
    SessionCaches.clearAll();
    gate.complete();
    await pending;

    expect(PocketRepository.instance.cards, isEmpty);
    expect(PocketRepository.instance.pockets, isEmpty);
  });
}
