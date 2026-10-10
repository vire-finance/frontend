import 'package:flutter/material.dart';

class CardThemeOption {
  const CardThemeOption(this.colors);

  final List<Color> colors;

  static const all = <CardThemeOption>[
    CardThemeOption([Color(0xFFFFB86B), Color(0xFFFF8B22)]),
    CardThemeOption([Color(0xFF83A5FF), Color(0xFF3260CD)]),
    CardThemeOption([Color(0xFF91D995), Color(0xFF32AD3A)]),
    CardThemeOption([Color(0xFFFF8585), Color(0xFFE41F26)]),
    CardThemeOption([Color(0xFFF587D8), Color(0xFFD62FC3)]),
    CardThemeOption([Color(0xFF707070), Color(0xFF303030)]),
    CardThemeOption([Color(0xFF8CE5E6), Color(0xFF35B8C0)]),
  ];
}

class CardModel {
  const CardModel({
    required this.id,
    required this.name,
    required this.pocketId,
    required this.balance,
    required this.monthlyLimit,
    required this.lastFour,
    required this.themeIndex,
    this.isLocked = false,
  });

  final String id;
  final String name;
  final String pocketId;
  final int balance;
  final int monthlyLimit;
  final String lastFour;
  final int themeIndex;
  final bool isLocked;

  CardModel copyWith({bool? isLocked}) => CardModel(
    id: id,
    name: name,
    pocketId: pocketId,
    balance: balance,
    monthlyLimit: monthlyLimit,
    lastFour: lastFour,
    themeIndex: themeIndex,
    isLocked: isLocked ?? this.isLocked,
  );
}