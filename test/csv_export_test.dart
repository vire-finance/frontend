import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/core/network/api_client.dart';
import 'package:vire/core/network/export_service.dart';

Map<String, dynamic> historyRow(int index) => {
      'id': 'tx-$index',
      'party_name': 'Merchant $index',
      'description': 'Payment $index',
      'amount': 1000 + index,
      'card_name': 'Card',
      'category': 'Operational',
      'processed_at': '2026-10-01T12:00:00+07:00',
      'status': 'APPROVED',
    };

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

List<List<dynamic>> parseCsv(Uint8List bytes) {
  // BOM check on raw bytes: Dart's utf8.decode strips a leading BOM.
  expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF], reason: 'missing UTF-8 BOM');
  final text = utf8.decode(bytes);
  return const CsvToListConverter().convert(text.substring(text.startsWith('\uFEFF') ? 1 : 0));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late HttpClientAdapter previousAdapter;
  late List<RequestOptions> requests;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    dio = ApiClient.instance.dio;
    previousAdapter = dio.httpClientAdapter;
    requests = [];
  });

  tearDown(() {
    dio.httpClientAdapter = previousAdapter;
    FlutterSecureStorage.setMockInitialValues({});
  });

  void useHistory({required int total, int failAtOffset = -1}) {
    dio.httpClientAdapter = FakeAdapter((options) async {
      requests.add(options);
      final offset = (options.queryParameters['offset'] as num).toInt();
      if (offset == failAtOffset) {
        return jsonResponse({'detail': 'boom'}, 500);
      }
      final remaining = total - offset;
      final count = remaining <= 0
          ? 0
          : (remaining > ExportService.historyPageSize
              ? ExportService.historyPageSize
              : remaining);
      return jsonResponse({
        'total': total,
        'offset': offset,
        'limit': ExportService.historyPageSize,
        'items': [
          for (var i = 0; i < count; i++) historyRow(offset + i),
        ],
      });
    });
  }

  test('exports all records beyond the old 200 cap via pagination', () async {
    useHistory(total: 250);
    final bytes = await ExportService.instance.exportHistoryBytes();
    expect(requests.map((r) => r.queryParameters['offset']), [0, 200]);
    expect(requests.every((r) => r.path == '/history'), isTrue);
    final table = parseCsv(bytes);
    expect(table.first, ExportService.historyHeaders);
    expect(table.length, 251);
    final ids = table.skip(1).map((row) => '${row[0]}').toSet();
    expect(ids, hasLength(250));
    expect(ids.contains('tx-0') && ids.contains('tx-249'), isTrue);
  });

  test('passes search, category, card, status, pocket, and date filters',
      () async {
    useHistory(total: 1);
    final from = DateTime.parse('2026-09-01T00:00:00+07:00');
    final to = DateTime.parse('2026-10-01T00:00:00+07:00');
    await ExportService.instance.exportHistoryBytes(
      search: 'kopi',
      category: 'Operational',
      cardId: 'card-1',
      pocketId: 'pocket-1',
      status: 'APPROVED',
      dateFrom: from,
      dateTo: to,
    );
    final params = requests.single.queryParameters;
    expect(params['search'], 'kopi');
    expect(params['category'], 'Operational');
    expect(params['card_id'], 'card-1');
    expect(params['pocket_id'], 'pocket-1');
    expect(params['status'], 'APPROVED');
    expect(params['date_from'], from.toIso8601String());
    expect(params['date_to'], to.toIso8601String());
  });

  test('preserves Indonesian non-ASCII text in valid UTF-8', () async {
    dio.httpClientAdapter = FakeAdapter((options) async {
      requests.add(options);
      return jsonResponse({
        'total': 1,
        'offset': 0,
        'limit': 200,
        'items': [
          {
            ...historyRow(0),
            'card_name': 'Warung Nasi Goreng Pak Harto',
            'description': 'Pembayaran katering rapat — lunas, terima kasih',
          },
        ],
      });
    });
    final bytes = await ExportService.instance.exportHistoryBytes();
    final text = utf8.decode(bytes);
    expect(text, contains('Warung Nasi Goreng Pak Harto'));
    expect(text, contains('Pembayaran katering rapat — lunas, terima kasih'));
    // Valid UTF-8 round-trips through strict decoding (already done above).
    expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
  });

  test('escapes commas, quotes, newlines and neutralizes formulas', () async {
    final rows = [
      {
        ...historyRow(0),
        'description': 'Beli "kopi", gula\naroma',
      },
      {...historyRow(1), 'description': '=CMD|/c calc'},
      {...historyRow(2), 'description': '+628123456789'},
      {...historyRow(3), 'description': '-2+3'},
      {...historyRow(4), 'description': '@mention'},
      {...historyRow(5), 'description': '  =padded'},
    ];
    final bytes = ExportService.buildHistoryCsvBytes(rows);
    final table = parseCsv(bytes);
    expect(table.length, 7);
    // Round-trip through a real CSV parser: structural escaping is correct.
    expect(table[1][4], 'Beli "kopi", gula\naroma');
    for (var i = 2; i <= 6; i++) {
      expect('${table[i][4]}'.startsWith("'"), isTrue,
          reason: 'row $i formula not neutralized: ${table[i][4]}');
    }
    // Legitimate numeric values are preserved as numbers.
    expect(table[1][5], 1000);
  });

  test('empty result still produces headers with BOM', () async {
    useHistory(total: 0);
    final bytes = await ExportService.instance.exportHistoryBytes();
    final table = parseCsv(bytes);
    expect(table, [ExportService.historyHeaders]);
  });

  test('mid-export API failure aborts without partial output', () async {
    useHistory(total: 250, failAtOffset: 200);
    await expectLater(
      ExportService.instance.exportHistoryBytes(),
      throwsA(isA<DioException>()),
    );
  });

  test('dashboard spending export passes period query to backend file',
      () async {
    dio.httpClientAdapter = FakeAdapter((options) async {
      requests.add(options);
      return ResponseBody.fromString('period,category\n',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/csv']
          });
    });
    final bytes = await ExportService.instance.fetchBackendFileBytes(
      '/dashboard/spending/export.csv',
      query: {'period': '2026-09'},
    );
    expect(requests.single.path, '/dashboard/spending/export.csv');
    expect(requests.single.queryParameters['period'], '2026-09');
    expect(utf8.decode(bytes), contains('period,category'));
  });
}
