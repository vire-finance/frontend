import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';

import 'api_client.dart';

class ExportService {
  ExportService._();
  static final instance = ExportService._();
  final _api = ApiClient.instance;

  Future<void> shareBackendFile(String path, {Map<String, dynamic>? query, String fileName = 'vire-export.csv'}) async {
    final response = await _api.dio.get<List<int>>(
      path,
      queryParameters: query,
      options: Options(responseType: ResponseType.bytes),
    );
    await _shareBytes(response.data ?? const [], fileName);
  }

  Future<void> shareHistoryCsv({String? cardId}) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/history',
      queryParameters: {'offset': 0, 'limit': 200, if (cardId != null) 'card_id': cardId},
    );
    final rows = response.data?['items'] as List<dynamic>? ?? const [];
    final csv = const ListToCsvConverter().convert([
      ['Transaction ID', 'Date', 'Card', 'Category', 'Description', 'Amount', 'Status'],
      for (final raw in rows)
        () {
          final row = Map<String, dynamic>.from(raw as Map);
          return [row['id'], row['processed_at'] ?? row['created_at'], row['card_name'], row['category'], row['description'], row['amount'], row['status']];
        }(),
    ]);
    await _shareBytes(csv.codeUnits, 'vire-transactions.csv');
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
