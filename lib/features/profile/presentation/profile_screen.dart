import '../../../shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_nav_shell.dart';
import '../../funding/presentation/fund_account_screen.dart';
import '../../dashboard/presentation/employee_dashboard_screen.dart';
import '../../dashboard/presentation/owner_dashboard_screen.dart';
import '../../document/presentation/owner/owner_document_list_screen.dart';
import '../../document/presentation/employee/employee_document_list_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../pocket/data/pocket_repository.dart';
import '../../pocket/presentation/owner/owner_access_screen.dart';
import '../../pocket/presentation/owner/owner_pocket_list_screen.dart';
import '../../pocket/presentation/employee/employee_pocket_list_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import 'widgets/profile_header.dart';
import 'change_password_screen.dart';
import 'widgets/invitation_code_card.dart';
import 'widgets/profile_menu_section.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({this.displayName, super.key});
  final String? displayName;
  @override
  Widget build(BuildContext context) => _ProfileScreen(isOwner: true, displayName: displayName);
}

class EmployeeProfileScreen extends StatelessWidget {
  const EmployeeProfileScreen({this.displayName, super.key});
  final String? displayName;
  @override
  Widget build(BuildContext context) => _ProfileScreen(isOwner: false, displayName: displayName);
}

class _ProfileScreen extends StatefulWidget {
  const _ProfileScreen({required this.isOwner, this.displayName});
  final bool isOwner;
  final String? displayName;

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  String? _displayName;
  bool? _biometricEnabled;
  Map<String, bool> _notificationPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthRepository.instance.profile();
      final settings = await AuthRepository.instance.securitySettings();
      if (widget.isOwner) await PocketRepository.instance.load();
      if (!mounted) return;
      final rawPreferences = settings['notification_preferences'];
      setState(() {
        _displayName = '${profile['full_name'] ?? ''}'.trim();
        _biometricEnabled = settings['biometric_enabled'] == true;
        if (rawPreferences is Map) {
          _notificationPreferences = rawPreferences.map((key, value) => MapEntry('$key', value == true));
        }
      });
    } catch (_) {
      // Keep the profile shell visible when the API cannot be reached.
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.isOwner ? 'Business Owner' : 'Employee';
    final items = widget.isOwner ? vireNavigationItems : employeeNavigationItems;
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: AppNavbar(items: items, selectedIndex: 4, onDestinationSelected: _selectDestination),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ProfileHeader(
                  name: _displayName?.isNotEmpty == true ? _displayName : widget.displayName,
                  role: role,
                  imagePath: widget.isOwner
                      ? 'assets/images/Profiles/Group 220.png'
                      : 'assets/images/Profiles/Group 212.png',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isOwner) ...[
                        const InvitationCodeCard(),
                        const SizedBox(height: 20),
                        ProfileMenuSection(
                          title: 'Workspace Settings',
                          items: [
                            ProfileMenuItem(icon: Icons.credit_card_outlined, label: 'Linked Fund Account', onTap: _openFundAccount),
                            ProfileMenuItem(icon: Icons.people_alt_outlined, label: 'Manage Employee', onTap: _manageEmployees),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      ProfileMenuSection(
                        title: 'Security & Account',
                        items: [
                          ProfileMenuItem(icon: Icons.password_outlined, label: 'Change Password', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()))),
                          ProfileMenuItem(icon: Icons.key_outlined, label: 'Change Security Pin', onTap: _changePin),
                          ProfileMenuItem(icon: Icons.fingerprint, label: 'Biometric Authentication', onTap: _toggleBiometric),
                          ProfileMenuItem(icon: Icons.notifications_none, label: 'Notification Preferences', onTap: _showNotificationPreferences),
                          ProfileMenuItem(icon: Icons.logout, label: 'Logout', isDestructive: true, onTap: _confirmLogout),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectDestination(int index) {
    if (index == 4) return;
    if (!widget.isOwner) {
      switch (index) {
        case 0:
          _goTo(const EmployeeDashboardScreen());
          return;
        case 1:
          _goTo(const EmployeePocketListScreen());
          return;
        case 2:
          _goTo(const EmployeeDocumentListScreen());
          return;
        case 3:
          _goTo(const HistoryScreen(employee: true));
          return;
      }
      return;
    }
    switch (index) {
      case 0:
        _goTo(const OwnerDashboardScreen());
        return;
      case 1:
        _goTo(const OwnerPocketListScreen());
        return;
      case 2:
        _goTo(const OwnerDocumentListScreen());
        return;
      case 3:
        _goTo(const HistoryScreen());
        return;
    }
  }

  Future<void> _openFundAccount() async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const FundAccountScreen()));
  }

  void _manageEmployees() {
    final cards = PocketRepository.instance.cards;
    if (cards.isEmpty) {
      _showUnavailable('Create a card first to manage employee access.');
      return;
    }
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OwnerAccessScreen(card: cards.first)));
  }

  Future<void> _showNotificationPreferences() => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Preferences'),
          content: StatefulBuilder(builder: (context, setDialogState) => Column(mainAxisSize: MainAxisSize.min, children: [
            for (final entry in {'push': 'Push notifications', 'email': 'Email notifications'}.entries)
              SwitchListTile(title: Text(entry.value), value: _notificationPreferences[entry.key] ?? true, onChanged: (value) => setDialogState(() => _notificationPreferences[entry.key] = value)),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            FilledButton(onPressed: () async {
              try {
                await AuthRepository.instance.updateNotificationPreferences(_notificationPreferences);
                if (context.mounted) Navigator.pop(context);
              } catch (error) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
              }
            }, child: const Text('Save')),
          ],
        ),
      );

  Future<void> _toggleBiometric() async {
    final next = !(_biometricEnabled ?? false);
    try {
      await AuthRepository.instance.updateBiometric(next);
      if (mounted) setState(() => _biometricEnabled = next);
      _showUnavailable(next ? 'Biometric sign-in enabled.' : 'Biometric sign-in disabled.');
    } catch (error) {
      _showUnavailable(apiErrorMessage(error));
    }
  }

  Future<void> _changePin() async {
    final oldPin = TextEditingController();
    final newPin = TextEditingController();
    final confirmedPin = TextEditingController();
    final save = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Change Security PIN'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        AppInputField(controller: oldPin, keyboardType: TextInputType.number, obscureText: true, maxLength: 4, decoration: const AppInputDecoration(labelText: 'Current PIN')),
        AppInputField(controller: newPin, keyboardType: TextInputType.number, obscureText: true, maxLength: 4, decoration: const AppInputDecoration(labelText: 'New PIN')),
        AppInputField(controller: confirmedPin, keyboardType: TextInputType.number, obscureText: true, maxLength: 4, decoration: const AppInputDecoration(labelText: 'Confirm new PIN')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))],
    ));
    if (save == true) {
      if (newPin.text.length != 4 || newPin.text != confirmedPin.text) {
        _showUnavailable('Enter the same 4-digit PIN twice.');
      } else {
        try {
          await AuthRepository.instance.changeSecurityPin(oldPin: oldPin.text, newPin: newPin.text);
          if (mounted) _showUnavailable('Security PIN updated.');
        } catch (error) {
          if (mounted) _showUnavailable(apiErrorMessage(error));
        }
      }
    }
    oldPin.dispose();
    newPin.dispose();
    confirmedPin.dispose();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to use this account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await AuthRepository.instance.logout();
        if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()), (route) => false);
      } catch (error) {
        if (mounted) _showUnavailable(apiErrorMessage(error));
      }
    }
  }

  void _goTo(Widget screen) => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => screen),
        (route) => false,
      );

  void _showUnavailable(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
