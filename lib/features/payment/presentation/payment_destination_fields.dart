import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/payment_destination.dart';

class PaymentDestinationFields extends StatefulWidget {
  const PaymentDestinationFields(
      {required this.bank,
      required this.onChanged,
      this.enabled = true,
      super.key});
  final bool bank, enabled;
  final ValueChanged<PaymentDestination?> onChanged;
  @override
  State<PaymentDestinationFields> createState() => _DestinationFieldsState();
}

class _DestinationFieldsState extends State<PaymentDestinationFields> {
  String? _name;
  final _number = TextEditingController(), _other = TextEditingController();
  @override
  void initState() {
    super.initState();
    _number.addListener(_emit);
    _other.addListener(_emit);
  }

  @override
  void dispose() {
    _number.dispose();
    _other.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PaymentDestinationFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bank != widget.bank) {
      _name = null;
      _number.clear();
      _other.clear();
    }
  }

  void _emit() => widget.onChanged(_name == null
      ? null
      : PaymentDestination(
          paymentType: widget.bank ? 'BANK' : 'E_WALLET',
          name: _name!,
          accountNumber: _number.text.trim(),
          bankName: _name == 'Other' ? _other.text.trim() : null));

  Future<String?> _searchBank() => showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var search = '';
        return StatefulBuilder(
            builder: (context, update) => SafeArea(
                child: Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.viewInsetsOf(context).bottom),
                    child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * .65,
                        child: Column(children: [
                          Padding(
                              padding: const EdgeInsets.all(16),
                              child: AppInputField(
                                  decoration: const AppInputDecoration(
                                      hintText: 'Search banks'),
                                  onChanged: (value) => update(
                                      () => search = value.toLowerCase()))),
                          Expanded(
                              child: ListView(
                                  children: destinationBanks
                                      .where((name) =>
                                          name.toLowerCase().contains(search))
                                      .map((name) => ListTile(
                                          title: Text(name),
                                          onTap: () =>
                                              Navigator.pop(context, name)))
                                      .toList())),
                        ])))));
      });

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppInputLabel(widget.bank ? 'Destination Bank' : 'Destination E-Wallet',
            requiredField: true),
        const SizedBox(height: 8),
        if (widget.bank)
          FormField<String>(
            key: ValueKey('bank-${widget.bank}'),
            validator: (_) => _name == null ? 'Select a destination bank' : null,
            builder: (field) => AppPickerField(
              value: _name,
              decoration:
                  const AppInputDecoration(hintText: 'Select destination bank')
                      .copyWith(errorText: field.errorText),
              onTap: !widget.enabled
                  ? null
                  : () async {
                      final name = await _searchBank();
                      if (!mounted || name == null) return;
                      setState(() {
                        _name = name;
                        _other.clear();
                      });
                      field.didChange(name);
                      _emit();
                    },
            ),
          ),
        if (!widget.bank)
          AppDropdownField<String>(
              key: ValueKey('wallet-${widget.bank}'),
              value: _name,
              decoration: const AppInputDecoration(hintText: 'Select e-wallet'),
              items: destinationWallets
                  .map((name) =>
                      DropdownMenuItem(value: name, child: Text(name)))
                  .toList(),
              onChanged: !widget.enabled
                  ? null
                  : (name) {
                      setState(() {
                        _name = name;
                        _other.clear();
                      });
                      _emit();
                    },
              validator: (value) =>
                  value == null ? 'Select an e-wallet' : null),
        if (widget.bank && _name == 'Other') ...[
          const SizedBox(height: 18),
          const AppInputLabel('Bank Name', requiredField: true),
          const SizedBox(height: 8),
          AppFormField(
              controller: _other,
              enabled: widget.enabled,
              decoration: const AppInputDecoration(hintText: 'Enter bank name'),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) {
                  return 'Enter the bank name';
                }
                if (name.length > 100 || !RegExp(r'[a-zA-Z]').hasMatch(name)) {
                  return 'Enter a valid bank name';
                }
                return null;
              }),
        ],
        const SizedBox(height: 18),
        AppInputLabel(widget.bank ? 'Account Number' : 'E-Wallet Number',
            requiredField: true),
        const SizedBox(height: 8),
        AppFormField(
            controller: _number,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: AppInputDecoration(
                hintText: widget.bank
                    ? 'Enter account number'
                    : 'Enter e-wallet number'),
            validator: (value) {
              final number = value?.trim() ?? '';
              if (number.isEmpty) {
                return 'Enter the destination number';
              }
              if (!RegExp(r'^[0-9]+$').hasMatch(number)) {
                return 'Use digits only';
              }
              if (('${_name == 'Other' ? _other.text.trim() : _name ?? ''} $number')
                      .length >
                  150) {
                return 'Destination exceeds supported storage capacity';
              }
              return null;
            }),
      ]);
}
