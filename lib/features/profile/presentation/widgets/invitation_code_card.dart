import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';

class InvitationCodeCard extends StatefulWidget {
  const InvitationCodeCard({super.key});

  @override
  State<InvitationCodeCard> createState() => _InvitationCodeCardState();
}

class _InvitationCodeCardState extends State<InvitationCodeCard> {
  String? _code;
  DateTime? _expiresAt;
  String? _error;
  bool _loading = true;

  bool get _expired =>
      _expiresAt == null || !_expiresAt!.isAfter(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool regenerate = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = regenerate
          ? await AuthRepository.instance.regenerateInvitationCode()
          : await AuthRepository.instance.invitationCode();
      if (!mounted) return;
      setState(() {
        _code = data['code'] as String?;
        _expiresAt =
            DateTime.tryParse('${data['expires_at'] ?? ''}')?.toLocal();
      });
    } catch (error) {
      if (mounted) setState(() => _error = apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy() async {
    final code = _code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation code copied.')));
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.blue50, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.person_add_alt_1_outlined, color: AppColors.blue500),
              SizedBox(width: 8),
              Expanded(
                  child: Text('Employee Invitation Code',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue900))),
            ]),
            const SizedBox(height: 12),
            if (_code != null) ...[
              Row(children: [
                Expanded(
                    child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(_code!,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue500)),
                )),
                IconButton(
                    onPressed: _loading || _expired ? null : _copy,
                    tooltip: 'Copy invitation code',
                    icon: const Icon(Icons.copy_outlined),
                    color: AppColors.blue500),
              ]),
              Text(
                  _expired
                      ? 'Expired. Create a new code to invite employees.'
                      : 'Valid until ${_expiresAt!.day.toString().padLeft(2, '0')}/${_expiresAt!.month.toString().padLeft(2, '0')}/${_expiresAt!.year}. Share this code with your employees.',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.grey500)),
            ] else if (!_loading && _error == null)
              const Text(
                  'The previous setup code cannot be displayed. Create a new code to replace it; the previous code will no longer work.',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500)),
            if (_error != null) ...[
              Text(_error!,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.red500)),
              TextButton(
                  onPressed: _loading ? null : () => _load(),
                  child: const Text('Retry')),
            ],
            if (_loading)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator()),
            if (!_loading && _error == null && (_code == null || _expired)) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                  onPressed: () => _load(regenerate: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Create New Code')),
              const Text('New codes are valid for 7 days.',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500)),
            ],
          ],
        ),
      );
}
