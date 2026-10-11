const destinationBanks = [
  'BCA',
  'BRI',
  'BNI',
  'Mandiri',
  'BTN',
  'CIMB Niaga',
  'PermataBank',
  'Bank Syariah Indonesia (BSI)',
  'Danamon',
  'OCBC',
  'Other'
];
const destinationWallets = ['DANA', 'GoPay', 'OVO', 'ShopeePay', 'LinkAja'];

class PaymentDestination {
  const PaymentDestination(
      {required this.paymentType,
      required this.name,
      required this.accountNumber,
      this.bankName});
  final String paymentType, name, accountNumber;
  final String? bankName;
  String get display => '${bankName ?? name} $accountNumber';
  Map<String, dynamic> toJson() => {
        'payment_type': paymentType,
        'destination_name': name,
        'destination_account_number': accountNumber,
        if (bankName != null) 'destination_bank_name': bankName,
      };
}
