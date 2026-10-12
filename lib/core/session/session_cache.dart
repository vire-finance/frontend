import '../../features/document/data/document_repository.dart';
import '../../features/document/data/employee_request_repository.dart';
import '../../features/history/data/transaction_repository.dart';
import '../../features/payment/data/payment_repository.dart';
import '../../features/pocket/data/employee_pocket_repository.dart';
import '../../features/pocket/data/pocket_repository.dart';

/// Central purge point for account-specific in-memory caches.
///
/// All listed repositories are process-lifetime singletons. Their contents
/// belong to exactly one authenticated account and must never survive a
/// logout, an account switch, or a session invalidation. Each repository's
/// [clear] also invalidates its in-flight requests via a generation guard,
/// so a late response from a previous session is discarded instead of
/// repopulating the cleared cache.
class SessionCaches {
  SessionCaches._();

  static void clearAll() {
    TransactionRepository.instance.clear();
    PocketRepository.instance.clear();
    EmployeePocketRepository.instance.clear();
    DocumentRepository.instance.clear();
    EmployeeRequestRepository.instance.clear();
    PaymentRepository.instance.clear();
  }
}
