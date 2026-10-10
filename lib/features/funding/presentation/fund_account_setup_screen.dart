import '../../../shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_client.dart';
import '../../setup/data/fund_sources.dart';
import '../../setup/presentation/widgets/pair_account_step.dart';
import '../data/funding_repository.dart';

class FundAccountSetupScreen extends StatefulWidget {
  const FundAccountSetupScreen({this.account, this.onSaved, super.key});
  final Map<String, dynamic>? account;
  final Future<void> Function()? onSaved;
  @override
  State<FundAccountSetupScreen> createState() => _FundAccountSetupScreenState();
}

class _FundAccountSetupScreenState extends State<FundAccountSetupScreen> {
  String? _selectedSource;
  bool _details = false;
  bool _saving = false;
  final _form = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _holder;

  @override
  void initState() {
    super.initState();
    _selectedSource = (FundSources.find(
                '${widget.account?['provider_name'] ?? ''}',
                accountType: widget.account?['account_type'] as String?) ??
            FundSources.find('${widget.account?['provider_name'] ?? ''}'))
        ?.name;
    _number = TextEditingController(
        text: widget.account?['account_number'] as String?);
    _holder = TextEditingController(
        text: widget.account?['account_holder'] as String?);
  }

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_saving) return;
    final source = FundSources.find(_selectedSource ?? '');
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih sumber dana terlebih dahulu.')));
      return;
    }
    if (!_details) {
      setState(() => _details = true);
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FundingRepository.instance.save({
        'account_type': source.accountType,
        'provider_name': source.name,
        'account_number': _number.text.trim(),
        'account_holder': _holder.text.trim(),
      });
      if (!mounted) return;
      if (widget.onSaved != null) {
        await widget.onSaved!();
      } else {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: SetupStepFrame(
          step: _details ? 3 : 2,
          title: _details
              ? 'Your Main Fund Account Details'
              : 'Pair Your Main Fund Account',
          description: _details
              ? 'Enter the account number and holder name for your selected fund account.'
              : "Link your company's primary bank account to start managing and funding your business expenses.",
          onBack: () {
            if (_saving) return;
            if (_details) {
              setState(() => _details = false);
            } else {
              Navigator.maybePop(context);
            }
          },
          onContinue: _continue,
          continueLabel: _saving
              ? 'Saving…'
              : _details
                  ? 'Save Account'
                  : 'Continue',
          content: !_details
              ? PairAccountStep(
                  selectedSource: _selectedSource,
                  onSelected: (value) {
                    if (value != _selectedSource) _number.clear();
                    setState(() => _selectedSource = value);
                  })
              : Form(
                  key: _form,
                  child: ListView(children: [
                    Center(
                        child: Image.asset(
                            FundSources.find(_selectedSource!)!.logoPath,
                            width: 100,
                            height: 44,
                            fit: BoxFit.contain,
                            semanticLabel: _selectedSource)),
                    const SizedBox(height: 16),
                    AppFormField(
                        controller: _number,
                        maxLength: 40,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const AppInputDecoration(
                            labelText: 'Account Number'),
                        validator: (value) => (value?.length ?? 0) < 3
                            ? 'Enter at least 3 digits'
                            : null),
                    const SizedBox(height: 6),
                    AppFormField(
                        controller: _holder,
                        maxLength: 150,
                        decoration: const AppInputDecoration(
                            labelText: 'Account Holder'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null),
                  ])),
        ),
      );
}
