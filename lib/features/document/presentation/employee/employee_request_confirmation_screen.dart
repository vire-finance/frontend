import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/employee_request_model.dart';

class EmployeeRequestConfirmationScreen extends StatelessWidget {
  const EmployeeRequestConfirmationScreen({required this.request, super.key});
  final EmployeePaymentRequest request;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(title: const Text('Request Submitted', style: TextStyle(color: AppColors.blue900, fontSize: 18, fontWeight: FontWeight.w700)), centerTitle: true, backgroundColor: AppColors.basicWhite, foregroundColor: AppColors.blue900, elevation: 0),
        body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
          const Spacer(),
          Image.asset('assets/images/Regular Images/Mascot - Unsure.png', height: 150, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.hourglass_top_rounded, size: 110, color: AppColors.blue400)),
          const SizedBox(height: 16),
          const Text('Request Submitted!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.blue500, fontWeight: FontWeight.w700, fontSize: 25)),
          const SizedBox(height: 8),
          const Text('Your payment request is waiting for the owner to review.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey700, fontSize: 14, height: 1.45)),
          const SizedBox(height: 22),
          Container(width: double.infinity, padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.grey50), borderRadius: BorderRadius.circular(18)), child: Column(children: [
            _Line(label: 'Request ID', value: request.reference),
            _Line(label: 'Request Type', value: request.requestType),
            _Line(label: 'Party Name', value: request.partyName),
            _Line(label: 'Needed By', value: _date(request.neededAt)),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerRight, child: Text(_money(request.amount), style: const TextStyle(color: AppColors.orange500, fontWeight: FontWeight.w700, fontSize: 22))),
          ])),
          const Spacer(),
          SizedBox(width: double.infinity, height: 48, child: FilledButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Back to Requests'))),
        ]))))),
      );

  static String _date(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static String _money(int amount) {
    final digits = amount.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return 'IDR $out';
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: AppColors.grey600))), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.blue700, fontWeight: FontWeight.w600)))]));
}
