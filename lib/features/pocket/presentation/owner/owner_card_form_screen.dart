import '../../../../shared/widgets/expense_category_multi_select.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/confirm_modal.dart';
import '../../data/pocket_repository.dart';
import 'owner_card_form.dart';

class OwnerCardFormScreen extends StatefulWidget {
  const OwnerCardFormScreen({this.pocketId, super.key});
  final String? pocketId;

  @override
  State<OwnerCardFormScreen> createState() => _OwnerCardFormScreenState();
}

class _OwnerCardFormScreenState extends State<OwnerCardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _limitController = TextEditingController();
  List<String> _allowedCategories = [];
  int _themeIndex = 0;
  String? _pocketId;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = PocketRepository.instance;
    _pocketId ??= widget.pocketId ??
        (repository.pockets.isEmpty ? null : repository.pockets.first.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8FF),
        foregroundColor: const Color(0xFF18346F),
        elevation: 0,
        centerTitle: true,
        title: const Text('New Card',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _label('Card Name', required: true),
              _input(_nameController, hint: 'Type here', validator: _required),
              const SizedBox(height: 18),
              _label('Card Theme', required: true),
              CardThemePicker(
                selectedIndex: _themeIndex,
                onSelected: (index) => setState(() => _themeIndex = index),
              ),
              const SizedBox(height: 18),
              ExpenseCategoryMultiSelect(
                  onChanged: (categories) => _allowedCategories = categories),
              const SizedBox(height: 18),
              _label('Initial Balance', required: true),
              _input(_balanceController,
                  hint: 'Type here',
                  keyboardType: TextInputType.number,
                  validator: _required),
              const SizedBox(height: 18),
              _label('Spending Limit', required: true),
              _input(_limitController,
                  hint: 'Type here',
                  keyboardType: TextInputType.number,
                  validator: _required),
              const SizedBox(height: 18),
              _label('Pocket', required: true),
              AppDropdownField<String>(
                  value: _pocketId,
                  decoration: _decoration(),
                  hint: const Text('Select a pocket'),
                  items: repository.pockets
                      .map((pocket) => DropdownMenuItem(
                          value: pocket.id, child: Text(pocket.name)))
                      .toList(),
                  onChanged: repository.pockets.isEmpty
                      ? null
                      : (value) => setState(() => _pocketId = value),
                  validator: (value) =>
                      value == null ? 'Create a pocket first.' : null),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5B80D7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String label, {required bool required}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppInputLabel(label, requiredField: required));

  Widget _input(
    TextEditingController controller, {
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      AppFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number
              ? [const IdrInputFormatter()]
              : null,
          validator: validator,
          decoration: _decoration(hint: hint));

  InputDecoration _decoration({String? hint}) =>
      AppInputDecoration(hintText: hint);

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  int _asAmount(String value) => parseIdrInput(value) ?? 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = PocketRepository.instance;
    final balance = _asAmount(_balanceController.text);
    final limit = _asAmount(_limitController.text);
    if (balance <= 0 || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Balance and limit must be greater than zero.')));
      return;
    }
    final card = VireCardData(
      id: '',
      name: _nameController.text.trim(),
      pocketId: _pocketId!,
      balance: balance,
      limit: limit,
      lastFour: '',
      themeIndex: _themeIndex,
      allowedCategories: _allowedCategories,
    );
    try {
      await repository.createCard(card);
      if (!mounted) return;
      await ConfirmModal.showCreated(context, isCard: true);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
    }
  }
}
