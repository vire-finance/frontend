import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class FundingRepository {
  static final instance = FundingRepository();
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>?> account() async {
    final response = await _api.dio.get<Map<String, dynamic>>('/fund-account');
    return response.data;
  }

  Future<void> save(Map<String, dynamic> account) async {
    await _api.dio.put<void>('/fund-account', data: account);
  }

  Future<List<Map<String, dynamic>>> movements() async {
    final response = await _api.dio.get<List<dynamic>>('/fund-account/movements');
    return (response.data ?? []).map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<void> allocate(String pocketId, int amount, String key, String token) async {
    await _api.dio.post<void>('/fund-account/allocations',
      data: {'pocket_id': pocketId, 'amount': amount},
      options: Options(headers: {'Idempotency-Key': key, 'X-Action-Token': token}));
  }
}
