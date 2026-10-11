import 'package:flutter/material.dart';

import '../../../../core/network/export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/document_model.dart';
import '../../providers/document_provider.dart';
import '../../../pin/presentation/pin_screen.dart';
import '../widgets/decline_modal.dart';
import 'owner_document_list_screen.dart';
import 'owner_invoice_form_screen.dart';

class OwnerDocumentDetailScreen extends StatelessWidget {
  const OwnerDocumentDetailScreen({
    required this.document,
    required this.provider,
    super.key,
  });

  final DocumentData document;
  final DocumentProvider provider;

  @override
  Widget build(BuildContext context) {
    final waiting = document.status == DocumentStatus.waiting;
    return Scaffold(
      backgroundColor: AppColors.basicWhite,
      appBar: AppBar(
        title: const Text('Document Review', style: TextStyle(color: AppColors.blue900, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        backgroundColor: AppColors.basicWhite,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(children: [
                              Text(document.reference, style: const TextStyle(color: AppColors.blue800, fontSize: 19, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              _Tag(text: document.type ?? 'Document'),
                            ]),
                          ),
                          const SizedBox(height: 104, child: VerticalDivider(color: AppColors.grey100, width: 1)),
                          Expanded(
                            child: Column(children: [
                              const Text('Requested By', style: TextStyle(color: AppColors.blue900, fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              const CircleAvatar(radius: 26, backgroundColor: AppColors.orange50, child: Icon(Icons.person, color: AppColors.grey500)),
                              const SizedBox(height: 6),
                              Text(document.requestedBy ?? '—', style: const TextStyle(color: AppColors.blue500, fontSize: 12), textAlign: TextAlign.center),
                              if (document.requestedByRole?.isNotEmpty == true)
                                Text(document.requestedByRole!, style: const TextStyle(color: AppColors.grey500, fontSize: 11)),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const _SectionTitle('Document Explanation'),
                      const SizedBox(height: 8),
                      Text(document.explanation?.trim().isNotEmpty == true ? document.explanation! : 'No explanation was provided.', style: const TextStyle(color: AppColors.grey700, height: 1.55, fontSize: 12)),
                      const SizedBox(height: 22),
                      const _SectionTitle('Document'),
                      const SizedBox(height: 10),
                      _FileTile(fileName: document.fileName, fileDate: document.fileDate, onDownload: document.fileId == null ? null : () => _downloadDocument(context)),
                      const SizedBox(height: 20),
                      const _SectionTitle('Party Name'),
                      const SizedBox(height: 8),
                      Text(document.partyName?.isNotEmpty == true ? document.partyName! : '—', style: const TextStyle(color: AppColors.grey700, fontSize: 13)),
                      const SizedBox(height: 20),
                      const _SectionTitle('Amount'),
                      const SizedBox(height: 8),
                      Text(formatDocumentAmount(document.amount), style: const TextStyle(color: AppColors.orange500, fontSize: 25, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 20),
                      const _SectionTitle('Date'),
                      const SizedBox(height: 8),
                      Text(_formatDate(document.date), style: const TextStyle(color: AppColors.grey700, fontSize: 13)),
                      const SizedBox(height: 20),
                      _AnalysisBox(text: document.aiAnalysis),
                      if (document.status == DocumentStatus.rejected && document.declineReason != null) ...[
                        const SizedBox(height: 18),
                        const _SectionTitle('Decline Reason'),
                        const SizedBox(height: 6),
                        Text(document.declineReason!, style: const TextStyle(color: AppColors.grey700)),
                      ],
                    ],
                  ),
                ),
                if (waiting)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    child: Column(children: [
                      SizedBox(width: double.infinity, height: 48, child: FilledButton(onPressed: () => _decline(context), child: const Text('Decline'))),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, height: 48, child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OwnerInvoiceFormScreen(document: document, provider: provider))), style: FilledButton.styleFrom(backgroundColor: AppColors.blue100, foregroundColor: AppColors.blue600), child: const Text('Approve & Pay Invoice'))),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _decline(BuildContext context) async {
    final reason = await DocumentActionModal.showDecline(context);
    if (reason == null || reason.isEmpty || !context.mounted) return;
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PinScreen(
      title: 'Enter Your Pin',
      showSuccessModal: false,
      onPinSubmitted: (pin) async {
        try {
          final token = await AuthRepository.instance.verifyPin(pin, actionType: 'APPROVAL');
          await provider.rejectRequest(document.id, reason, token);
        } catch (error) {
          throw Exception(apiErrorMessage(error));
        }
      },
      onPinComplete: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const OwnerDocumentListScreen()),
        (route) => false,
      ),
    )));
  }

  Future<void> _downloadDocument(BuildContext context) async {
    if (document.fileId == null) return;
    try {
      await ExportService.instance.shareBackendFile(
        '/fund-requests/${document.id}/documents/${document.fileId}/file',
        query: const {'download': true},
        fileName: document.fileName ?? 'request-document',
      );
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
    }
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '—';
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(border: Border.all(color: AppColors.orange400), borderRadius: BorderRadius.circular(5)), child: Text(text, style: const TextStyle(color: AppColors.orange600, fontSize: 12)));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: AppColors.blue500, fontSize: 15, fontWeight: FontWeight.w700));
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.fileName, required this.fileDate, this.onDownload});
  final String? fileName;
  final DateTime? fileDate;
  final VoidCallback? onDownload;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(border: Border.all(color: AppColors.grey50), borderRadius: BorderRadius.circular(17)),
        child: Row(children: [
          const Icon(Icons.picture_as_pdf_outlined, color: AppColors.red500, size: 28),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(fileName ?? 'No document attached', style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(fileDate == null ? '—' : OwnerDocumentDetailScreen._formatDate(fileDate), style: const TextStyle(color: AppColors.grey600, fontSize: 11))])),
          IconButton(onPressed: fileName == null ? null : onDownload, icon: const Icon(Icons.download, color: AppColors.blue500)),
        ]),
      );
}

class _AnalysisBox extends StatelessWidget {
  const _AnalysisBox({required this.text});
  final String? text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.blue50, border: Border.all(color: AppColors.blue300), borderRadius: BorderRadius.circular(17)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.auto_awesome, color: AppColors.blue500, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('AI Analysis', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w700, fontSize: 12)), const SizedBox(height: 4), Text(text?.trim().isNotEmpty == true ? text! : 'Analysis will appear when document review data is available.', style: const TextStyle(color: AppColors.blue500, height: 1.45, fontSize: 12))])),
        ]),
      );
}

