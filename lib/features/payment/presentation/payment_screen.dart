import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import 'payment_entry_form.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _camera = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _opening = false;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _open(Widget screen) async {
    if (_opening) return;
    _opening = true;
    try {
      await _camera.stop();
      if (!mounted) return;
      await Navigator.of(context)
          .push<void>(MaterialPageRoute(builder: (_) => screen));
    } finally {
      _opening = false;
      if (mounted) await _camera.start();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_opening) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _open(PaymentEntryForm(transfer: false, scannedCode: code));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
          title: const Text('Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          centerTitle: true,
          backgroundColor: AppColors.basicWhite,
          foregroundColor: AppColors.blue900,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 20),
                        child: AspectRatio(
                          aspectRatio: 1.08,
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.grey100, width: 0.7),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                MobileScanner(
                                  controller: _camera,
                                  onDetect: _onDetect,
                                  errorBuilder: (context, error, child) =>
                                      const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.no_photography_outlined,
                                              color: AppColors.blue500,
                                              size: 40),
                                          SizedBox(height: 12),
                                          Text(
                                              'Camera unavailable. Allow camera access to scan a QR code.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: AppColors.grey600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  child: Center(
                                    child: Container(
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        color: AppColors.blue300,
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppColors.blue300,
                                              blurRadius: 8,
                                              spreadRadius: 2)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    decoration: BoxDecoration(
                      color: AppColors.basicWhite,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(30)),
                      border: Border.all(color: AppColors.grey100, width: 0.7),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Also Pay With',
                            style: TextStyle(
                                color: AppColors.blue600,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _PaymentAction(
                                    icon: Icons.qr_code_2,
                                    label: 'Show QR Code',
                                    onTap: () => _open(const PaymentEntryForm(
                                        transfer: false, showQrCode: true)))),
                            const SizedBox(width: 24),
                            Expanded(
                                child: _PaymentAction(
                                    icon: Icons.account_balance,
                                    label: 'Transfer',
                                    onTap: () => _open(const PaymentEntryForm(
                                        transfer: true)))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _PaymentAction extends StatelessWidget {
  const _PaymentAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.grey100, width: 0.7)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 98,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: AppColors.blue600),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.blue600,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}
