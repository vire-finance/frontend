import 'package:flutter/material.dart';

class DashboardData {
  const DashboardData({
    this.ownerName,
    this.totalBalance,
    this.monthlyLimit,
    this.balanceCurrency = 'IDR',
    this.pendingRequestCount,
    this.transactionCount,
    this.spendingCategories = const [],
    this.pendingRequests = const [],
    this.transactions = const [],
    this.aiInsight,
  });

  final String? ownerName;
  final int? totalBalance;
  final int? monthlyLimit;
  final String balanceCurrency;
  final int? pendingRequestCount;
  final int? transactionCount;
  final List<SpendingCategory> spendingCategories;
  final List<PaymentRequest> pendingRequests;
  final List<DashboardTransaction> transactions;
  final String? aiInsight;

  static const empty = DashboardData();
}

class SpendingCategory {
  const SpendingCategory(
      {required this.name,
      required this.amount,
      required this.share,
      required this.color});
  final String name;
  final int amount;
  final double share;
  final Color color;
}

class PaymentRequest {
  const PaymentRequest(
      {required this.id,
      required this.reference,
      required this.createdAt,
      required this.description,
      required this.amount,
      required this.status});
  final String id;
  final String reference;
  final String createdAt;
  final String description;
  final int amount;
  final String status;
}

class DashboardTransaction {
  const DashboardTransaction(
      {required this.id,
      required this.merchant,
      required this.date,
      required this.category,
      required this.amount,
      this.currency = 'IDR'});
  final String id;
  final String merchant;
  final String date;
  final String category;
  final int amount;
  final String currency;
}

String formatDashboardAmount(int? value, {String currency = 'IDR'}) {
  if (value == null) return '—';
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '$currency $buffer';
}
