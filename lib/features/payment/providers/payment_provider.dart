import 'package:flutter/foundation.dart';

import '../data/payment_model.dart';
import '../data/payment_repository.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider(this._repository);

  final PaymentRepository _repository;
  PaymentDraft? _completedPayment;
  PaymentDraft? get completedPayment => _completedPayment;

  PaymentDraft complete(
    PaymentDraft draft, {
    String? transactionId,
    DateTime? completedAt,
  }) {
    _completedPayment = _repository.complete(
      draft,
      transactionId: transactionId,
      completedAt: completedAt,
    );
    notifyListeners();
    return _completedPayment!;
  }
}
