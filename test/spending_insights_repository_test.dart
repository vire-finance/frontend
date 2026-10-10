import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/features/dashboard/data/spending_insights_repository.dart';

class InsightAdapter implements HttpClientAdapter {
  InsightAdapter(this.responses);
  final List<Map<String, dynamic>> responses;
  final List<String> methods = [];
  final List<Map<String, dynamic>> queries = [];
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    methods.add(options.method);
    queries.add(options.queryParameters);
    return ResponseBody.fromString(
        jsonEncode({'ai_analysis': responses.removeAt(0)}), 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

const ready = {
  'available': true,
  'summary': 'Ringkasan yang juga muncul di detail.',
  'insights': []
};

void main() {
  test('explicit refresh bypasses cached analysis and requests a new result',
      () async {
    final adapter = InsightAdapter([
      ready,
      {...ready, 'summary': 'Analisis terbaru.'}
    ]);
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = ApiSpendingInsightsRepository(dio: dio);
    await repo.generate();
    final refreshed = await repo.generate(force: true);
    expect(refreshed.summary, 'Analisis terbaru.');
    expect(adapter.methods, ['GET', 'POST']);
    expect(adapter.queries.last['force'], isTrue);
  });
  test('dashboard reuses completed backend analysis without generating again',
      () async {
    final adapter = InsightAdapter([ready]);
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = ApiSpendingInsightsRepository(dio: dio);
    final result = await repo.generate();
    expect(result.available, isTrue);
    expect(repo.latest?.summary, ready['summary']);
    expect(adapter.methods, ['GET']);
  });

  test('concurrent dashboard and detail wait for in-progress result', () async {
    final adapter = InsightAdapter([
      {'available': false, 'fallback_reason': 'NOT_GENERATED'},
      {'available': false, 'fallback_reason': 'LLM_GENERATION_IN_PROGRESS'},
      {'available': false, 'fallback_reason': 'NOT_GENERATED'},
      ready,
    ]);
    final dio = Dio()..httpClientAdapter = adapter;
    final repo =
        ApiSpendingInsightsRepository(dio: dio, pollInterval: Duration.zero);
    final dashboard = repo.generate();
    final detail = repo.generate();
    expect(identical(dashboard, detail), isTrue);
    expect((await dashboard).available, isTrue);
    expect((await detail).summary, ready['summary']);
    expect(adapter.methods, ['GET', 'POST', 'GET', 'GET']);
  });
}
