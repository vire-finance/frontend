enum DocumentStatus { waiting, rejected, accepted, paid }

class DocumentData {
  const DocumentData({
    required this.id,
    required this.reference,
    required this.amount,
    this.pocketId,
    this.status = DocumentStatus.waiting,
    this.date,
    this.type,
    this.category,
    this.explanation,
    this.fileName,
    this.fileId,
    this.fileDate,
    this.partyName,
    this.requestedBy,
    this.requestedByRole,
    this.aiAnalysis,
    this.declineReason,
  });

  final String id;
  final String reference;
  final int amount;
  final String? pocketId;
  final DocumentStatus status;
  final DateTime? date;
  final String? type;
  final String? category;
  final String? explanation;
  final String? fileName;
  final String? fileId;
  final DateTime? fileDate;
  final String? partyName;
  final String? requestedBy;
  final String? requestedByRole;
  final String? aiAnalysis;
  final String? declineReason;

  DocumentData copyWith({DocumentStatus? status, String? declineReason}) =>
      DocumentData(
        id: id,
        reference: reference,
        amount: amount,
        pocketId: pocketId,
        status: status ?? this.status,
        date: date,
        type: type,
        category: category,
        explanation: explanation,
        fileName: fileName,
        fileId: fileId,
        fileDate: fileDate,
        partyName: partyName,
        requestedBy: requestedBy,
        requestedByRole: requestedByRole,
        aiAnalysis: aiAnalysis,
        declineReason: declineReason ?? this.declineReason,
      );
}

extension DocumentStatusLabel on DocumentStatus {
  String get label => switch (this) {
        DocumentStatus.waiting => 'Waiting',
        DocumentStatus.rejected => 'Rejected',
        DocumentStatus.accepted => 'Accepted',
        DocumentStatus.paid => 'Paid',
      };
}

String formatDocumentAmount(int amount, {String currency = 'IDR'}) {
  final digits = amount.abs().toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write(',');
    output.write(digits[index]);
  }
  return '$currency $output';
}
