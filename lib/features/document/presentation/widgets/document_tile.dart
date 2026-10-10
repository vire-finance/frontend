import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/document_model.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile({required this.document, required this.onTap, super.key});

  final DocumentData document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (document.status) {
      DocumentStatus.waiting => AppColors.orange400,
      DocumentStatus.rejected => AppColors.red500,
      DocumentStatus.accepted || DocumentStatus.paid => AppColors.green500,
    };
    final date = document.date == null
        ? '—'
        : '${document.date!.year.toString().padLeft(4, '0')}-'
            '${document.date!.month.toString().padLeft(2, '0')}-'
            '${document.date!.day.toString().padLeft(2, '0')}';
    final description = [date, document.category]
        .where((part) => part != null && part.isNotEmpty)
        .join(' | ');

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.grey50),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 12, 14, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(document.reference,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(
                      description.isEmpty ? '—' : description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      document.status.label,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatDocumentAmount(document.amount),
                    style: const TextStyle(
                      color: AppColors.grey700,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
