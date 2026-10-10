import 'package:flutter/foundation.dart';

import 'payment_model.dart';

class PaymentRepository extends ChangeNotifier {
  PaymentRepository._();

  static final instance = PaymentRepository._();

  PaymentDraft? _lastCompletedPayment;
  PaymentDraft? get lastCompletedPayment => _lastCompletedPayment;

  PaymentDraft complete(PaymentDraft draft,
      {String? transactionId, DateTime? completedAt}) {
    final completed = draft.completed(
      transactionId: transactionId,
      time: completedAt ?? DateTime.now(),
    );
    _lastCompletedPayment = completed;
    notifyListeners();
    return completed;
  }
}
