import 'package:flutter/material.dart';
import '../payment_entry_form.dart';
import '../payment_screen.dart';

class EmployeePaymentScreen extends StatelessWidget {
  const EmployeePaymentScreen({this.scannedCode, super.key});
  final String? scannedCode;
  @override
  Widget build(BuildContext context) => scannedCode == null
      ? const PaymentScreen()
      : PaymentEntryForm(transfer: false, scannedCode: scannedCode);
}
