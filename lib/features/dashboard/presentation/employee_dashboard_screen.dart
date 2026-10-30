import 'package:flutter/material.dart';
import '../../../core/services/push_notification_service.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/export_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_nav_shell.dart';
import '../../../shared/widgets/notification_sheet.dart';
import '../../document/data/employee_request_model.dart';
import '../../document/data/employee_request_repository.dart';
import '../../document/presentation/employee/employee_document_list_screen.dart';
import '../../history/data/transaction_repository.dart';
import '../../history/presentation/history_screen.dart';
import '../../payment/presentation/employee/employee_payment_screen.dart';
import '../../pocket/data/employee_pocket_repository.dart';
import '../../pocket/presentation/employee/employee_pocket_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/dashboard_model.dart';
import 'widgets/balance_card.dart';
import 'widgets/pending_requests_section.dart';
import 'widgets/transactions_preview_section.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  bool _hideBalance = false;
  int? _totalBalance;
  String? _displayName;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.dashboardReady();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dashboardResponse =
          await ApiClient.instance.dio.get<Map<String, dynamic>>('/dashboard');
      await Future.wait<void>([
        EmployeePocketRepository.instance.load(),
        EmployeeRequestRepository.instance.load(),
        TransactionRepository.instance.load(),
      ]);
      final data = dashboardResponse.data!;
      if (!mounted) return;
      setState(() {
        _totalBalance = (data['total_balance'] as num?)?.round();
        _displayName = data['name'] as String?;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = apiErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = Listenable.merge([
      EmployeePocketRepository.instance,
      EmployeeRequestRepository.instance,
      TransactionRepository.instance,
    ]);
    return AnimatedBuilder(
      animation: sources,
      builder: (context, _) {
        final requests = EmployeeRequestRepository.instance.requests
            .where((request) => request.status == EmployeeRequestStatus.waiting)
            .map((request) => PaymentRequest(
                  id: request.id,
                  reference: request.reference,
                  createdAt: _dateLabel(request.createdAt),
                  description: '${request.requestType} · ${request.partyName}',
                  amount: request.amount,
                  status: request.status.label,
                ))
            .toList();
        final transactions = TransactionRepository.instance.transactions
            .map((transaction) => DashboardTransaction(
                  id: transaction.id,
                  merchant: transaction.title,
                  date: _dateLabel(transaction.dateTime),
                  category: transaction.category ?? transaction.paymentMethod,
                  amount: transaction.amount,
                ))
            .toList();
        return Scaffold(
          backgroundColor: AppColors.basicWhite,
          bottomNavigationBar: AppNavbar(
            items: employeeNavigationItems,
            selectedIndex: 0,
            onDestinationSelected: _selectDestination,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Row(children: [
                      Image.asset('assets/images/Regular Images/Logo - V.png',
                          width: 30, height: 30, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            _displayName == null
                                ? 'Dashboard'
                                : 'Hi, $_displayName!',
                            style: const TextStyle(
                                color: AppColors.blue800,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                          tooltip: 'Notifications',
                          icon: const Icon(Icons.notifications,
                              color: AppColors.blue500),
                          onPressed: () =>
                              showNotificationSheet(context, owner: false)),
                    ]),
                    const SizedBox(height: 14),
                    BalanceCard(
                      amount: _totalBalance,
                      isHidden: _hideBalance,
                      onToggleVisibility: () =>
                          setState(() => _hideBalance = !_hideBalance),
                      onDetails: () => _selectDestination(1),
                      onPayment: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => const EmployeePaymentScreen()));
                        if (mounted) await _loadData();
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_loadError != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(_loadError!,
                              style: const TextStyle(
                                  color: AppColors.red700, fontSize: 12))),
                    PendingRequestsSection(
                        requests: requests, requestCount: requests.length),
                    const SizedBox(height: 16),
                    TransactionsPreviewSection(
                      transactions: transactions,
                      transactionCount: transactions.length,
                      onViewAll: () => _selectDestination(3),
                      onExport: () => ExportService.instance.shareHistoryCsv(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectDestination(int index) {
    if (index == 0) return;
    final Widget? screen = switch (index) {
      1 => const EmployeePocketListScreen(),
      2 => const EmployeeDocumentListScreen(),
      3 => const HistoryScreen(employee: true),
      4 => const EmployeeProfileScreen(),
      _ => null,
    };
    if (screen != null) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => screen), (route) => false);
    }
  }

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
