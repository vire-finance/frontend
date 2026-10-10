import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/employee_request_model.dart';

class EmployeeRequestTile extends StatelessWidget {
  const EmployeeRequestTile({required this.request, required this.onTap, super.key});
  final EmployeePaymentRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (request.status) {
      EmployeeRequestStatus.waiting => AppColors.orange400,
      EmployeeRequestStatus.rejected => AppColors.red500,
      EmployeeRequestStatus.accepted => AppColors.green500,
    };
    final date = '${request.createdAt.year.toString().padLeft(4, '0')}-${request.createdAt.month.toString().padLeft(2, '0')}-${request.createdAt.day.toString().padLeft(2, '0')}';
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.grey50)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 12, 14, 11),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(request.reference, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text('$date | ${request.requestType} | ${request.partyName}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.4)),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Text(request.status.label, style: const TextStyle(color: Colors.white, fontSize: 10))),
              const SizedBox(height: 8),
              Text(_formatAmount(request.amount), style: const TextStyle(color: AppColors.grey700, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ]),
        ),
      ),
    );
  }

  static String _formatAmount(int amount) => 'IDR ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';
}
