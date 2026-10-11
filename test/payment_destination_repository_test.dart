import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/core/network/api_client.dart';
import 'package:vire/features/history/data/transaction_repository.dart';
import 'package:vire/features/payment/data/payment_destination.dart';
import 'package:vire/features/pocket/presentation/owner/owner_card_form.dart';

class PaymentAdapter implements HttpClientAdapter {
  Map<String, dynamic>? submitted;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.method == 'POST') {
      submitted = Map<String, dynamic>.from(options.data as Map);
    }
    return ResponseBody.fromString(
        jsonEncode(options.method == 'POST'
            ? {
                'id': 'transaction',
                'status': 'APPROVED',
                'amount': 50,
                'description': 'Supplies',
                'created_at': '2026-10-11T00:00:00Z',
                'payment_method': submitted!['payment_type'] == 'BANK'
                    ? 'BANK_TRANSFER'
                    : submitted!['payment_type'] == 'E_WALLET'
                        ? 'E_WALLET'
                        : submitted!['payment_method'],
                if (submitted!.containsKey('payment_type')) ...submitted!,
                'recipient_account': submitted!['recipient_account'],
              }
            : {'items': []}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final destination in [
    const PaymentDestination(
        paymentType: 'BANK', name: 'BCA', accountNumber: '000123'),
    const PaymentDestination(
        paymentType: 'E_WALLET', name: 'GoPay', accountNumber: '008123'),
    const PaymentDestination(
        paymentType: 'BANK',
        name: 'Other',
        bankName: 'Bank Jago',
        accountNumber: '001'),
  ]) {
    test('selected ${destination.name} submits through the compatible API',
        () async {
      final dio = ApiClient.instance.dio;
      final oldAdapter = dio.httpClientAdapter;
      final interceptors = dio.interceptors.toList();
      final adapter = PaymentAdapter();
      dio.interceptors.clear();
      dio.httpClientAdapter = adapter;
      addTearDown(() {
        dio.httpClientAdapter = oldAdapter;
        dio.interceptors.clear();
        dio.interceptors.addAll(interceptors);
      });
      final result = await TransactionRepository.instance.createCardPayment(
          card: const VireCardData(
              id: 'card',
              name: 'Card',
              pocketId: 'pocket',
              balance: 1000,
              limit: 1000,
              lastFour: '1234',
              themeIndex: 1),
          title: 'Supplies',
          amount: 50,
          actionToken: 'test-proof',
          destination: destination,
          idempotencyKey: 'test-key');
      expect(adapter.submitted!['payment_type'], destination.paymentType);
      expect(adapter.submitted!['destination_name'], destination.name);
      expect(adapter.submitted!['destination_account_number'],
          destination.accountNumber);
      expect(adapter.submitted!.containsKey('recipient_account'), isFalse);
      expect(result.status, 'APPROVED');
      expect(result.destinationName, destination.name);
      expect(result.destinationAccountNumber, destination.accountNumber);
    });
  }
}
