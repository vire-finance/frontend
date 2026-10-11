import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../history/data/transaction_model.dart';
import '../../history/data/transaction_repository.dart';
import '../../pin/presentation/pin_screen.dart';
import '../../pocket/data/pocket_repository.dart';
import '../../pocket/presentation/owner/owner_card_form.dart';
import '../data/payment_model.dart';
import '../data/payment_repository.dart';
import '../providers/payment_provider.dart';
import 'choose_card_sheet.dart';
import '../data/payment_destination.dart';
import 'payment_destination_fields.dart';
import 'expense_category_field.dart';
import 'show_qr_code_screen.dart';
import 'qr_scanner_screen.dart';
import 'transaction_complete_screen.dart';

class PaymentEntryForm extends StatefulWidget {
  const PaymentEntryForm(
      {required this.transfer,
      this.scannedCode,
      this.showQrCode = false,
      this.quickActions = false,
      super.key});
  final bool transfer;
  final String? scannedCode;
  final bool showQrCode;
  final bool quickActions;

  @override
  State<PaymentEntryForm> createState() => _PaymentEntryFormState();
}

class _PaymentEntryFormState extends State<PaymentEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentDestination? _destination;
  final _pocketRepository = PocketRepository.instance;
  final _paymentProvider = PaymentProvider(PaymentRepository.instance);
  VireCardData? _selectedCard;
  PaymentKind _kind = PaymentKind.bank;
  String? _category;
  TransactionData? _transaction;
  bool _submitting = false;
  String? _paymentKey, _paymentSignature;

  void _changeKind(PaymentKind kind) {
    if (_submitting || kind == _kind) return;
    setState(() {
      _kind = kind;
      _destination = null;
    });
  }

  @override
  void initState() {
    super.initState();
    if (!widget.transfer) _kind = PaymentKind.qris;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pocketRepository.load().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();

    _paymentProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
            title: const Text('Payment'),
            centerTitle: true,
            backgroundColor: AppColors.basicWhite,
            foregroundColor: AppColors.blue900,
            elevation: 0),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AnimatedBuilder(
                animation: _pocketRepository,
                builder: (context, _) {
                  final cards = _pocketRepository.cards
                      .where((card) => card.canPay)
                      .toList();
                  if (_selectedCard != null) {
                    final matching =
                        cards.where((card) => card.id == _selectedCard!.id);
                    _selectedCard = matching.isEmpty ? null : matching.first;
                  }
                  if (!(_selectedCard?.allowedCategories ?? const <String>[])
                      .contains(_category)) _category = null;
                  return Form(
                    key: _formKey,
                    child: Column(children: [
                      Expanded(
                          child: ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 20),
                              children: [
                            if (widget.quickActions) ...[
                              Row(children: [
                                Expanded(
                                    child: _ModeCard(
                                  icon: Icons.qr_code_scanner,
                                  label: 'Scan QRIS',
                                  selected: false,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const QrScannerScreen())),
                                )),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _ModeCard(
                                  icon: Icons.qr_code_2,
                                  label: 'Show Code',
                                  selected: false,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const PaymentEntryForm(
                                                  transfer: false,
                                                  showQrCode: true))),
                                )),
                              ]),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (_) => const PaymentEntryForm(
                                            transfer: true))),
                                icon: const Icon(Icons.account_balance),
                                label:
                                    const Text('Transfer to Bank / E-Wallet'),
                              ),
                              const SizedBox(height: 18),
                            ],
                            if (widget.transfer) ...[
                              Row(children: [
                                Expanded(
                                    child: _ModeCard(
                                        icon: Icons.account_balance,
                                        label: 'Bank',
                                        selected: _kind == PaymentKind.bank,
                                        onTap: () =>
                                            _changeKind(PaymentKind.bank))),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _ModeCard(
                                        icon: Icons.account_balance_wallet,
                                        label: 'E-Wallet',
                                        selected: _kind == PaymentKind.eWallet,
                                        onTap: () =>
                                            _changeKind(PaymentKind.eWallet))),
                              ]),
                              const SizedBox(height: 18),
                              PaymentDestinationFields(
                                  key: ValueKey(_kind),
                                  bank: _kind == PaymentKind.bank,
                                  enabled: !_submitting,
                                  onChanged: (destination) =>
                                      _destination = destination),
                              const SizedBox(height: 18),
                            ] else if (widget.scannedCode != null) ...[
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: AppColors.blue50,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Row(children: [
                                    Icon(Icons.qr_code_scanner,
                                        color: AppColors.blue500),
                                    SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            'QR scanned. The current backend does not validate its merchant data; check the merchant and amount before paying.',
                                            style: TextStyle(
                                                color: AppColors.blue700,
                                                fontSize: 12)))
                                  ])),
                              const SizedBox(height: 18),
                            ],
                            _FormLabel('Choose Which Card to Pay With',
                                required: true),
                            const SizedBox(height: 8),
                            _CardSelector(
                                card: _selectedCard,
                                cardsAvailable: cards.isNotEmpty,
                                onTap: cards.isEmpty
                                    ? null
                                    : () async {
                                        final card = await ChooseCardSheet.show(
                                            context, cards);
                                        if (card != null && mounted)
                                          setState(() {
                                            _selectedCard = card;
                                            if (!card.allowedCategories
                                                .contains(_category))
                                              _category = null;
                                          });
                                      }),
                            if (cards.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text('No active cards are available.',
                                      style: TextStyle(
                                          color: AppColors.grey500,
                                          fontSize: 11))),
                            const SizedBox(height: 18),
                            _FormLabel('Transaction Title', required: true),
                            const SizedBox(height: 8),
                            _InputField(
                                controller: _titleController,
                                hint: 'Type here',
                                validator: _required),
                            const SizedBox(height: 18),
                            ExpenseCategoryField(
                                value: _category,
                                categories: _selectedCard?.allowedCategories ??
                                    const [],
                                onChanged: _submitting || _selectedCard == null
                                    ? null
                                    : (value) =>
                                        setState(() => _category = value)),
                            const SizedBox(height: 18),
                            _FormLabel('Total Amount (IDR)', required: true),
                            const SizedBox(height: 8),
                            _InputField(
                                controller: _amountController,
                                hint: 'Type here',
                                keyboardType: TextInputType.number,
                                inputFormatters: [const IdrInputFormatter()],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'Required';
                                  if (parseIdrInput(value) == null ||
                                      parseIdrInput(value)! <= 0)
                                    return 'Enter an amount greater than zero';
                                  if (_selectedCard != null &&
                                      parseIdrInput(value)! >
                                          _selectedCard!.balance)
                                    return 'Amount exceeds the available balance';
                                  return null;
                                }),
                          ])),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                          child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                  onPressed:
                                      _selectedCard == null || _submitting
                                          ? null
                                          : _submit,
                                  child: Text(_submitting
                                      ? 'Please wait…'
                                      : widget.showQrCode
                                          ? 'Show QR Code'
                                          : 'Pay')))),
                    ]),
                  );
                },
              ),
            ),
          ),
        ),
      );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  Future<void> _submit() async {
    if (_submitting ||
        !_formKey.currentState!.validate() ||
        _selectedCard == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      _transaction = null;
      final draft = PaymentDraft(
        kind: _kind,
        category: _category!,
        title: _titleController.text.trim(),
        amount: parseIdrInput(_amountController.text)!,
        sourceCard: _selectedCard!,
        destinationMethod: widget.transfer ? _destination?.display : null,
        destination: widget.transfer ? _destination : null,
        scannedCode: widget.scannedCode,
      );
      final signature = [
        draft.sourceCard.id,
        draft.amount,
        draft.title,
        draft.category,
        draft.kind.name,
        draft.destination?.toJson().toString() ?? draft.destinationMethod
      ].toString();
      if (_paymentSignature != signature) {
        _paymentSignature = signature;
        _paymentKey = ApiClient.newIdempotencyKey();
      }
      final paymentKey = _paymentKey!;
      if (widget.showQrCode) {
        String? verifiedToken;
        final token = await Navigator.of(context).push<String>(
          MaterialPageRoute<String>(
              builder: (pinContext) => PinScreen(
                    title: 'Enter Your Pin',
                    showSuccessModal: false,
                    onPinSubmitted: (pin) async {
                      try {
                        verifiedToken = await AuthRepository.instance
                            .verifyPin(pin, actionType: 'PAYMENT');
                      } catch (error) {
                        throw Exception(apiErrorMessage(error));
                      }
                    },
                    onPinComplete: () {
                      if (pinContext.mounted && verifiedToken != null) {
                        Navigator.pop(pinContext, verifiedToken);
                      }
                    },
                  )),
        );
        if (token == null || !mounted) return;
        final confirmed = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
              builder: (_) => ShowQrCodeScreen(
                    code:
                        'VIRE-SIMULATED-PAYMENT|$paymentKey|${draft.sourceCard.id}|${draft.amount}',
                    payment: draft,
                  )),
        );
        if (confirmed != true || !mounted) return;
        final transaction =
            await TransactionRepository.instance.createCardPayment(
          card: draft.sourceCard,
          title: draft.title,
          amount: draft.amount,
          actionToken: token,
          category: draft.category,
          paymentMethod: 'QRIS',
          idempotencyKey: paymentKey,
        );
        final complete = _paymentProvider.complete(draft,
            transactionId: transaction.id, completedAt: transaction.dateTime);
        // The payment is committed; a balance refresh must not offer a second payment.
        await _pocketRepository.load().catchError((_) {});
        if (!mounted) return;
        await Navigator.of(context).push<void>(MaterialPageRoute<void>(
            builder: (_) => TransactionCompleteScreen(
                payment: complete, receiptRequestId: transaction.requestId)));
        return;
      }
      if (!mounted) return;
      final navigator = Navigator.of(context);
      await navigator.push<void>(MaterialPageRoute<void>(
          builder: (_) => PinScreen(
              title: 'Enter Your Pin',
              showSuccessModal: false,
              onPinComplete: () {
                final transaction = _transaction;
                if (transaction == null) return;
                final complete = _paymentProvider.complete(draft,
                    transactionId: transaction.id,
                    completedAt: transaction.dateTime);
                navigator.pushReplacement(MaterialPageRoute<void>(
                    builder: (_) => TransactionCompleteScreen(
                        payment: complete,
                        receiptRequestId: transaction.requestId)));
              },
              onPinSubmitted: (pin) async {
                try {
                  final token = await AuthRepository.instance
                      .verifyPin(pin, actionType: 'PAYMENT');
                  _transaction =
                      await TransactionRepository.instance.createCardPayment(
                          card: draft.sourceCard,
                          title: draft.title,
                          amount: draft.amount,
                          actionToken: token,
                          category: draft.category,
                          paymentMethod: draft.kind == PaymentKind.bank
                              ? 'BANK_TRANSFER'
                              : draft.kind == PaymentKind.eWallet
                                  ? 'E_WALLET'
                                  : 'QRIS',
                          destination: draft.destination,
                          idempotencyKey: paymentKey);
                  await _pocketRepository.load().catchError((_) {});
                } catch (error) {
                  throw Exception(apiErrorMessage(error));
                }
              })));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
          height: 98,
          decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(
                  color: selected ? AppColors.blue500 : AppColors.grey50),
              borderRadius: BorderRadius.circular(10)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppColors.blue500, size: 34),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.blue600,
                    fontSize: 17,
                    fontWeight: FontWeight.w700))
          ])));
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text, {this.required = false});
  final String text;
  final bool required;
  @override
  Widget build(BuildContext context) =>
      AppInputLabel(text, requiredField: required);
}

class _InputField extends StatelessWidget {
  const _InputField(
      {required this.controller,
      required this.hint,
      this.validator,
      this.keyboardType,
      this.inputFormatters});
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  @override
  Widget build(BuildContext context) => AppFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: AppInputDecoration(hintText: hint));
}

class _CardSelector extends StatelessWidget {
  const _CardSelector(
      {required this.card, required this.cardsAvailable, required this.onTap});
  final VireCardData? card;
  final bool cardsAvailable;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AppPickerField(
        value: card == null ? null : '${card!.name}  •••• ${card!.lastFour}',
        onTap: onTap,
        decoration: AppInputDecoration(
          hintText: cardsAvailable
              ? 'Click here to choose'
              : 'No cards available',
        ),
      );
}

