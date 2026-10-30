import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_text_field.dart';
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
  Widget build(BuildContext context) =>
      _ProfileScreen(isOwner: true, displayName: displayName);
}

class EmployeeProfileScreen extends StatelessWidget {
  const EmployeeProfileScreen({this.displayName, super.key});
  final String? displayName;
  @override
  Widget build(BuildContext context) =>
      _ProfileScreen(isOwner: false, displayName: displayName);
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
  String? _profileImageUrl;
  Map<String, String>? _profileImageHeaders;
  bool _changingPhoto = false;
  Map<String, bool> _notificationPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthRepository.instance.profile();
      final token = await ApiClient.instance.accessToken;
      final photoPath = profile['avatar_url'] as String?;
      final settings = await AuthRepository.instance.securitySettings();
      if (widget.isOwner) await PocketRepository.instance.load();
      if (!mounted) return;
      final rawPreferences = settings['notification_preferences'];
      setState(() {
        _profileImageUrl =
            photoPath == null ? null : _resolvePhotoUrl(photoPath);
        _profileImageHeaders =
            token == null ? null : {'Authorization': 'Bearer $token'};
        _displayName = '${profile['full_name'] ?? ''}'.trim();
        if (rawPreferences is Map) {
          _notificationPreferences = rawPreferences
              .map((key, value) => MapEntry('$key', value == true));
        }
      });
    } catch (_) {
      // Keep the profile shell visible when the API cannot be reached.
    }
  }

  Future<void> _changePhoto() async {
    if (_changingPhoto) return;
    setState(() => _changingPhoto = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 95,
        requestFullMetadata: false,
      );
      if (picked == null || !mounted) return;
      final sourceBytes = await picked.readAsBytes();
      final ratio = await _choosePhotoRatio(sourceBytes);
      if (ratio == null || !mounted) return;
      final decoded = img.decodeImage(sourceBytes);
      if (decoded == null) throw StateError('Foto tidak dapat dibaca.');
      final oriented = img.bakeOrientation(decoded);
      final cropWidth = oriented.width / oriented.height > ratio
          ? (oriented.height * ratio).round()
          : oriented.width;
      final cropHeight = oriented.width / oriented.height > ratio
          ? oriented.height
          : (oriented.width / ratio).round();
      final cropped = img.copyCrop(
        oriented,
        x: (oriented.width - cropWidth) ~/ 2,
        y: (oriented.height - cropHeight) ~/ 2,
        width: cropWidth,
        height: cropHeight,
      );
      final resized = cropped.width > 1024 || cropped.height > 1024
          ? img.copyResize(
              cropped,
              width: cropped.width >= cropped.height ? 1024 : null,
              height: cropped.height > cropped.width ? 1024 : null,
            )
          : cropped;
      var jpeg = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
      if (jpeg.length > 1900000) {
        final smaller = img.copyResize(
          resized,
          width: resized.width >= resized.height ? 768 : null,
          height: resized.height > resized.width ? 768 : null,
        );
        jpeg = Uint8List.fromList(img.encodeJpg(smaller, quality: 75));
      }
      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
        '/api/v1/profile/photo',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            jpeg,
            filename: 'profile.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
        }),
      );
      final photoPath = response.data?['avatar_url'] as String?;
      if (photoPath == null || photoPath.isEmpty) {
        throw StateError('Server tidak mengembalikan foto profil.');
      }
      final token = await ApiClient.instance.accessToken;
      if (!mounted) return;
      setState(() {
        _profileImageUrl = Uri.parse(_resolvePhotoUrl(photoPath)).replace(
            queryParameters: {
              'v': '${DateTime.now().millisecondsSinceEpoch}'
            }).toString();
        _profileImageHeaders =
            token == null ? null : {'Authorization': 'Bearer $token'};
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _changingPhoto = false);
    }
  }

  String _resolvePhotoUrl(String path) =>
      Uri.parse(ApiClient.instance.dio.options.baseUrl)
          .resolve(path)
          .toString();

  Future<double?> _choosePhotoRatio(Uint8List bytes) => showDialog<double>(
        context: context,
        builder: (dialogContext) {
          var selectedRatio = 1.0;
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Atur rasio foto'),
              content: SizedBox(
                width: 270,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: selectedRatio,
                        child: Image.memory(bytes, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: [
                        for (final option in const [
                          (label: '1:1', ratio: 1.0),
                          (label: '4:3', ratio: 4 / 3),
                          (label: '3:4', ratio: 3 / 4),
                          (label: '16:9', ratio: 16 / 9),
                        ])
                          ChoiceChip(
                            label: Text(option.label),
                            selected: selectedRatio == option.ratio,
                            onSelected: (_) => setDialogState(
                                () => selectedRatio = option.ratio),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Batal')),
                FilledButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, selectedRatio),
                    child: const Text('Gunakan Foto')),
              ],
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final role = widget.isOwner ? 'Business Owner' : 'Employee';
    final items =
        widget.isOwner ? vireNavigationItems : employeeNavigationItems;
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: AppNavbar(
          items: items,
          selectedIndex: 4,
          onDestinationSelected: _selectDestination),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ProfileHeader(
                  name: _displayName?.isNotEmpty == true
                      ? _displayName
                      : widget.displayName,
                  role: role,
                  imagePath: widget.isOwner
                      ? 'assets/images/Profiles/Group 220.png'
                      : 'assets/images/Profiles/Group 212.png',
                  imageUrl: _profileImageUrl,
                  imageHeaders: _profileImageHeaders,
                  onTapImage: _changePhoto,
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
                            ProfileMenuItem(
                                icon: Icons.credit_card_outlined,
                                label: 'Linked Fund Account',
                                onTap: _openFundAccount),
                            ProfileMenuItem(
                                icon: Icons.people_alt_outlined,
                                label: 'Manage Employee',
                                onTap: _manageEmployees),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      ProfileMenuSection(
                        title: 'Security & Account',
                        items: [
                          ProfileMenuItem(
                              icon: Icons.password_outlined,
                              label: 'Change Password',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const ChangePasswordScreen()))),
                          ProfileMenuItem(
                              icon: Icons.key_outlined,
                              label: 'Change Security Pin',
                              onTap: _changePin),
                          ProfileMenuItem(
                              icon: Icons.notifications_none,
                              label: 'Notification Preferences',
                              onTap: _showNotificationPreferences),
                          ProfileMenuItem(
                              icon: Icons.logout,
                              label: 'Logout',
                              isDestructive: true,
                              onTap: _confirmLogout),
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
    await Navigator.push(context,
        MaterialPageRoute<void>(builder: (_) => const FundAccountScreen()));
  }

  void _manageEmployees() {
    final cards = PocketRepository.instance.cards;
    if (cards.isEmpty) {
      _showUnavailable('Create a card first to manage employee access.');
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => OwnerAccessScreen(card: cards.first)));
  }

  Future<void> _showNotificationPreferences() => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Preferences'),
          content: StatefulBuilder(
              builder: (context, setDialogState) =>
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    for (final entry in {
                      'push': 'Push notifications',
                      'email': 'Email notifications'
                    }.entries)
                      SwitchListTile(
                          title: Text(entry.value),
                          value: _notificationPreferences[entry.key] ?? true,
                          onChanged: (value) => setDialogState(() =>
                              _notificationPreferences[entry.key] = value)),
                  ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
            FilledButton(
                onPressed: () async {
                  try {
                    await AuthRepository.instance.updateNotificationPreferences(
                        _notificationPreferences);
                    if (context.mounted) Navigator.pop(context);
                  } catch (error) {
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(apiErrorMessage(error))));
                  }
                },
                child: const Text('Save')),
          ],
        ),
      );

  Future<void> _changePin() async {
    final oldPin = TextEditingController();
    final newPin = TextEditingController();
    final confirmedPin = TextEditingController();
    final save = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Change Security PIN'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                AppInputField(
                    controller: oldPin,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration:
                        const AppInputDecoration(labelText: 'Current PIN')),
                AppInputField(
                    controller: newPin,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const AppInputDecoration(labelText: 'New PIN')),
                AppInputField(
                    controller: confirmedPin,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration:
                        const AppInputDecoration(labelText: 'Confirm new PIN')),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save'))
              ],
            ));
    if (save == true) {
      if (newPin.text.length != 4 || newPin.text != confirmedPin.text) {
        _showUnavailable('Enter the same 4-digit PIN twice.');
      } else {
        try {
          await AuthRepository.instance
              .changeSecurityPin(oldPin: oldPin.text, newPin: newPin.text);
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
        content:
            const Text('You will need to log in again to use this account.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await AuthRepository.instance.logout();
        if (mounted)
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
              (route) => false);
      } catch (error) {
        if (mounted) _showUnavailable(apiErrorMessage(error));
      }
    }
  }

  void _goTo(Widget screen) => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => screen),
        (route) => false,
      );

  void _showUnavailable(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}
