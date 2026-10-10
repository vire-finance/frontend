import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/confirm_modal.dart';
import '../../data/pocket_repository.dart';
import 'owner_card_form.dart';

class OwnerPocketFormScreen extends StatefulWidget {
  const OwnerPocketFormScreen({super.key});

  @override
  State<OwnerPocketFormScreen> createState() => _OwnerPocketFormScreenState();
}

class _OwnerPocketFormScreenState extends State<OwnerPocketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  int _themeIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF8F8FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F8FF),
          foregroundColor: const Color(0xFF18346F),
          elevation: 0,
          centerTitle: true,
          title: const Text('New Pocket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _label('Pocket Name'),
                _input(_nameController, hint: 'Type here'),
                const SizedBox(height: 18),
                _label('Card Theme'),
                CardThemePicker(selectedIndex: _themeIndex, onSelected: (index) => setState(() => _themeIndex = index)),
                const SizedBox(height: 18),
                _label('Initial Budget (IDR)'),
                _input(_limitController, hint: 'Type here', keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                const Text('This budget is deducted from your Main Fund Account. Top up your main balance before creating a pocket.', style: TextStyle(fontSize: 12, color: Color(0xFF616161))),
                const SizedBox(height: 28),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5B80D7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: AppInputLabel(text, requiredField: true));

  Widget _input(TextEditingController controller, {required String hint, TextInputType? keyboardType}) => AppFormField(controller: controller, keyboardType: keyboardType, inputFormatters: keyboardType == TextInputType.number ? [const IdrInputFormatter()] : null, validator: (value) => value == null || value.trim().isEmpty ? 'This field is required.' : null, decoration: _decoration(hint: hint));

  InputDecoration _decoration({String? hint}) => AppInputDecoration(hintText: hint);

  int _asAmount(String value) => parseIdrInput(value) ?? 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _asAmount(_limitController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a positive spending limit.')));
      return;
    }
    try {
      await PocketRepository.instance.createPocket(
        VirePocketData(
          id: '',
        name: _nameController.text.trim(),
        balance: 0,
        limit: amount,
        source: '—',
        themeIndex: _themeIndex,
        ),
      );

      if (!mounted) return;
      await ConfirmModal.showCreated(context, isCard: false);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
    }
  }
}
