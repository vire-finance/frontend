import 'package:flutter/painting.dart';

class FundSource {
  const FundSource(this.name, this.assetName, this.accountType, this.primaryColor);
  final String name;
  final String assetName;
  final String accountType;
  final Color primaryColor;
  String get logoPath => 'assets/images/${accountType == 'BANK' ? 'Logo Bank' : 'Logo E-Wallet'}/$assetName';
}

abstract final class FundSources {
  static const banks = [
    FundSource('Bank BCA', 'BCA.png', 'BANK', Color(0xFF0030A0)),
    FundSource('Bank Mandiri', 'MANDIRI.png', 'BANK', Color(0xFF004070)),
    FundSource('Bank BNI', 'BNI.png', 'BANK', Color(0xFF006070)),
    FundSource('Bank Jakarta', 'BANK JAKARTA.png', 'BANK', Color(0xFFFF4010)),
    FundSource('Bank Jago', 'BANK JAGO.png', 'BANK', Color(0xFFFFB020)),
    FundSource('Bank BRI', 'BANK BRI.png', 'BANK', Color(0xFF0050C0)),
  ];
  static const wallets = [
    FundSource('DANA', 'Dana.webp', 'E_WALLET', Color(0xFF1090F0)),
    FundSource('GoPay', 'Gopay.png', 'E_WALLET', Color(0xFF00B0E0)),
    FundSource('I.Saku', 'I.Saku.jpg', 'E_WALLET', Color(0xFF00A0C0)),
    FundSource('Jenius', 'Jenius.png', 'E_WALLET', Color(0xFF00B0F0)),
    FundSource('OVO', 'OVO.jpg', 'E_WALLET', Color(0xFF503090)),
    FundSource('ShopeePay', 'ShopeePay.jpg', 'E_WALLET', Color(0xFFF05030)),
  ];
  static String _normalize(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').replaceFirst(RegExp(r'^bank'), '');
  static FundSource? find(String name, {String? accountType}) {
    for (final source in [...banks, ...wallets]) {
      if ((accountType == null || source.accountType == accountType) && _normalize(source.name) == _normalize(name)) return source;
    }
    return null;
  }
}
