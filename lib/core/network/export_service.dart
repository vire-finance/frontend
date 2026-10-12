import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';

import 'api_client.dart';

class ExportService {
  ExportService._();
  static final instance = ExportService._();
  final _api = ApiClient.instance;

  static const historyPageSize = 200;
  static const historyFileName = 'vire-transactions.csv';
  static const historyHeaders = [
    'Transaction ID',
    'Date',
    'Card',
    'Category',
    'Description',
    'Amount',
    'Status'
  ];

  Future<List<int>> fetchBackendFileBytes(String path,
      {Map<String, dynamic>? query}) async {
    final response = await _api.dio.get<List<int>>(
      path,
      queryParameters: query,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }

  Future<void> shareBackendFile(String path,
      {Map<String, dynamic>? query,
      String fileName = 'vire-export.csv'}) async {
    await _shareBytes(
        await fetchBackendFileBytes(path, query: query), fileName);
  }

  /// Fetches every history row matching [filters] and builds the CSV bytes.
  ///
  /// Pagination follows the backend `{total, offset, limit, items}` envelope
  /// with [historyPageSize] (the backend maximum), so exports are never
  /// silently truncated. The returned bytes are valid UTF-8 prefixed with a
  /// BOM for Microsoft Excel compatibility. Separated from [shareHistoryCsv]
  /// so the fetch/build logic is unit-testable without the share plugin.
  Future<Uint8List> exportHistoryBytes({
    String? cardId,
    String? pocketId,
    String? status,
    String? search,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final rows = await _fetchAllHistoryRows(
      cardId: cardId,
      pocketId: pocketId,
      status: status,
      search: search,
      category: category,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    return buildHistoryCsvBytes(rows);
  }

  Future<void> shareHistoryCsv({
    String? cardId,
    String? pocketId,
    String? status,
    String? search,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    await _shareBytes(
      await exportHistoryBytes(
        cardId: cardId,
        pocketId: pocketId,
        status: status,
        search: search,
        category: category,
        dateFrom: dateFrom,
        dateTo: dateTo,
      ),
      historyFileName,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllHistoryRows({
    String? cardId,
    String? pocketId,
    String? status,
    String? search,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final rows = <Map<String, dynamic>>[];
    var offset = 0;
    var total = historyPageSize + 1;
    while (offset < total) {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/history',
        queryParameters: {
          'offset': offset,
          'limit': historyPageSize,
          if (cardId != null) 'card_id': cardId,
          if (pocketId != null) 'pocket_id': pocketId,
          if (status != null) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty) 'category': category,
          if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
          if (dateTo != null) 'date_to': dateTo.toIso8601String(),
        },
      );
      final data = response.data ?? const {};
      total = (data['total'] as num?)?.toInt() ?? 0;
      final items = data['items'] as List<dynamic>? ?? const [];
      if (items.isEmpty) break;
      for (final item in items) {
        rows.add(Map<String, dynamic>.from(item as Map));
      }
      offset += items.length;
    }
    return rows;
  }

  /// Builds valid UTF-8 CSV bytes (with BOM) from raw history rows.
  ///
  /// Commas, quotes, and newlines are escaped by [ListToCsvConverter].
  /// User-controlled text cells that could be interpreted as spreadsheet
  /// formulas (`=`, `+`, `-`, `@` after leading whitespace) are prefixed
  /// with a single quote, mirroring the backend export guard. Numeric
  /// amounts pass through untouched.
  static Uint8List buildHistoryCsvBytes(List<Map<String, dynamic>> rows) {
    final csv = const ListToCsvConverter().convert([
      historyHeaders,
      for (final row in rows)
        [
          _safeCell(row['id']),
          _safeCell(row['processed_at'] ?? row['created_at']),
          _safeCell(row['card_name']),
          _safeCell(row['category']),
          _safeCell(row['description']),
          row['amount'],
          _safeCell(row['status']),
        ],
    ]);
    return Uint8List.fromList(utf8.encode('\uFEFF$csv'));
  }

  static Object? _safeCell(Object? value) {
    if (value == null) return null;
    if (value is num) return value;
    final text = '$value';
    if (text.trimLeft().startsWith(RegExp(r'[=+\-@]'))) return "'$text";
    return text;
  }

  Future<void> _shareBytes(List<int> bytes, String fileName) async {
    await Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: fileName,
          mimeType: 'text/csv',
        ),
      ],
      subject: fileName,
    );
  }
}
