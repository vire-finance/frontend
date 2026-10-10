import '../../../../shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/pocket_repository.dart';
import 'owner_card_form.dart';

class OwnerCardSettingsScreen extends StatefulWidget {
  const OwnerCardSettingsScreen({required this.card, super.key});
  final VireCardData card;

  @override
  State<OwnerCardSettingsScreen> createState() =>
      _OwnerCardSettingsScreenState();
}

class _OwnerCardSettingsScreenState extends State<OwnerCardSettingsScreen> {
  late DateTime _expiry;
  late String _usageType;
  late bool _blocked;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _expiry = card.expiresOn ??
        DateTime(card.expiryYear ?? DateTime.now().year + 3,
            (card.expiryMonth ?? DateTime.now().month) + 1, 0);
    _usageType = card.usageType;
    _blocked = card.blocked;
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(now.year + 30, 12, 31);
    final initial = _expiry.isBefore(today)
        ? today
        : _expiry.isAfter(last)
            ? last
            : _expiry;
    final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: today,
        lastDate: last);
    if (date != null && mounted) setState(() => _expiry = date);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await PocketRepository.instance.updateCardSettings(widget.card,
          expiresOn: _expiry, usageType: _usageType, blocked: _blocked);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
            title: const Text('Card Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            centerTitle: true,
            backgroundColor: AppColors.basicWhite,
            foregroundColor: AppColors.blue900),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('${widget.card.name}  •••• ${widget.card.lastFour}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue900)),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_outlined,
                      color: AppColors.blue500),
                  title: const Text('Expiry date'),
                  subtitle: Text(
                      '${_expiry.day.toString().padLeft(2, '0')}/${_expiry.month.toString().padLeft(2, '0')}/${_expiry.year}'),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _saving ? null : _pickExpiry,
                ),
              ),
              const SizedBox(height: 20),
              AppDropdownField<String>(initialValue: _usageType, decoration: const AppInputDecoration(labelText: 'Card type'), items: const [
                  DropdownMenuItem(
                      value: 'SINGLE_USE', child: Text('Single use')),
                  DropdownMenuItem(
                      value: 'LONG_TERM', child: Text('Long-term use')),
                  DropdownMenuItem(
                      value: 'SUBSCRIPTION',
                      child: Text('Online subscription')),
                ], onChanged: _saving || widget.card.singleUseConsumed
                    ? null
                    : (value) {
                        if (value != null) setState(() => _usageType = value);
                      }),
              const SizedBox(height: 10),
              Text(
                  widget.card.singleUseConsumed
                      ? 'This single-use card has already been used and cannot pay again.'
                      : switch (_usageType) {
                          'SINGLE_USE' =>
                            'Can complete one successful payment. Failed payments do not use the card.',
                          'SUBSCRIPTION' =>
                            'For repeated online service or product payments. Payments are simulated and confirmed manually.',
                          _ => 'Can be used repeatedly until the expiry date.',
                        },
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.grey500)),
              const SizedBox(height: 20),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.block, color: AppColors.red500),
                  title: const Text('Block card'),
                  subtitle: const Text(
                      'Blocked cards cannot make payments. Turn this off to unblock the card.'),
                  value: _blocked,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _blocked = value),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                  height: 48,
                  child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save Settings'))),
            ],
          ),
        ),
      );
}
