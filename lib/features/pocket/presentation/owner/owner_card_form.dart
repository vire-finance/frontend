import '../../../../core/constants/expense_categories.dart';
import 'package:flutter/material.dart';

const vireCardThemes = <List<Color>>[
  [Color(0xFFFFB86B), Color(0xFFFF8B22)],
  [Color(0xFF83A5FF), Color(0xFF3260CD)],
  [Color(0xFF91D995), Color(0xFF32AD3A)],
  [Color(0xFFFF8585), Color(0xFFE41F26)],
  [Color(0xFFF587D8), Color(0xFFD62FC3)],
  [Color(0xFF707070), Color(0xFF303030)],
  [Color(0xFF8CE5E6), Color(0xFF35B8C0)],
];

class VireCardData {
  const VireCardData({
    required this.id,
    required this.name,
    required this.pocketId,
    required this.balance,
    required this.limit,
    required this.lastFour,
    required this.themeIndex,
    this.allowedCategories = expenseCategories,
    this.locked = false,
    this.blocked = false,
    this.usageType = 'LONG_TERM',
    this.expiresOn,
    this.singleUseConsumed = false,
    this.maskedNumber,
    this.simulatedCardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.cvv,
  });

  final String id;
  final String name;
  final String pocketId;
  final int balance;
  final int limit;
  final List<String> allowedCategories;
  final String lastFour;
  final int themeIndex;
  final bool locked;
  final bool blocked;
  final String usageType;
  final DateTime? expiresOn;
  final bool singleUseConsumed;

  bool get canPay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = expiresOn ??
        (expiryYear != null && expiryMonth != null
            ? DateTime(expiryYear!, expiryMonth! + 1, 0)
            : null);
    return !locked &&
        !blocked &&
        !singleUseConsumed &&
        (expiry == null || !expiry.isBefore(today));
  }

  String get usageLabel => switch (usageType) {
        'SINGLE_USE' => 'Single use',
        'SUBSCRIPTION' => 'Online subscription',
        _ => 'Long-term use',
      };
  final String? maskedNumber;
  final String? simulatedCardNumber;
  final int? expiryMonth;
  final int? expiryYear;
  final String? cvv;

  VireCardData copyWith({bool? locked, int? balance}) => VireCardData(
        id: id,
        name: name,
        pocketId: pocketId,
        balance: balance ?? this.balance,
        limit: limit,
        lastFour: lastFour,
        allowedCategories: allowedCategories,
        themeIndex: themeIndex,
        locked: locked ?? this.locked,
        blocked: blocked,
        usageType: usageType,
        expiresOn: expiresOn,
        singleUseConsumed: singleUseConsumed,
        maskedNumber: maskedNumber,
        simulatedCardNumber: simulatedCardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: cvv,
      );
}

class VirePocketData {
  const VirePocketData({
    required this.id,
    required this.name,
    required this.balance,
    required this.limit,
    required this.source,
    required this.themeIndex,
  });

  final String id;
  final String name;
  final int balance;
  final int limit;
  final String source;
  final int themeIndex;
}

String formatIdr(int value) {
  final digits = value.toString();
  final result = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) result.write(',');
    result.write(digits[i]);
  }

  return 'IDR $result';
}

class CardThemePicker extends StatelessWidget {
  const CardThemePicker({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: List.generate(vireCardThemes.length, (index) {
        return GestureDetector(
          onTap: () => onSelected(index),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: vireCardThemes[index].last,
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedIndex == index
                    ? const Color(0xFF5B80D7)
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: selectedIndex == index
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }),
    );
  }
}
