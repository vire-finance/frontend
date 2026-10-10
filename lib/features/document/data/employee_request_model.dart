enum EmployeeRequestStatus { waiting, rejected, accepted }

class EmployeePaymentRequest {
  const EmployeePaymentRequest({
    required this.id,
    required this.reference,
    this.pocketId = '',
    required this.explanation,
    required this.requestType,
    required this.partyName,
    required this.amount,
    required this.neededAt,
    required this.createdAt,
    this.status = EmployeeRequestStatus.waiting,
    this.rejectionReason,
    this.ocrDocumentId,
    this.allowFailedOcr = false,
  });

  final String id;
  final String reference;
  final String pocketId;
  final String explanation;
  final String requestType;
  final String partyName;
  final int amount;
  final DateTime neededAt;
  final DateTime createdAt;
  final EmployeeRequestStatus status;
  final String? rejectionReason;
  final String? ocrDocumentId;
  final bool allowFailedOcr;

  EmployeePaymentRequest withStatus(EmployeeRequestStatus newStatus, {String? reason}) => EmployeePaymentRequest(
        id: id,
        reference: reference,
        pocketId: pocketId,
        explanation: explanation,
        requestType: requestType,
        partyName: partyName,
        amount: amount,
        neededAt: neededAt,
        createdAt: createdAt,
        status: newStatus,
        rejectionReason: reason,
        ocrDocumentId: ocrDocumentId,
        allowFailedOcr: allowFailedOcr,
      );
}

extension EmployeeRequestStatusText on EmployeeRequestStatus {
  String get label => switch (this) {
        EmployeeRequestStatus.waiting => 'Waiting',
        EmployeeRequestStatus.rejected => 'Rejected',
        EmployeeRequestStatus.accepted => 'Accepted',
      };
}
