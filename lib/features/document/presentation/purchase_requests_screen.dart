import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/export_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/constants/expense_categories.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../data/ocr_repository.dart';
import '../data/employee_request_model.dart';
import 'employee/employee_request_confirmation_screen.dart';
import 'widgets/decline_modal.dart';
import '../../auth/data/auth_repository.dart';
import '../../pin/presentation/pin_screen.dart';
import '../../pocket/data/employee_pocket_repository.dart';
import '../../pocket/data/pocket_repository.dart';
import '../../pocket/presentation/owner/owner_card_form.dart';
import '../../history/presentation/history_screen.dart';

String purchaseStatus(Map<String, dynamic> row) =>
    switch ('${row['workflow_status'] ?? row['status']}') {
      'PENDING_APPROVAL' => 'Pending Approval',
      'AWAITING_PAYMENT' => 'Pending Payment',
      'AWAITING_RECEIPT' => 'Awaiting Receipt',
      'RECEIPT_SUBMITTED' => 'Ready for Review',
      'NEEDS_CLARIFICATION' => 'Needs Clarification',
      'RECEIPT_OVERDUE' => 'Receipt Overdue',
      'COMPLETED' || 'VERIFIED' => 'Verified',
      'INVOICE_PAID' => 'Invoice Paid',
      'REJECTED' => 'Rejected',
      _ => 'Draft',
    };

class PurchaseRequestsScreen extends StatefulWidget {
  const PurchaseRequestsScreen(
      {required this.owner,
      this.title = 'Purchase Requests',
      this.paymentInbox = false,
      super.key});
  final bool owner;
  final String title;
  final bool paymentInbox;
  @override
  State<PurchaseRequestsScreen> createState() => _PurchaseRequestsScreenState();
}

class _PurchaseRequestsScreenState extends State<PurchaseRequestsScreen>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  String? _error;
  bool _loading = true, _fetching = false;
  int _tab = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (ModalRoute.of(context)?.isCurrent == true) _load(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (_fetching) return;
    _fetching = true;
    try {
      final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
          '/fund-requests',
          queryParameters: {'limit': 200});
      if (mounted)
        setState(() {
          _rows = (response.data?['items'] as List? ?? [])
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
          _error = null;
        });
    } catch (e) {
      if (mounted && !silent) setState(() => _error = apiErrorMessage(e));
    } finally {
      _fetching = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(String id) async {
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) =>
                PurchaseRequestDetailScreen(id: id, owner: widget.owner)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows.where((r) {
      final closed = ['COMPLETED', 'REJECTED'].contains(r['status']);
      final pending = r['status'] == 'PENDING_APPROVAL';
      final matches = widget.owner
          ? (_tab == 0
              ? pending
              : _tab == 1
                  ? !closed && !pending
                  : closed)
          : widget.paymentInbox
              ? (_tab == 0
                  ? r['workflow_status'] == 'AWAITING_PAYMENT'
                  : _tab == 1
                      ? !closed && r['workflow_status'] != 'AWAITING_PAYMENT'
                      : closed)
              : (_tab == 0 ? !closed : closed);
      return matches &&
          '${r['party_name']} ${r['explanation']} ${r['display_id']}'
              .toLowerCase()
              .contains(_search.text.toLowerCase());
    }).toList();
    return Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(title: Text(widget.title)),
        body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  if (!widget.owner) ...[
                    FilledButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const PurchaseRequestFormScreen()));
                          await _load();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('New Purchase Request')),
                    const SizedBox(height: 16)
                  ],
                  Wrap(spacing: 8, children: [
                    for (var i = 0;
                        i < (widget.owner || widget.paymentInbox ? 3 : 2);
                        i++)
                      ChoiceChip(
                          label: Text(widget.owner
                              ? ['Pending Approval', 'Open', 'Closed'][i]
                              : widget.paymentInbox
                                  ? [
                                      'Pending Payment',
                                      'Other Open',
                                      'Closed'
                                    ][i]
                                  : ['Open', 'Closed'][i]),
                          selected: _tab == i,
                          onSelected: (_) => setState(() => _tab = i))
                  ]),
                  const SizedBox(height: 16),
                  AppSearchBar(
                      controller: _search,
                      hint: 'Search purchase requests...',
                      onChanged: (_) => setState(() {})),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: AppColors.red500)),
                  if (!_loading && rows.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No purchase requests here yet.')),
                  for (final r in rows)
                    Card(
                        child: ListTile(
                            onTap: () => _open('${r['id']}'),
                            title: Text('${r['party_name']}'),
                            subtitle: Text(
                                '${r['payment_executor'] == 'OWNER_PAYMENT' ? 'Owner Payment · Invoice' : 'Employee Payment'}\n${purchaseStatus(r)}',
                                style: TextStyle(
                                    color: r['workflow_status'] ==
                                            'RECEIPT_OVERDUE'
                                        ? AppColors.red500
                                        : AppColors.grey600)),
                            isThreeLine: true,
                            trailing:
                                Text(formatIdr(_amount(r['total_amount']))))),
                ])));
  }
}

int _amount(dynamic v) =>
    v is num ? v.round() : num.tryParse('$v')?.round() ?? 0;

class PurchaseRequestFormScreen extends StatefulWidget {
  const PurchaseRequestFormScreen({this.initialRequest, super.key});
  final Map<String, dynamic>? initialRequest;
  @override
  State<PurchaseRequestFormScreen> createState() =>
      _PurchaseRequestFormScreenState();
}

class _PurchaseRequestFormScreenState extends State<PurchaseRequestFormScreen> {
  final _form = GlobalKey<FormState>();
  final _purpose = TextEditingController(),
      _party = TextEditingController(),
      _amountInput = TextEditingController(),
      _account = TextEditingController();
  List<VireCardData> _cards = [];
  VireCardData? _card;
  final String _executor = 'OWNER_PAYMENT';
  String _method = 'BANK_TRANSFER';
  String? _category, _invoiceId, _invoiceName, _draftId, _invoiceStatus;
  final _purposeFocus = FocusNode();
  DateTime? _neededBy;
  bool _busy = false, _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    final row = widget.initialRequest;
    if (row != null) {
      _draftId = '${row['id']}';
      _purpose.text = '${row['explanation'] ?? ''}';
      _party.text = '${row['party_name'] ?? ''}';
      _amountInput.text = formatIdrInput(_amount(row['total_amount']));
      _category = '${row['category'] ?? 'Others'}';
      _method = '${row['payment_method'] ?? 'BANK_TRANSFER'}';
      _account.text = '${row['recipient_account'] ?? ''}';
    }
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      await EmployeePocketRepository.instance.load();
      if (mounted)
        setState(() {
          _cards = EmployeePocketRepository.instance.accessibleCards;
          final id = widget.initialRequest?['card_id'];
          for (final card in _cards) {
            if (card.id == id) _card = card;
          }
        });
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _purposeFocus.dispose();
    _purpose.dispose();
    _party.dispose();
    _amountInput.dispose();
    _account.dispose();
    super.dispose();
  }

  Future<void> _invoice() async {
    setState(() => _busy = true);
    try {
      final doc = await pickPurchaseDocument();
      if (doc != null && mounted) {
        setState(() {
          _invoiceId = doc.$1;
          _invoiceName = doc.$2;
          _invoiceStatus = 'PROCESSING';
          _error = null;
        });
        final result = await OcrRepository.instance.waitForResult(
            UploadedRequestDocument(
                id: doc.$1, status: 'PROCESSING', fileName: doc.$2));
        if (!mounted) return;
        setState(() => _invoiceStatus = result.status);
        if (result.status == 'COMPLETED') {
          final data = await OcrRepository.instance.prefill(result.id);
          if (!mounted) return;
          setState(() {
            if (_party.text.trim().isEmpty && data['party_name'] != null) {
              _party.text = '${data['party_name']}';
            }
            if (_amountInput.text.trim().isEmpty &&
                data['total_amount'] != null) {
              _amountInput.text = formatIdrInput(_amount(data['total_amount']));
            }
          });
        } else {
          setState(() => _error = result.status == 'FAILED'
              ? 'The invoice needs manual review. Enter its details below.'
              : 'Invoice scanning is still processing. Tap Scan Document to retry.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _card == null) return;
    if (_neededBy == null) {
      setState(() => _error = 'Choose when you need this purchase.');
      return;
    }
    if (_executor == 'OWNER_PAYMENT' && _invoiceId == null) {
      setState(
          () => _error = 'An invoice is required for Owner Payment Request.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ApiClient.instance.dio;
      final payload = {
        'card_id': _card!.id,
        'pocket_id': _card!.pocketId,
        'request_type': 'PURCHASE',
        'payment_executor': _executor,
        'payment_method': _method,
        'recipient_account':
            _account.text.trim().isEmpty ? null : _account.text.trim(),
        'category': _category,
        'explanation': _purpose.text.trim(),
        'party_name': _party.text.trim(),
        'total_amount': parseIdrInput(_amountInput.text),
        'needed_by': _neededBy!.toUtc().toIso8601String()
      };
      final response = _draftId == null
          ? await api.post<Map<String, dynamic>>('/fund-requests',
              data: payload)
          : await api.put<Map<String, dynamic>>('/fund-requests/$_draftId',
              data: payload);
      _draftId = '${response.data!['id']}';
      if (_executor == 'OWNER_PAYMENT')
        await api.post('/fund-requests/$_draftId/documents',
            data: {'document_id': _invoiceId});
      final sent = await api.post<Map<String, dynamic>>(
          '/fund-requests/$_draftId/submit',
          data: {'allow_failed_ocr': true});
      if (mounted) {
        final row = sent.data ?? response.data!;
        await Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
                builder: (_) => EmployeeRequestConfirmationScreen(
                    request: EmployeePaymentRequest(
                        id: _draftId!,
                        reference: '${row['display_id'] ?? _draftId}',
                        pocketId: _card!.pocketId,
                        explanation: _purpose.text.trim(),
                        requestType: 'Invoice',
                        partyName: _party.text.trim(),
                        amount: parseIdrInput(_amountInput.text)!,
                        neededAt: _neededBy!,
                        createdAt: DateTime.tryParse('${row['created_at']}')
                                ?.toLocal() ??
                            DateTime.now(),
                        ocrDocumentId: _invoiceId))));
      }
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveDocument() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    if (_invoiceId == null) {
      setState(() => _error = 'Scan or attach an invoice before saving.');
      return;
    }
    if (!['COMPLETED', 'FAILED'].contains(_invoiceStatus)) {
      setState(() => _error = 'Wait for invoice scanning to finish.');
      return;
    }
    final paymentForm = GlobalKey<FormState>();
    final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.basicWhite,
        builder: (sheetContext) =>
            StatefulBuilder(builder: (context, updateSheet) {
              return SafeArea(
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20,
                          MediaQuery.viewInsetsOf(context).bottom + 20),
                      child: SingleChildScrollView(
                          child: Form(
                              key: paymentForm,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Payment Details',
                                        style: TextStyle(
                                            color: AppColors.blue900,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18)),
                                    const SizedBox(height: 8),
                                    const Text(
                                        'Choose the card and merchant destination for your owner to pay this invoice.'),
                                    const SizedBox(height: 20),
                                    AppDropdownField<VireCardData>(
                                        value: _card,
                                        decoration: const AppInputDecoration(
                                            labelText: 'Card'),
                                        validator: (v) =>
                                            v == null ? 'Choose a card' : null,
                                        items: [
                                          for (final card in _cards)
                                            DropdownMenuItem(
                                                value: card,
                                                child: Text(
                                                    '${card.name} · ${card.lastFour}',
                                                    overflow:
                                                        TextOverflow.ellipsis))
                                        ],
                                        onChanged: (v) =>
                                            updateSheet(() => _card = v)),
                                    const SizedBox(height: 18),
                                    AppDropdownField<String>(
                                        value: _method,
                                        decoration: const AppInputDecoration(
                                            labelText: 'Payment Method'),
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'QRIS',
                                              child: Text('QRIS')),
                                          DropdownMenuItem(
                                              value: 'BANK_TRANSFER',
                                              child: Text('Bank Transfer')),
                                          DropdownMenuItem(
                                              value: 'E_WALLET',
                                              child: Text('E-Wallet Transfer'))
                                        ],
                                        onChanged: (v) =>
                                            updateSheet(() => _method = v!)),
                                    const SizedBox(height: 18),
                                    AppFormField(
                                        controller: _account,
                                        decoration: AppInputDecoration(
                                            labelText: _method == 'QRIS'
                                                ? 'Merchant QR / Payment Reference'
                                                : 'Bank / E-Wallet and Destination Number'),
                                        validator: _required),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: FilledButton(
                                            onPressed: () {
                                              if (paymentForm.currentState!
                                                  .validate()) {
                                                Navigator.pop(
                                                    sheetContext, true);
                                              }
                                            },
                                            child: const Text('Send Request'))),
                                  ])))));
            }));
    if (confirmed == true && mounted) await _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.basicWhite,
      appBar: AppBar(
          title: const Text('New Request',
              style: TextStyle(
                  color: AppColors.blue900,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          centerTitle: true,
          backgroundColor: AppColors.basicWhite,
          foregroundColor: AppColors.blue900,
          elevation: 0),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                      key: _form,
                      child: Column(children: [
                        Expanded(
                            child: ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                children: [
                              if (_loading) const LinearProgressIndicator(),
                              const Text('Input From Document',
                                  style: TextStyle(
                                      color: AppColors.blue500,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const SizedBox(height: 16),
                              Row(children: [
                                Expanded(
                                    child: SizedBox(
                                        height: 50,
                                        child: OutlinedButton.icon(
                                            onPressed: _busy ? null : _invoice,
                                            style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.blue500,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                side: const BorderSide(
                                                    color: AppColors.blue500)),
                                            icon: _busy
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2))
                                                : const Icon(
                                                    Icons.document_scanner_outlined),
                                            label: Text(_invoiceName ?? 'Scan Document', maxLines: 1, overflow: TextOverflow.ellipsis)))),
                                const SizedBox(width: 14),
                                Expanded(
                                    child: SizedBox(
                                        height: 50,
                                        child: FilledButton.icon(
                                            onPressed: _busy
                                                ? null
                                                : () => _purposeFocus
                                                    .requestFocus(),
                                            style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.blue500,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10))),
                                            icon: const Icon(
                                                Icons.article_rounded),
                                            label: const Text('Add Request')))),
                              ]),
                              const SizedBox(height: 24),
                              const Text('Request Details',
                                  style: TextStyle(
                                      color: AppColors.blue500,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const SizedBox(height: 18),
                              AppFormField(
                                  controller: _purpose,
                                  focusNode: _purposeFocus,
                                  decoration: const AppInputDecoration(
                                      labelText: 'Request Explanation'),
                                  validator: _required),
                              const SizedBox(height: 22),
                              AppDropdownField<String>(
                                  value: _category,
                                  decoration: const AppInputDecoration(
                                      labelText: 'Request Type'),
                                  validator: (v) =>
                                      v == null ? 'Choose a category' : null,
                                  items: [
                                    for (final category in expenseCategories
                                        .where((c) => c != 'Salary'))
                                      DropdownMenuItem(
                                          value: category,
                                          child: Text(category))
                                  ],
                                  onChanged: _busy
                                      ? null
                                      : (v) => setState(() => _category = v)),
                              const SizedBox(height: 22),
                              AppFormField(
                                  controller: _party,
                                  decoration: const AppInputDecoration(
                                      labelText: "Other Party's Name"),
                                  validator: _required),
                              const SizedBox(height: 22),
                              AppFormField(
                                  controller: _amountInput,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [const IdrInputFormatter()],
                                  decoration: const AppInputDecoration(
                                      labelText: 'Total Amount (IDR)'),
                                  validator: (v) =>
                                      (parseIdrInput(v ?? '') ?? 0) > 0
                                          ? null
                                          : 'Enter a valid amount'),
                              const SizedBox(height: 22),
                              const AppInputLabel('When do you need it by?',
                                  requiredField: true),
                              const SizedBox(height: 8),
                              TextFormField(
                                  key: ValueKey(_neededBy),
                                  readOnly: true,
                                  initialValue: _neededBy == null
                                      ? ''
                                      : '${_neededBy!.day}/${_neededBy!.month}/${_neededBy!.year}',
                                  style: AppInputStyles.value,
                                  decoration: const AppInputDecoration(
                                      hintText: 'Input date and time'),
                                  validator: (_) => _neededBy == null
                                      ? 'Choose a date'
                                      : null,
                                  onTap: _busy
                                      ? null
                                      : () async {
                                          final now = DateTime.now();
                                          final date = await showDatePicker(
                                              context: context,
                                              initialDate: _neededBy ?? now,
                                              firstDate: DateTime(
                                                  now.year, now.month, now.day),
                                              lastDate: DateTime(now.year + 5));
                                          if (date != null && mounted)
                                            setState(() => _neededBy = DateTime(
                                                date.year,
                                                date.month,
                                                date.day,
                                                23,
                                                59,
                                                59));
                                        }),
                              if (_error != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(_error!,
                                        style: const TextStyle(
                                            color: AppColors.red500))),
                            ])),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                            child: SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.blue500,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10))),
                                    onPressed: _busy || _loading
                                        ? null
                                        : _saveDocument,
                                    child: Text(_busy
                                        ? 'Saving...'
                                        : 'Save Document')))),
                      ]))))),
    );
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;
}

Future<(String, String)?> pickPurchaseDocument() async {
  final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true);
  if (picked == null) return null;
  final file = picked.files.single;
  if (file.size > 5 * 1024 * 1024)
    throw StateError('Maximum file size is 5 MB.');
  final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/ocr/documents',
      data: FormData.fromMap(
          {'file': MultipartFile.fromBytes(file.bytes!, filename: file.name)}),
      options: Options(contentType: 'multipart/form-data'));
  return ('${response.data!['document_id']}', file.name);
}

class PurchaseRequestDetailScreen extends StatefulWidget {
  const PurchaseRequestDetailScreen(
      {required this.id,
      required this.owner,
      this.receiptOnly = false,
      super.key});
  final String id;
  final bool owner, receiptOnly;
  @override
  State<PurchaseRequestDetailScreen> createState() =>
      _PurchaseRequestDetailScreenState();
}

class _PurchaseRequestDetailScreenState
    extends State<PurchaseRequestDetailScreen> {
  Map<String, dynamic>? _row;
  String? _error;
  bool _busy = false;
  final _note = TextEditingController();
  final _approvalKey = ApiClient.newIdempotencyKey();
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.dio
          .get<Map<String, dynamic>>('/fund-requests/${widget.id}');
      if (mounted) setState(() => _row = res.data);
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    }
  }

  Future<void> _pin(
      String action, Future<void> Function(String token) operation) async {
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => PinScreen(
                title: 'Enter Your Pin',
                showSuccessModal: false,
                onPinSubmitted: (pin) async {
                  final token = await AuthRepository.instance
                      .verifyPin(pin, actionType: action);
                  await operation(token);
                },
                onPinComplete: () {
                  Navigator.pop(context);
                })));
    await _load();
  }

  Future<String?> _reason(String title) async {
    final controller = TextEditingController();
    final answer = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(title),
                content: AppFormField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const AppInputDecoration(
                        hintText: 'Explain your reason')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty)
                          Navigator.pop(ctx, controller.text.trim());
                      },
                      child: const Text('Confirm'))
                ]));
    controller.dispose();
    return answer;
  }

  Future<void> _approve() async {
    final confirmed = await DocumentActionModal.showConfirmPayment(context,
        message:
            'Approving this will approve the request and pay the invoice from your main fund account.');
    if (confirmed != true || !mounted) return;
    final r = _row!;
    String? cardId = r['card_id'] as String?;
    if (cardId == null) {
      await PocketRepository.instance.load();
      final cards = PocketRepository.instance.cards
          .where((c) => c.pocketId == '${r['pocket_id']}')
          .toList();
      if (!mounted) return;
      cardId = await showDialog<String>(
          context: context,
          builder: (ctx) =>
              SimpleDialog(title: const Text('Choose payment card'), children: [
                for (final c in cards)
                  SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, c.id),
                      child: Text('${c.name} · ${c.lastFour}'))
              ]));
    }
    if (cardId == null || !mounted) return;
    await _pin('APPROVAL', (token) async {
      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
          '/fund-requests/${widget.id}/approve',
          data: {'card_id': cardId},
          options: Options(headers: {
            'X-Action-Token': token,
            'Idempotency-Key': _approvalKey
          }));
      if (response.data?['failure_reason'] != null)
        throw StateError('${response.data!['failure_reason']}');
    });
  }

  Future<void> _reject() async {
    final reason = await DocumentActionModal.showDecline(context);
    if (reason == null || !mounted) return;
    await _pin('APPROVAL', (token) async {
      await ApiClient.instance.dio.post('/fund-requests/${widget.id}/reject',
          data: {'reason': reason},
          options: Options(headers: {'X-Action-Token': token}));
    });
  }

  Future<void> _review(bool verified) async {
    final reason = verified ? '' : await _reason('Request Clarification');
    if (reason == null || !mounted) return;
    await _pin('APPROVAL', (token) async {
      await ApiClient.instance.dio.post(
          '/fund-requests/${widget.id}/receipt/review',
          data: {
            'decision': verified ? 'VERIFIED' : 'NEEDS_CLARIFICATION',
            'reason': reason
          },
          options: Options(headers: {'X-Action-Token': token}));
    });
  }

  Future<void> _receipt() async {
    setState(() => _busy = true);
    try {
      final doc = await pickPurchaseDocument();
      if (doc != null) {
        await ApiClient.instance.dio.post('/fund-requests/${widget.id}/receipt',
            data: {'document_id': doc.$1, 'note': _note.text.trim()});
        await _load();
      }
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _file(String path, String name) async {
    try {
      await ExportService.instance.shareBackendFile(path, fileName: name);
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _row;
    return Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
            title: Text(
                widget.receiptOnly
                    ? (r?['payment_executor'] == 'OWNER_PAYMENT'
                        ? 'Invoice & Payment'
                        : 'Purchase Receipt')
                    : 'Document Review',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            centerTitle: true,
            backgroundColor: AppColors.basicWhite,
            foregroundColor: AppColors.blue900,
            elevation: 0),
        bottomNavigationBar: widget.owner &&
                r != null &&
                r['payment_executor'] == 'OWNER_PAYMENT' &&
                r['status'] == 'PENDING_APPROVAL'
            ? SafeArea(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                              onPressed: _reject,
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.blue500),
                              child: const Text('Decline'))),
                      const SizedBox(height: 8),
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                              onPressed: _approve,
                              style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFBFCEF0),
                                  foregroundColor: AppColors.blue700),
                              child: const Text('Approve & Pay Invoice'))),
                    ])))
            : null,
        body: r == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Text(_error!))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  IntrinsicHeight(
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        Expanded(
                            child: Column(children: [
                          Text('${r['display_id'] ?? 'Invoice'}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue900)),
                          const SizedBox(height: 24),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E8),
                                  border:
                                      Border.all(color: AppColors.orange500),
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text('Purchase',
                                  style:
                                      TextStyle(color: AppColors.orange500))),
                        ])),
                        const VerticalDivider(width: 24),
                        Expanded(
                            child: Column(children: [
                          const Text('Requested By',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue900)),
                          const SizedBox(height: 10),
                          ClipOval(
                              child: _requesterAvatar(
                                  r['requester']?['avatar_url'])),
                          const SizedBox(height: 8),
                          Text(
                              "${r['requester']?['name'] ?? 'Employee'} - Employee",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.blue500,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ])),
                      ])),
                  const SizedBox(height: 20),
                  if (r['paid_at'] != null) ...[
                    Text(
                        r['payment_executor'] == 'OWNER_PAYMENT'
                            ? 'Paid by Owner'
                            : 'Payment Completed',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                  ] else if (r['payment_executor'] == 'EMPLOYEE_PAYMENT') ...[
                    const Text(
                        'Invoice required: this older request has not been paid.',
                        style: TextStyle(color: AppColors.orange500)),
                    const SizedBox(height: 16),
                  ],
                  _info('Document Explanation', r['explanation']),
                  const SizedBox(height: 10),
                  const Text('Document',
                      style: TextStyle(
                          color: AppColors.blue500,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  if ((r['documents'] as List? ?? []).isEmpty)
                    const Text('No invoice attached.'),
                  for (final d in (r['documents'] as List? ?? []))
                    if ('${d['id']}' != '${r['receipt']?['id']}')
                      Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                              border: Border.all(color: AppColors.grey50),
                              borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                              leading: Icon(Icons.picture_as_pdf_outlined,
                                  color: '${d['mime_type']}'.contains('pdf')
                                      ? Colors.red
                                      : AppColors.blue500),
                              title: Text('${d['original_filename']}',
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  '${d['created_at'] ?? ''}'.split('T').first),
                              trailing: IconButton(
                                  icon: const Icon(Icons.download_outlined,
                                      color: AppColors.blue500),
                                  onPressed: () => _file('${d['download_url']}',
                                      '${d['original_filename']}')))),
                  const SizedBox(height: 12),
                  _info('Party Name', r['party_name']),
                  const Text('Amount',
                      style: TextStyle(
                          color: AppColors.blue500,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(formatIdr(_amount(r['total_amount'])),
                      style: const TextStyle(
                          color: AppColors.orange500,
                          fontSize: 28,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  _info(
                      'Date',
                      '${r['needed_by'] ?? r['created_at'] ?? ''}'
                          .split('T')
                          .first),
                  Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEDEFFC),
                          border: Border.all(color: AppColors.blue500),
                          borderRadius: BorderRadius.circular(18)),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome_outlined,
                                color: AppColors.blue500, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Text('AI Analysis',
                                      style: TextStyle(
                                          color: AppColors.blue500,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text(
                                      '${r['ai_analysis']?['summary'] ?? 'Analysis unavailable. Review the invoice details manually.'}',
                                      style: const TextStyle(
                                          color: AppColors.blue500,
                                          height: 1.5,
                                          fontSize: 12)),
                                ])),
                          ])),
                  if (r['rejection_reason'] != null)
                    _info('Rejection Reason', r['rejection_reason']),
                  if (r['paid_at'] != null) ...[
                    if (r['receipt_due_at'] != null)
                      _info('Receipt Due', r['receipt_due_at']),
                    if (r['receipt_review_reason'] != null)
                      _info('Owner Review', r['receipt_review_reason']),
                    if (r['receipt'] != null)
                      OutlinedButton.icon(
                          onPressed: () => _file(
                              '${r['receipt']['download_url']}',
                              '${r['receipt']['file_name']}'),
                          icon: const Icon(Icons.receipt_long),
                          label: Text('${r['receipt']['file_name']}')),
                    if (r['receipt_note'] != null)
                      _info('Receipt Explanation', r['receipt_note'])
                  ],
                  if (!widget.owner &&
                      r['paid_at'] == null &&
                      r['payment_executor'] == 'EMPLOYEE_PAYMENT' &&
                      ['PENDING_APPROVAL', 'APPROVED']
                          .contains(r['status'])) ...[
                    const Text(
                        'This older request has not been paid. Attach an invoice and send it again for your owner to approve and pay.'),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => PurchaseRequestFormScreen(
                                      initialRequest: r)));
                          await _load();
                        },
                        child: const Text('Complete Invoice Request')),
                  ],
                  if (!widget.owner &&
                      r['paid_at'] != null &&
                      r['status'] == 'APPROVED' &&
                      r['receipt_status'] != 'RECEIPT_SUBMITTED') ...[
                    if (widget.receiptOnly) ...[
                      AppFormField(
                          controller: _note,
                          maxLines: 3,
                          decoration: const AppInputDecoration(
                              labelText: 'Receipt Explanation')),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                          onPressed: _busy ? null : _receipt,
                          icon: const Icon(Icons.upload_file),
                          label:
                              Text(_busy ? 'Uploading...' : 'Upload Receipt'))
                    ] else
                      FilledButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => const HistoryScreen())),
                          icon: const Icon(Icons.history),
                          label: const Text('Upload Receipt in History')),
                  ],
                  if (widget.owner &&
                      r['receipt_status'] == 'RECEIPT_SUBMITTED') ...[
                    FilledButton(
                        onPressed: () => _review(true),
                        child: const Text('Verify & Close')),
                    OutlinedButton(
                        onPressed: () => _review(false),
                        child: const Text('Needs Clarification'))
                  ],
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: AppColors.red500)),
                ])));
  }

  Widget _requesterAvatar(dynamic value) {
    final path = '$value';
    if (path.startsWith('assets/'))
      return Image.asset(path, width: 56, height: 56, fit: BoxFit.cover);
    if (path.startsWith('https://') || path.startsWith('http://')) {
      return Image.network(path,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const CircleAvatar(radius: 28, child: Icon(Icons.person)));
    }
    return Image.asset('assets/images/Profiles/Group 212.png',
        width: 56, height: 56, fit: BoxFit.cover);
  }

  Widget _info(String label, dynamic value) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.blue500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Text(value == null ? '—' : '$value')
      ]));
}
