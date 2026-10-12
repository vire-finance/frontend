import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/dashboard_model.dart';
import '../data/dashboard_repository.dart';
import '../data/spending_insights_repository.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repository,
      {SpendingInsightsRepository? insightsRepository})
      : insightsRepository =
            insightsRepository ?? ApiSpendingInsightsRepository();

  final DashboardRepository _repository;
  final SpendingInsightsRepository insightsRepository;
  DashboardData? _data;
  bool _isLoading = false;
  bool _isGeneratingInsights = false;
  bool _disposed = false;
  Object? _error;
  SpendingInsights? _insights;
  bool _insightsFailed = false;
  String? _aiDataKey;
  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  bool get isGeneratingInsights => _isGeneratingInsights;
  bool get insightsFailed => _insightsFailed && aiSummary == null;
  String? get aiSummary =>
      insightsRepository.latest?.summary ??
      (_insights?.available == true ? _insights?.summary : null);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({String? period}) async {
    _isLoading = true;
    _error = null;
    _notify();
    try {
      _data = await _repository.loadOwnerDashboard(period: period);
      final key = '${_data!.monthlyLimit}:${_data!.transactionCount}:'
          '${_data!.spendingCategories.map((c) => '${c.name}:${c.amount}').join('|')}';
      if (!_disposed && key != _aiDataKey) {
        _aiDataKey = key;
        unawaited(loadInsights());
      }
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> loadInsights({bool force = false}) async {
    if (_disposed || _isGeneratingInsights) return;
    _isGeneratingInsights = true;
    _insightsFailed = false;
    _notify();
    try {
      _insights = await insightsRepository.generate(force: force);
      _insightsFailed = !_insights!.available;
    } catch (_) {
      _insightsFailed = true;
      _insights = null;
    } finally {
      _isGeneratingInsights = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
