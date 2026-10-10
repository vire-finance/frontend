import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/employee_request_model.dart';

class EmployeeDocumentDetailScreen extends StatelessWidget {
  const EmployeeDocumentDetailScreen({required this.request, super.key});
  final EmployeePaymentRequest request;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(title: const Text('Request Details', style: TextStyle(color: AppColors.blue900, fontSize: 18, fontWeight: FontWeight.w700)), centerTitle: true, backgroundColor: AppColors.basicWhite, foregroundColor: AppColors.blue900, elevation: 0),
        body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
          Row(children: [Expanded(child: Column(children: [Text(request.reference, style: const TextStyle(color: AppColors.blue800, fontSize: 19, fontWeight: FontWeight.w700)), const SizedBox(height: 10), _StatusPill(status: request.status)])), const SizedBox(height: 80, child: VerticalDivider(color: AppColors.grey100)), Expanded(child: Column(children: [const Text('Requested By', style: TextStyle(color: AppColors.blue900, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 8), const CircleAvatar(radius: 24, backgroundColor: AppColors.orange50, child: Icon(Icons.person_outline, color: AppColors.grey500)), const SizedBox(height: 5), const Text('You', style: TextStyle(color: AppColors.blue500, fontSize: 12))]))]),
          const SizedBox(height: 24),
          const _Heading('Request Explanation'),
          const SizedBox(height: 8),
          Text(request.explanation, style: const TextStyle(color: AppColors.grey700, fontSize: 13, height: 1.5)),
          const SizedBox(height: 22),
          const _Heading('Request Type'),
          const SizedBox(height: 8),
          Text(request.requestType, style: const TextStyle(color: AppColors.grey700, fontSize: 13)),
          const SizedBox(height: 22),
          const _Heading('Party Name'),
          const SizedBox(height: 8),
          Text(request.partyName, style: const TextStyle(color: AppColors.grey700, fontSize: 13)),
          const SizedBox(height: 22),
          const _Heading('Amount'),
          const SizedBox(height: 8),
          Text(_money(request.amount), style: const TextStyle(color: AppColors.orange500, fontSize: 25, fontWeight: FontWeight.w700)),
          const SizedBox(height: 22),
          const _Heading('Needed By'),
          const SizedBox(height: 8),
          Text(_date(request.neededAt), style: const TextStyle(color: AppColors.grey700, fontSize: 13)),
          if (request.status == EmployeeRequestStatus.rejected && request.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 22),
            const _Heading('Reason for Rejection'),
            const SizedBox(height: 8),
            Text(request.rejectionReason!, style: const TextStyle(color: AppColors.red700, fontSize: 13)),
          ],
          if (request.status == EmployeeRequestStatus.waiting) ...[
            const SizedBox(height: 24),
            const Text('This request is waiting for the owner’s review.', style: TextStyle(color: AppColors.grey500, fontSize: 12)),
          ],
        ])))),
      );

  static String _money(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return 'IDR $out';
  }

  static String _date(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: AppColors.blue500, fontSize: 15, fontWeight: FontWeight.w700));
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final EmployeeRequestStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) { EmployeeRequestStatus.waiting => AppColors.orange500, EmployeeRequestStatus.accepted => AppColors.green500, EmployeeRequestStatus.rejected => AppColors.red500 };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .12), border: Border.all(color: color), borderRadius: BorderRadius.circular(8)), child: Text(status.label, style: TextStyle(color: color, fontSize: 12)));
  }
}
