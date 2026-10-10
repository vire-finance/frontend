import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../pin/presentation/pin_screen.dart';
import '../../../pocket/data/pocket_repository.dart';
import '../../../pocket/presentation/owner/owner_card_form.dart';
import '../../data/document_model.dart';
import '../../providers/document_provider.dart';
import '../widgets/decline_modal.dart';
import 'owner_document_list_screen.dart';

class OwnerInvoiceFormScreen extends StatefulWidget {
  const OwnerInvoiceFormScreen({required this.document, required this.provider, super.key});

  final DocumentData document;
  final DocumentProvider provider;

  @override
  State<OwnerInvoiceFormScreen> createState() => _OwnerInvoiceFormScreenState();
}

class _OwnerInvoiceFormScreenState extends State<OwnerInvoiceFormScreen> {
  final _repository = PocketRepository.instance;
  VireCardData? _selectedCard;

  @override
  void initState() {
    super.initState();
    _repository.load().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
          title: const Text('Pay Invoice', style: TextStyle(color: AppColors.blue900, fontSize: 18, fontWeight: FontWeight.w700)),
          centerTitle: true,
          backgroundColor: AppColors.basicWhite,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AnimatedBuilder(
                animation: _repository,
                builder: (context, _) {
                  final cards = _repository.cards.where((card) =>
                      card.pocketId == widget.document.pocketId && !card.locked).toList();
                  if (_selectedCard != null && !cards.any((card) => card.id == _selectedCard!.id)) _selectedCard = null;
                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          children: [
                            const _FieldTitle('Transfer Destination', required: true),
                            const SizedBox(height: 8),
                            _SelectionBox(
                              enabled: widget.document.requestedBy?.isNotEmpty == true,
                              child: Row(children: [
                                Expanded(child: Text(widget.document.requestedBy?.isNotEmpty == true ? widget.document.requestedBy! : 'Destination unavailable', style: TextStyle(color: widget.document.requestedBy == null ? AppColors.grey400 : AppColors.grey700, fontSize: 12))),
                                const Icon(Icons.keyboard_arrow_down, color: AppColors.blue200),
                              ]),
                            ),
                            const SizedBox(height: 18),
                            const _FieldTitle('Source of Funds', required: true),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: cards.isEmpty ? null : () => _chooseCard(cards),
                              borderRadius: BorderRadius.circular(14),
                              child: _SelectionBox(
                                enabled: true,
                                child: Row(children: [
                                  const Icon(Icons.credit_card, color: AppColors.blue500, size: 31),
                                  const SizedBox(width: 13),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_selectedCard?.name ?? (cards.isEmpty ? 'No funding source available' : 'Select a card'), style: TextStyle(color: cards.isEmpty ? AppColors.grey400 : AppColors.grey700, fontSize: 15)), const SizedBox(height: 3), Text(_selectedCard == null ? 'Connect a card to pay this invoice' : 'Balance: ${formatIdr(_selectedCard!.balance)}', style: const TextStyle(color: AppColors.grey400, fontSize: 11))])),
                                  const Icon(Icons.keyboard_arrow_down, color: AppColors.blue500),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const _FieldTitle('Summary'),
                            const SizedBox(height: 8),
                            _AmountRow(label: 'Subtotal Invoice', amount: formatDocumentAmount(widget.document.amount)),
                            _AmountRow(label: 'Transfer Fee', amount: formatDocumentAmount(0)),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: AppColors.blue100)),
                            _AmountRow(label: 'Total Amount', amount: formatDocumentAmount(widget.document.amount), strong: true),
                            if (cards.isEmpty) ...[
                              const SizedBox(height: 18),
                              const Text('Payment will be available after a funding source is connected.', style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _selectedCard == null || widget.document.requestedBy?.isNotEmpty != true ? null : _confirmPayment,
                            child: const Text('Confirm & Pay'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

  Future<void> _chooseCard(List<VireCardData> cards) async {
    final selected = await showModalBottomSheet<VireCardData>(
      context: context,
      backgroundColor: AppColors.white,
      builder: (context) => SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), shrinkWrap: true, children: [
          const Padding(padding: EdgeInsets.all(8), child: Text('Select a funding source', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.blue800))),
          for (final card in cards) ListTile(leading: const Icon(Icons.credit_card, color: AppColors.blue500), title: Text(card.name), subtitle: Text('Balance: ${formatIdr(card.balance)}'), onTap: () => Navigator.pop(context, card)),
        ]),
      ),
    );
    if (selected != null && mounted) setState(() => _selectedCard = selected);
  }

  Future<void> _confirmPayment() async {
    final confirmed = await DocumentActionModal.showConfirmPayment(context);
    if (confirmed != true || !mounted) return;
    final card = _selectedCard;
    if (card == null) return;
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PinScreen(
      title: 'Enter Your Pin',
      showSuccessModal: false,
      showFingerprintButton: true,
      onPinSubmitted: (pin) async {
        try {
          final token = await AuthRepository.instance.verifyPin(pin, actionType: 'APPROVAL');
          await widget.provider.approveRequest(widget.document.id, card.id, token);
        } catch (error) {
          throw Exception(apiErrorMessage(error));
        }
      },
      onPinComplete: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const OwnerDocumentListScreen()),
        (route) => false,
      ),
    )));
  }
}

class _FieldTitle extends StatelessWidget {
  const _FieldTitle(this.text, {this.required = false});
  final String text;
  final bool required;
  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: [TextSpan(text: text, style: const TextStyle(color: AppColors.blue500, fontSize: 15)), if (required) const TextSpan(text: '  *', style: TextStyle(color: AppColors.red500, fontWeight: FontWeight.w700))]));
}

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({required this.child, required this.enabled});
  final Widget child;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12), decoration: BoxDecoration(border: Border.all(color: enabled ? AppColors.blue500 : AppColors.grey100), borderRadius: BorderRadius.circular(14)), child: child);
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.amount, this.strong = false});
  final String label;
  final String amount;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: AppColors.grey700, fontSize: strong ? 13 : 12, fontWeight: strong ? FontWeight.w600 : FontWeight.w400))), Text(amount, style: TextStyle(color: AppColors.grey700, fontSize: strong ? 16 : 12, fontWeight: FontWeight.w700))]));
}
