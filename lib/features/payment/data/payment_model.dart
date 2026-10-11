export '../../../core/constants/expense_categories.dart';
import 'payment_destination.dart';
import '../../pocket/presentation/owner/owner_card_form.dart';

enum PaymentKind { qris, bank, eWallet }

class PaymentDraft {
  const PaymentDraft({
    required this.kind,
    required this.title,
    required this.amount,
    required this.sourceCard,
    this.category = 'Others',
    this.destinationMethod,
    this.destination,
    this.scannedCode,
    this.transactionId,
    this.completedAt,
  });

  final PaymentKind kind;
  final String category;
  final String title;
  final int amount;
  final VireCardData sourceCard;
  final String? destinationMethod;
  final PaymentDestination? destination;
  final String? scannedCode;
  final String? transactionId;
  final DateTime? completedAt;

  PaymentDraft completed({String? transactionId, required DateTime time}) =>
      PaymentDraft(
        kind: kind,
        category: category,
        title: title,
        amount: amount,
        sourceCard: sourceCard,
        destinationMethod: destinationMethod,
        destination: destination,
        scannedCode: scannedCode,
        transactionId: transactionId,
        completedAt: time,
      );
}

String formatPaymentAmount(int amount) {
  final digits = amount.abs().toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write(',');
    output.write(digits[index]);
  }
  return 'IDR $output';
}
