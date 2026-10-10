import 'package:flutter/material.dart';
import '../payment_entry_form.dart';

class EmployeePaymentScreen extends StatelessWidget {
  const EmployeePaymentScreen({this.scannedCode, super.key});
  final String? scannedCode;
  @override
  Widget build(BuildContext context) => PaymentEntryForm(
      transfer: false, scannedCode: scannedCode, quickActions: true);
}
