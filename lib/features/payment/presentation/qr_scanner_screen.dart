import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import 'qr_payment_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({this.onCodeScanned, super.key});
  final ValueChanged<String>? onCodeScanned;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
            title: const Text('Scan QRIS'),
            centerTitle: true,
            backgroundColor: AppColors.basicWhite,
            foregroundColor: AppColors.blue900,
            elevation: 0),
        body: Stack(fit: StackFit.expand, children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
              child: Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.blue400, width: 3),
                      borderRadius: BorderRadius.circular(24)))),
          const Positioned(
              left: 24,
              right: 24,
              bottom: 36,
              child: Text('Place a QR code inside the frame to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600))),
        ]),
      );

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final values = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList();
    if (values.isEmpty) return;
    final code = values.first;
    _handled = true;
    final onCodeScanned = widget.onCodeScanned;
    if (onCodeScanned != null) {
      onCodeScanned(code);
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => QrPaymentScreen(scannedCode: code)));
  }
}
