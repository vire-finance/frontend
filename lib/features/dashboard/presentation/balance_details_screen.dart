import 'package:flutter/material.dart';
import '../data/dashboard_model.dart';
import '../../funding/presentation/fund_account_screen.dart';

class BalanceDetailsScreen extends StatelessWidget {
  const BalanceDetailsScreen({required this.data, super.key});
  final DashboardData data;
  @override
  Widget build(BuildContext context) => const FundAccountScreen();
}
