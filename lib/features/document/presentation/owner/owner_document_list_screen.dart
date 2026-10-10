import '../request_document_list.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/bottom_nav_shell.dart';
import '../../../dashboard/presentation/owner_dashboard_screen.dart';
import '../../../history/presentation/history_screen.dart';
import '../../../pocket/presentation/owner/owner_pocket_list_screen.dart';
import '../../../profile/presentation/profile_screen.dart';

class OwnerDocumentListScreen extends StatelessWidget {
  const OwnerDocumentListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: const RequestDocumentList(owner: true),
        bottomNavigationBar: AppNavbar(
            items: vireNavigationItems,
            selectedIndex: 2,
            onDestinationSelected: (index) {
              final Widget screen = switch (index) {
                0 => const OwnerDashboardScreen(),
                1 => const OwnerPocketListScreen(),
                3 => const HistoryScreen(),
                4 => const OwnerProfileScreen(),
                _ => const OwnerDocumentListScreen()
              };
              if (index != 2)
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => screen),
                    (_) => false);
            }),
      );
}
