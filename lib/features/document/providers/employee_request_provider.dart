import 'package:flutter/foundation.dart';

import '../data/employee_request_model.dart';
import '../data/employee_request_repository.dart';

class EmployeeRequestProvider extends ChangeNotifier {
  EmployeeRequestProvider(this._repository) {
    _repository.addListener(_sync);
    _requests = _repository.requests;
  }

  final EmployeeRequestRepository _repository;
  List<EmployeePaymentRequest> _requests = const [];
  List<EmployeePaymentRequest> get requests => _requests;

  void _sync() {
    _requests = _repository.requests;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.removeListener(_sync);
    super.dispose();
  }
}
