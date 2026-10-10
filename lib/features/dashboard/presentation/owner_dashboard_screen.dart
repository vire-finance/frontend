import 'package:flutter/material.dart';
import '../../../core/services/push_notification_service.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/export_service.dart';
import '../../history/presentation/history_screen.dart';
import '../../document/presentation/owner/owner_document_list_screen.dart';
import '../../payment/presentation/payment_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../pocket/presentation/owner/owner_pocket_list_screen.dart';
import '../../../shared/widgets/bottom_nav_shell.dart';
import '../data/dashboard_model.dart';
import '../data/dashboard_repository.dart';
import '../providers/dashboard_provider.dart';
import 'analytics_detail_screen.dart';
import 'balance_details_screen.dart';
import 'widgets/balance_card.dart';
import '../../document/presentation/purchase_requests_summary.dart';
import '../../../shared/widgets/notification_sheet.dart';
import 'widgets/spending_analytics_card.dart';
import 'widgets/transactions_preview_section.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late final DashboardProvider _provider;
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.dashboardReady();
    _provider = DashboardProvider(ApiDashboardRepository())..load();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        bottomNavigationBar: AppNavbar(
            items: vireNavigationItems,
            selectedIndex: 0,
            onDestinationSelected: _selectDestination),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final width =
                constraints.maxWidth > 480 ? 430.0 : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: width,
                child: AnimatedBuilder(
                  animation: _provider,
                  builder: (context, _) {
                    final data = _provider.data ?? DashboardData.empty;
                    return RefreshIndicator(
                      onRefresh: _provider.load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        children: [
                          _DashboardHeader(
                              ownerName: data.ownerName,
                              onNotifications: _showNotifications),
                          const SizedBox(height: 12),
                          BalanceCard(
                            amount: data.totalBalance,
                            isHidden: _hideBalance,
                            onToggleVisibility: () =>
                                setState(() => _hideBalance = !_hideBalance),
                            onDetails: () => _openAndRefresh(
                                BalanceDetailsScreen(data: data)),
                            onPayment: () =>
                                _openAndRefresh(const PaymentScreen()),
                          ),
                          const SizedBox(height: 16),
                          SpendingAnalyticsCard(
                            data: data,
                            aiSummary: _provider.aiSummary,
                            isAiLoading: _provider.isGeneratingInsights,
                            hasAiError: _provider.insightsFailed,
                            onRefreshAi: _refreshAi,
                            onExport: () => _export(
                                '/dashboard/spending/export.csv',
                                'vire-spending.csv'),
                            onViewDetails: () => _openAndRefresh(
                                AnalyticsDetailScreen(
                                    data: data,
                                    insightsRepository:
                                        _provider.insightsRepository)),
                          ),
                          const SizedBox(height: 16),
                          PurchaseRequestsSummary(onChanged: _provider.load),
                          const SizedBox(height: 16),
                          TransactionsPreviewSection(
                            transactions: data.transactions,
                            transactionCount: data.transactionCount,
                            onExport: () => _exportHistory(),
                            onViewAll: () => _goTo(const HistoryScreen()),
                          ),
                          if (_provider.isLoading)
                            const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: LinearProgressIndicator(minHeight: 2)),
                          if (_provider.error != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: TextButton.icon(
                                    onPressed: _provider.load,
                                    icon: const Icon(Icons.refresh),
                                    label:
                                        const Text('Retry loading dashboard'))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
      );

  void _refreshAi() {
    if (_provider.isGeneratingInsights) {
      _showUnavailable(
          'Analysis is still running. You can keep using the dashboard.');
      return;
    }
    _provider.loadInsights(force: true);
  }

  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.push<void>(
        context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _provider.load();
  }

  void _selectDestination(int index) {
    if (index == 0) return;
    if (index == 1) {
      _openAndRefresh(const OwnerPocketListScreen());
      return;
    }
    if (index == 2) {
      _goTo(const OwnerDocumentListScreen());
      return;
    }
    if (index == 3) {
      _goTo(const HistoryScreen());
      return;
    }
    if (index == 4) {
      _goTo(OwnerProfileScreen(displayName: _provider.data?.ownerName));
      return;
    }
    final labels = ['Home', 'Pocket', 'Document', 'History', 'Profile'];
    _showUnavailable('${labels[index]} will be available here.');
  }

  void _goTo(Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => screen),
      (route) => false,
    );
  }

  void _showUnavailable(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _export(String path, String name) async {
    try {
      await ExportService.instance.shareBackendFile(path, fileName: name);
    } catch (error) {
      if (mounted) _showUnavailable(apiErrorMessage(error));
    }
  }

  Future<void> _exportHistory() async {
    try {
      await ExportService.instance.shareHistoryCsv();
    } catch (error) {
      if (mounted) _showUnavailable(apiErrorMessage(error));
    }
  }

  Future<void> _showNotifications() =>
      showNotificationSheet(context, owner: true);
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader(
      {required this.ownerName, required this.onNotifications});
  final String? ownerName;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            ownerName == null || ownerName!.trim().isEmpty
                ? 'Hi!'
                : 'Hi, ${ownerName!.trim()}!',
            style: const TextStyle(
                color: AppColors.orange400,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          Image.asset('assets/images/Regular Images/Logo - V.png',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.flutter_dash,
                  color: AppColors.blue500, size: 30)),
          const Spacer(),
          IconButton(
              onPressed: onNotifications,
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications, color: AppColors.blue500))
        ]),
      ]);
}
