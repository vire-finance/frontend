import '../../../../shared/widgets/expense_category_tags.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bottom_nav_shell.dart';
import '../../../dashboard/presentation/employee_dashboard_screen.dart';
import '../../../document/presentation/employee/employee_document_list_screen.dart';
import '../../../history/presentation/history_screen.dart';
import '../../../profile/presentation/profile_screen.dart';
import '../../data/employee_pocket_repository.dart';
import '../owner/owner_card_form.dart';

class EmployeePocketListScreen extends StatefulWidget {
  const EmployeePocketListScreen({super.key});

  @override
  State<EmployeePocketListScreen> createState() =>
      _EmployeePocketListScreenState();
}

class _EmployeePocketListScreenState extends State<EmployeePocketListScreen> {
  @override
  void initState() {
    super.initState();
    EmployeePocketRepository.instance.load().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final repository = EmployeePocketRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        bottomNavigationBar: AppNavbar(
            items: employeeNavigationItems,
            selectedIndex: 1,
            onDestinationSelected: (index) => _navigate(context, index)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Image.asset('assets/images/Regular Images/Logo - V.png',
                      width: 30, height: 30, alignment: Alignment.centerLeft),
                  const SizedBox(height: 26),
                  Text('Your Card (${repository.accessibleCards.length})',
                      style: const TextStyle(
                          color: AppColors.blue800,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  if (repository.accessibleCards.isEmpty)
                    const _EmptyAccessibleCards()
                  else
                    for (final card in repository.accessibleCards) ...[
                      _EmployeeCardTile(card: card),
                      const SizedBox(height: 18),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _navigate(BuildContext context, int index) {
    final Widget? screen = switch (index) {
      0 => const EmployeeDashboardScreen(),
      1 => null,
      2 => const EmployeeDocumentListScreen(),
      3 => const HistoryScreen(employee: true),
      4 => const EmployeeProfileScreen(),
      _ => null,
    };
    if (screen == null) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => screen), (route) => false);
  }
}

class _EmptyAccessibleCards extends StatelessWidget {
  const _EmptyAccessibleCards();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 44, horizontal: 20),
        child: Column(children: [
          Icon(Icons.credit_card_off_outlined,
              color: AppColors.blue200, size: 48),
          SizedBox(height: 12),
          Text('No cards shared with you yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey500)),
        ]),
      );
}

class _EmployeeCardTile extends StatelessWidget {
  const _EmployeeCardTile({required this.card});
  final VireCardData card;

  @override
  Widget build(BuildContext context) {
    final colors = vireCardThemes[card.themeIndex];
    return Row(children: [
      Container(
        width: 152,
        height: 146,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12)),
        child: Align(
            alignment: Alignment.bottomRight,
            child: Text(card.lastFour,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700))),
      ),
      const SizedBox(width: 16),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(card.name,
            style: const TextStyle(
                color: AppColors.blue500,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        Text(formatIdr(card.balance),
            style: const TextStyle(
                color: AppColors.blue900, fontWeight: FontWeight.w600)),
        const SizedBox(height: 9),
        ExpenseCategoryTags(categories: card.allowedCategories),
      ])),
    ]);
  }
}
