import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/payment_model.dart';
import '../../document/presentation/purchase_requests_screen.dart';
import 'receipt_export_service.dart';

class TransactionCompleteScreen extends StatefulWidget {
  const TransactionCompleteScreen({
    required PaymentDraft this.payment,
    this.receiptRequestId,
    super.key,
  })  : sourceAccount = null,
        transactionId = null,
        completedAt = null,
        amount = null,
        onBack = null,
        isTopUp = false;

  const TransactionCompleteScreen.topUp({
    required this.sourceAccount,
    required this.transactionId,
    required this.completedAt,
    required this.amount,
    required this.onBack,
    super.key,
  })  : payment = null,
        isTopUp = true,
        receiptRequestId = null;

  final PaymentDraft? payment;
  final String? sourceAccount;
  final String? transactionId;
  final DateTime? completedAt;
  final int? amount;
  final VoidCallback? onBack;
  final bool isTopUp;
  final String? receiptRequestId;

  @override
  State<TransactionCompleteScreen> createState() =>
      _TransactionCompleteScreenState();
}

class _TransactionCompleteScreenState extends State<TransactionCompleteScreen> {
  final _receiptKey = GlobalKey();
  bool _exporting = false;
  PaymentDraft? get payment => widget.payment;
  String? get sourceAccount => widget.sourceAccount;
  String? get transactionId => widget.transactionId;
  DateTime? get completedAt => widget.completedAt;
  int? get amount => widget.amount;
  VoidCallback? get onBack => widget.onBack;
  bool get isTopUp => widget.isTopUp;
  String? get receiptRequestId => widget.receiptRequestId;

  @override
  Widget build(BuildContext context) {
    final date = completedAt ?? payment?.completedAt;
    final dateText = date == null
        ? '—'
        : '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return LayoutBuilder(
      builder: (context, viewport) {
        final width = viewport.maxWidth.clamp(0.0, 480.0);
        final imageHeight =
            ((viewport.maxHeight - MediaQuery.paddingOf(context).vertical) *
                    0.25)
                .clamp(145.0, 220.0);
        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              width: width,
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    key: _receiptKey,
                    child: Material(
                      color: AppColors.basicWhite,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
                        child: _receiptContent(
                          imageHeight,
                          dateText,
                          actions: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Scaffold(
              backgroundColor: AppColors.basicWhite,
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final imageHeight =
                            (constraints.maxHeight * 0.25).clamp(145.0, 220.0);
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _receiptContent(
                                imageHeight,
                                dateText,
                                actions: true,
                              ),
                              const SizedBox(height: 44),
                              if (receiptRequestId != null) ...[
                                const Text(
                                  'Attach your receipt within 48 hours. You can also upload it later from History.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.blue700),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          PurchaseRequestDetailScreen(
                                        id: receiptRequestId!,
                                        owner: false,
                                        receiptOnly: true,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Attach Receipt'),
                                ),
                                const SizedBox(height: 12),
                              ],
                              SizedBox(
                                height: 48,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.blue400,
                                    foregroundColor: AppColors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: onBack ??
                                      () => Navigator.of(context)
                                          .popUntil((route) => route.isFirst),
                                  child: const Text('Back'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _receiptContent(
    double imageHeight,
    String dateText, {
    required bool actions,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'assets/images/Regular Images/Transaction Success.png',
            height: imageHeight,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.check_circle,
              color: AppColors.green500,
              size: 140,
            ),
          ),
          const SizedBox(height: 18),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Transaction Complete!',
              style: TextStyle(
                color: AppColors.blue500,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isTopUp
                ? 'Funds added successfully. Your capital is ready for your next business expense.'
                : 'Another business expense tracked perfectly. Your capital is secure, your operations are moving.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grey700,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (actions)
            Row(
              children: [
                Expanded(
                  child: _ReceiptAction(
                    label: 'Share',
                    icon: Icons.share_outlined,
                    onPressed: () => _shareImage(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReceiptAction(
                    label: 'Print',
                    icon: Icons.print_outlined,
                    onPressed: () => _sharePdf(context),
                  ),
                ),
              ],
            ),
          if (actions) const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(19, 12, 19, 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.grey100, width: 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: 'Source Account/Card',
                  value: sourceAccount ?? payment!.sourceCard.name,
                ),
                _DetailRow(
                  label: 'Transaction ID',
                  value: transactionId ?? payment?.transactionId ?? '—',
                ),
                _DetailRow(label: 'Date & Time', value: dateText),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${isTopUp ? '+' : '-'}${formatPaymentAmount(amount ?? payment!.amount)}',
                      style: const TextStyle(
                        color: AppColors.orange400,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  static String _month(int value) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][value - 1];
  Future<void> _shareImage(BuildContext context) async {
    if (_exporting) return;
    _exporting = true;
    try {
      await ReceiptExportService.sharePng(_receiptKey);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    } finally {
      _exporting = false;
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      await ReceiptExportService.sharePdf(
        account: sourceAccount ?? payment!.sourceCard.name,
        id: transactionId ?? payment?.transactionId ?? '—',
        date: completedAt == null && payment?.completedAt == null
            ? '—'
            : '${(completedAt ?? payment!.completedAt)!.day.toString().padLeft(2, '0')} ${_month((completedAt ?? payment!.completedAt)!.month)} ${(completedAt ?? payment!.completedAt)!.year}, ${(completedAt ?? payment!.completedAt)!.hour.toString().padLeft(2, '0')}:${(completedAt ?? payment!.completedAt)!.minute.toString().padLeft(2, '0')}',
        amount: formatPaymentAmount(amount ?? payment!.amount),
        isTopUp: isTopUp,
        recipient: payment?.destination == null
            ? payment?.title
            : '${payment!.destination!.name}\n${payment!.destination!.display}',
      );
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  static void _showError(BuildContext context, Object error) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not export receipt: $error'),
          duration: const Duration(seconds: 3),
        ),
      );
}

class _ReceiptAction extends StatelessWidget {
  const _ReceiptAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.blue700,
            side: const BorderSide(color: AppColors.blue700, width: 1.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 17),
            ],
          ),
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.grey600, fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.blue600,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}
