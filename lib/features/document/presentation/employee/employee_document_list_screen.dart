import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_nav_shell.dart';
import '../../../dashboard/presentation/employee_dashboard_screen.dart';
import '../../../history/presentation/history_screen.dart';
import '../../../pocket/presentation/employee/employee_pocket_list_screen.dart';
import '../../../profile/presentation/profile_screen.dart';
import '../request_document_list.dart';

class EmployeeDocumentListScreen extends StatelessWidget {
  const EmployeeDocumentListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: const RequestDocumentList(owner: false),
      bottomNavigationBar: AppNavbar(
          items: employeeNavigationItems,
          selectedIndex: 2,
          onDestinationSelected: (index) {
            final Widget screen = switch (index) {
              0 => const EmployeeDashboardScreen(),
              1 => const EmployeePocketListScreen(),
              3 => const HistoryScreen(),
              4 => const EmployeeProfileScreen(),
              _ => const EmployeeDocumentListScreen()
            };
            if (index != 2)
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => screen),
                  (_) => false);
          }));
}
