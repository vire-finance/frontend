class PocketModel {
  const PocketModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.monthlyLimit,
    required this.fundingSource,
    required this.themeIndex,
  });

  final String id;
  final String name;
  final int balance;
  final int monthlyLimit;
  final String fundingSource;
  final int themeIndex;
}