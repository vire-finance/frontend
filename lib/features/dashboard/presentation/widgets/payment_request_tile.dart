import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/dashboard_model.dart';

class PaymentRequestTile extends StatelessWidget {
  const PaymentRequestTile({required this.request, this.onTap, super.key});
  final PaymentRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.grey50),
                borderRadius: BorderRadius.circular(16)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(request.reference,
                        style: const TextStyle(fontWeight: FontWeight.w500))),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.orange400,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(request.status,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10)))
              ]),
              const SizedBox(height: 5),
              Row(children: [
                Expanded(
                    child: Text('${request.createdAt} | ${request.description}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, height: 1.4))),
                const SizedBox(width: 8),
                Text(formatDashboardAmount(request.amount),
                    style: const TextStyle(
                        color: AppColors.grey700,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ]),
            ]),
          )));
}
