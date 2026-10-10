class TransactionData {
  const TransactionData({
    required this.id,
    required this.title,
    required this.amount,
    required this.sourceAccount,
    required this.dateTime,
    required this.paymentMethod,
    this.category,
    this.transactionId,
    this.location,
    this.acquirer,
    this.fee,
    this.status = 'APPROVED',
    this.cardId,
    this.pocketId,
    this.failureReason,
    this.requestId,
  });

  final String id;
  final String title;
  final int amount;
  final String sourceAccount;
  final DateTime dateTime;
  final String paymentMethod;
  final String? category;
  final String? transactionId;
  final String? location;
  final String? acquirer;
  final int? fee;
  final String status;
  final String? cardId;
  final String? pocketId;
  final String? failureReason;
  final String? requestId;
}

String formatTransactionAmount(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return 'IDR $buffer';
}

String formatTransactionDate(DateTime dateTime) =>
    '${dateTime.day.toString().padLeft(2, '0')} ${_monthName(dateTime.month)} ${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

String _monthName(int month) => const [
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
    ][month - 1];
