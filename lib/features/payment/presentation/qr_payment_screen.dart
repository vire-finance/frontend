import 'package:flutter/material.dart';

import 'payment_entry_form.dart';

class QrPaymentScreen extends StatelessWidget {
  const QrPaymentScreen({this.scannedCode, super.key});
  final String? scannedCode;

  @override
  Widget build(BuildContext context) =>
      PaymentEntryForm(transfer: false, scannedCode: scannedCode);
}
