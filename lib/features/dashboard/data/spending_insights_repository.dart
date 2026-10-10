import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class SpendingInsights {
  const SpendingInsights(
      {required this.available,
      this.summary,
      this.recommendations = const [],
      this.reason});
  final bool available;
  final String? summary;
  final List<String> recommendations;
  final String? reason;
  factory SpendingInsights.fromApi(Map<String, dynamic> response) {
    final ai =
        Map<String, dynamic>.from(response['ai_analysis'] as Map? ?? const {});
    final insights = ai['insights'] as List<dynamic>? ?? const [];
    return SpendingInsights(
        available: ai['available'] == true,
        summary: ai['summary'] as String?,
        recommendations: insights
            .map(
                (item) => '${(item as Map)['recommended_action'] ?? ''}'.trim())
            .where((text) => text.isNotEmpty)
            .toSet()
            .toList(),
        reason: ai['fallback_reason'] as String?);
  }
}

abstract class SpendingInsightsRepository {
  Future<SpendingInsights> generate({bool force = false});
  SpendingInsights? get latest => null;
}

class ApiSpendingInsightsRepository implements SpendingInsightsRepository {
  ApiSpendingInsightsRepository(
      {Dio? dio,
      this.pollInterval = const Duration(seconds: 5),
      this.maxWait = const Duration(seconds: 150)})
      : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;
  final Duration pollInterval;
  final Duration maxWait;
  Future<SpendingInsights>? _inFlight;
  SpendingInsights? _latest;
  @override
  SpendingInsights? get latest => _latest;

  @override
  Future<SpendingInsights> generate({bool force = false}) => _inFlight ??=
      _generate(force: force).whenComplete(() => _inFlight = null);

  Future<SpendingInsights> _readCached() async {
    final response = await _dio.get<Map<String, dynamic>>('/ai/owner/insights',
        queryParameters: {'period': 'month'});
    return SpendingInsights.fromApi(response.data ?? const {});
  }

  Future<SpendingInsights> _generate({required bool force}) async {
    final timer = Stopwatch()..start();
    var result = force
        ? const SpendingInsights(available: false, reason: 'NOT_GENERATED')
        : await _readCached();
    if (!result.available && result.reason != 'LLM_GENERATION_IN_PROGRESS') {
      final response = await _dio.post<Map<String, dynamic>>(
          '/ai/owner/insights/generate',
          queryParameters: {'period': 'month', if (force) 'force': true},
          options: Options(receiveTimeout: maxWait));
      result = SpendingInsights.fromApi(response.data ?? const {});
    }
    while (!result.available &&
        (result.reason == 'LLM_GENERATION_IN_PROGRESS' ||
            result.reason == 'NOT_GENERATED') &&
        timer.elapsed < maxWait) {
      await Future<void>.delayed(pollInterval);
      result = await _readCached();
    }
    if (result.available) _latest = result;
    return result;
  }
}
