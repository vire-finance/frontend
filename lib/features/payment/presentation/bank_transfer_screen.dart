import 'package:flutter/material.dart';

import 'payment_entry_form.dart';

class BankTransferScreen extends StatelessWidget {
  const BankTransferScreen({super.key});

  @override
  Widget build(BuildContext context) => const PaymentEntryForm(transfer: true);
}
