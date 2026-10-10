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
import '../../auth/data/auth_repository.dart';
import '../../pin/presentation/pin_screen.dart';
import '../../pocket/data/employee_pocket_repository.dart';
import '../../pocket/data/pocket_repository.dart';
import '../../pocket/presentation/owner/owner_card_form.dart';
import '../../history/presentation/history_screen.dart';
import '../../payment/presentation/qr_scanner_screen.dart';

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
  const PurchaseRequestFormScreen({super.key});
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
  String? _category, _invoiceId, _invoiceName, _draftId;
  DateTime? _neededBy;
  bool _busy = false, _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      await EmployeePocketRepository.instance.load();
      if (mounted)
        setState(
            () => _cards = EmployeePocketRepository.instance.accessibleCards);
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
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
      if (doc != null && mounted)
        setState(() {
          _invoiceId = doc.$1;
          _invoiceName = doc.$2;
        });
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
      await api.post('/fund-requests/$_draftId/submit',
          data: {'allow_failed_ocr': true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Purchase Request sent to your owner.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _executor == 'OWNER_PAYMENT'
        ? expenseCategories
        : _card?.allowedCategories ?? <String>[];
    return Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(title: const Text('New Request')),
        body: Form(
            key: _form,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              if (_loading) const LinearProgressIndicator(),
              const Text(
                  'Submit an invoice for the owner to review and pay. For direct purchases, use Payment.',
                  style: TextStyle(color: AppColors.grey600, fontSize: 12)),
              const SizedBox(height: 18),
              AppDropdownField<VireCardData>(
                  value: _card,
                  decoration: const AppInputDecoration(labelText: 'Card'),
                  validator: (v) => v == null ? 'Choose a card' : null,
                  items: [
                    for (final c in _cards)
                      DropdownMenuItem(
                          value: c,
                          child: Text('${c.name} · ${c.lastFour}',
                              overflow: TextOverflow.ellipsis))
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                            _card = v;
                            _category = null;
                          })),
              const SizedBox(height: 18),
              AppFormField(
                  controller: _purpose,
                  maxLines: 3,
                  maxLength: 5000,
                  decoration:
                      const AppInputDecoration(labelText: 'Purchase Purpose'),
                  validator: _required),
              const SizedBox(height: 18),
              AppDropdownField<String>(
                  key: ValueKey('${_card?.id}$_executor'),
                  value: _category,
                  decoration:
                      const AppInputDecoration(labelText: 'Expense Category'),
                  validator: (v) => v == null ? 'Choose a category' : null,
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c, child: Text(c))
                  ],
                  onChanged: _card == null || _busy
                      ? null
                      : (v) => setState(() => _category = v)),
              const SizedBox(height: 18),
              AppFormField(
                  controller: _party,
                  decoration: const AppInputDecoration(
                      labelText: 'Merchant / Recipient Name'),
                  validator: _required),
              const SizedBox(height: 18),
              AppFormField(
                  controller: _amountInput,
                  keyboardType: TextInputType.number,
                  inputFormatters: [const IdrInputFormatter()],
                  decoration:
                      const AppInputDecoration(labelText: 'Total Amount (IDR)'),
                  validator: (v) {
                    final n = parseIdrInput(v ?? '');
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    if (_executor == 'EMPLOYEE_PAYMENT' &&
                        n > (_card?.balance ?? 0))
                      return 'Above card budget. Choose Owner Payment Request.';
                    return null;
                  }),
              const SizedBox(height: 18),
              AppDropdownField<String>(
                  value: _method,
                  decoration:
                      const AppInputDecoration(labelText: 'Payment Method'),
                  items: const [
                    DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                    DropdownMenuItem(
                        value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                    DropdownMenuItem(
                        value: 'E_WALLET', child: Text('E-Wallet Transfer'))
                  ],
                  onChanged:
                      _busy ? null : (v) => setState(() => _method = v!)),
              const SizedBox(height: 18),
              AppFormField(
                  controller: _account,
                  decoration: AppInputDecoration(
                      labelText: _method == 'QRIS'
                          ? 'Merchant QR / Payment Reference'
                          : 'Bank / E-Wallet and Destination Number'),
                  validator: _executor == 'OWNER_PAYMENT' || _method != 'QRIS'
                      ? _required
                      : null),
              const SizedBox(height: 18),
              TextFormField(
                  readOnly: true,
                  decoration: AppInputDecoration(
                      labelText: null,
                      hintText: _neededBy == null
                          ? 'When do you need it by?'
                          : '${_neededBy!.day}/${_neededBy!.month}/${_neededBy!.year}',
                      suffixIcon: const Icon(Icons.calendar_today_outlined)),
                  onTap: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)));
                    if (date != null && mounted)
                      setState(() => _neededBy = DateTime(
                          date.year, date.month, date.day, 23, 59, 59));
                  }),
              const SizedBox(height: 18),
              if (_executor == 'OWNER_PAYMENT')
                OutlinedButton.icon(
                    onPressed: _busy ? null : _invoice,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_invoiceName ?? 'Attach Invoice (Required)')),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.red500))),
              const SizedBox(height: 18),
              FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(
                      _busy ? 'Submitting...' : 'Submit Purchase Request')),
            ])));
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
  final _paymentKey = ApiClient.newIdempotencyKey(),
      _approvalKey = ApiClient.newIdempotencyKey();
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
    final reason = await _reason('Reject Purchase Request');
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

  Future<void> _pay() async {
    final r = _row!;
    if (r['payment_method'] == 'QRIS') {
      final code = await Navigator.push<String>(
          context,
          MaterialPageRoute(
              builder: (_) => QrScannerScreen(
                  onCodeScanned: (value) => Navigator.of(context).pop(value))));
      if (code == null || !mounted) return;
      final expected = r['recipient_account'] as String?;
      if (expected != null && expected.isNotEmpty && code != expected) {
        setState(
            () => _error = 'QR differs from the approved merchant reference.');
        return;
      }
    }
    if (!mounted) return;
    await _pin('PAYMENT', (token) async {
      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
          '/transactions',
          data: {
            'request_id': widget.id,
            'card_id': r['card_id'],
            'description': '${r['explanation']}'
                .substring(0, '${r['explanation']}'.length.clamp(0, 255)),
            'category': r['category'],
            'amount': _amount(r['total_amount']),
            'payment_method': r['payment_method'],
            'recipient_account': r['recipient_account']
          },
          options: Options(headers: {
            'X-Action-Token': token,
            'Idempotency-Key': _paymentKey
          }));
      if (response.data?['status'] != 'APPROVED')
        throw StateError(
            '${response.data?['failure_reason'] ?? 'Payment failed'}');
    });
    if (mounted && _row?['paid_at'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Payment successful. Upload your receipt in History.')));
    }
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
            title: Text(widget.receiptOnly
                ? (r?['payment_executor'] == 'OWNER_PAYMENT'
                    ? 'Invoice & Payment'
                    : 'Purchase Receipt')
                : 'Purchase Request')),
        body: r == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Text(_error!))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Text('${r['party_name']}',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue700)),
                  const SizedBox(height: 8),
                  Text(purchaseStatus(r),
                      style: TextStyle(
                          color: r['workflow_status'] == 'RECEIPT_OVERDUE'
                              ? AppColors.red500
                              : AppColors.blue500,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  _info(
                      'Request Type',
                      r['payment_executor'] == 'OWNER_PAYMENT'
                          ? 'Owner Payment Request'
                          : 'Employee Payment Request'),
                  _info('Requested By', r['requester']?['name']),
                  if (r['card'] != null) _info('Card', r['card']['name']),
                  _info('Purchase Purpose', r['explanation']),
                  _info('Category', r['category']),
                  _info('Amount', formatIdr(_amount(r['total_amount']))),
                  _info('Payment Method', r['payment_method']),
                  _info('Destination', r['recipient_account']),
                  for (final d in (r['documents'] as List? ?? []))
                    if ('${d['id']}' != '${r['receipt']?['id']}')
                      OutlinedButton.icon(
                          onPressed: () => _file('${d['download_url']}',
                              '${d['original_filename']}'),
                          icon: const Icon(Icons.description_outlined),
                          label: Text('Invoice: ${d['original_filename']}')),
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
                  if (widget.owner && r['status'] == 'PENDING_APPROVAL') ...[
                    FilledButton(
                        onPressed: _approve,
                        child: Text(r['payment_executor'] == 'OWNER_PAYMENT'
                            ? 'Approve & Pay Invoice'
                            : 'Approve Request')),
                    TextButton(
                        onPressed: _reject,
                        child: const Text('Reject',
                            style: TextStyle(color: AppColors.red500)))
                  ],
                  if (!widget.owner &&
                      r['workflow_status'] == 'AWAITING_PAYMENT')
                    FilledButton(
                        onPressed: _pay,
                        child: const Text('Proceed to Payment')),
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
