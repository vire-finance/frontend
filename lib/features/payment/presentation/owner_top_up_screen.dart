import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'transaction_complete_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../dashboard/presentation/owner_dashboard_screen.dart';
import '../../pin/presentation/pin_screen.dart';
import '../../pocket/data/pocket_repository.dart';
import '../../funding/data/funding_repository.dart';
import '../../funding/presentation/fund_account_screen.dart';

class OwnerTopUpScreen extends StatefulWidget {
  const OwnerTopUpScreen({required this.method, super.key});
  final String method;

  @override
  State<OwnerTopUpScreen> createState() => _OwnerTopUpScreenState();
}

class _OwnerTopUpScreenState extends State<OwnerTopUpScreen> {
  final _amount = TextEditingController();
  Map<String, dynamic>? _fundAccount;
  final _idempotencyKey = ApiClient.newIdempotencyKey();
  String? _paymentId;
  List<int>? _qrSvg;
  Map<String, dynamic>? _bankDetails;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    try {
      final account = await FundingRepository.instance.account();
      if (mounted) setState(() => _fundAccount = account);
    } catch (error) {
      if (mounted) _message(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: PocketRepository.instance,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: AppColors.basicWhite,
            appBar: AppBar(
                title: Text(widget.method == 'QR_CODE'
                    ? 'Show QR Code'
                    : 'Bank Transfer'),
                centerTitle: true,
                backgroundColor: AppColors.basicWhite,
                foregroundColor: AppColors.blue900,
                elevation: 0),
            body: SafeArea(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(children: [
                          Expanded(
                              child: ListView(
                                  padding: const EdgeInsets.all(20),
                                  children: [
                                const Text('Add funds to your main account',
                                    style: TextStyle(
                                        color: AppColors.blue500,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17)),
                                const SizedBox(height: 18),
                                if (_fundAccount != null)
                                  Text(
                                      '${_fundAccount!['provider_name']} • ${_fundAccount!['account_number']}',
                                      style: const TextStyle(
                                          color: AppColors.blue900,
                                          fontWeight: FontWeight.w600))
                                else if (!_loading) ...[
                                  const Text(
                                      'Set up your Main Fund Account before adding funds.'),
                                  TextButton(
                                      onPressed: () async {
                                        await Navigator.push<void>(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const FundAccountScreen()));
                                        if (mounted) await _loadAccount();
                                      },
                                      child: const Text('Set Up Account')),
                                ],
                                const SizedBox(height: 18),
                                const Text('Amount (IDR)',
                                    style: TextStyle(color: AppColors.blue500)),
                                const SizedBox(height: 7),
                                AppInputField(
                                    controller: _amount,
                                    enabled: _paymentId == null,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      const IdrInputFormatter()
                                    ],
                                    decoration: _input('Enter amount')),
                                if (_paymentId != null) ...[
                                  const SizedBox(height: 24),
                                  if (widget.method == 'QR_CODE' &&
                                      _qrSvg != null)
                                    Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: AppColors.grey50),
                                            borderRadius:
                                                BorderRadius.circular(18)),
                                        child: SvgPicture.memory(
                                            Uint8List.fromList(_qrSvg!),
                                            height: 240,
                                            fit: BoxFit.contain))
                                  else if (_bankDetails != null)
                                    _BankDetails(details: _bankDetails!),
                                  const SizedBox(height: 12),
                                  const Text(
                                      'This backend currently simulates funding. No real bank transfer or QR payment is sent.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppColors.orange600,
                                          fontSize: 12)),
                                ],
                              ])),
                          Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                              child: SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: FilledButton(
                                      onPressed: _loading ||
                                              _submitting ||
                                              _fundAccount == null
                                          ? null
                                          : _paymentId == null
                                              ? _create
                                              : _confirm,
                                      child: Text(_submitting
                                          ? 'Please waitâ€¦'
                                          : _paymentId == null
                                              ? 'Continue'
                                              : 'Confirm with PIN')))),
                        ])))),
          );
        },
      );

  Future<void> _create() async {
    final amount = parseIdrInput(_amount.text);
    if (_fundAccount == null || amount == null || amount <= 0) {
      _message(
          'Set up your main account and enter an amount greater than zero.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
          '/payments',
          data: {'amount': amount, 'method': widget.method},
          options: Options(headers: {'Idempotency-Key': _idempotencyKey}));
      final data = response.data!;
      final id = '${data['id']}';
      List<int>? qr;
      final bank = data['bank_details'] is Map
          ? Map<String, dynamic>.from(data['bank_details'] as Map)
          : null;
      if (widget.method == 'QR_CODE') {
        final qrResponse = await ApiClient.instance.dio.get<List<int>>(
            '/payments/$id/qr',
            options: Options(responseType: ResponseType.bytes));
        qr = qrResponse.data;
      }
      if (!mounted) return;
      setState(() {
        _paymentId = id;
        _qrSvg = qr;
        _bankDetails = bank;
      });
    } catch (error) {
      if (mounted) _message(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirm() async {
    final paymentId = _paymentId;
    if (paymentId == null) return;
    final amount = parseIdrInput(_amount.text) ?? 0;
    final accountName =
        '${_fundAccount?['provider_name'] ?? 'Main Fund Account'}';
    Map<String, dynamic>? confirmedPayment;
    setState(() => _submitting = true);
    try {
      final navigator = Navigator.of(context);
      await navigator.push<void>(MaterialPageRoute<void>(
          builder: (_) => PinScreen(
                title: 'Enter Your Pin',
                showSuccessModal: false,
                onPinSubmitted: (pin) async {
                  try {
                    final token = await AuthRepository.instance
                        .verifyPin(pin, actionType: 'PAYMENT');
                    final response =
                        await ApiClient.instance.dio.post<Map<String, dynamic>>(
                      '/payments/$paymentId/confirm',
                      data: const {'confirmed': true},
                      options: Options(headers: {'X-Action-Token': token}),
                    );
                    confirmedPayment = response.data;
                    await PocketRepository.instance.load();
                  } catch (error) {
                    throw Exception(apiErrorMessage(error));
                  }
                },
                onPinComplete: () {
                  final result = confirmedPayment;
                  if (result == null) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                        builder: (_) => TransactionCompleteScreen.topUp(
                              sourceAccount: accountName,
                              transactionId: '${result['id'] ?? paymentId}',
                              completedAt:
                                  DateTime.tryParse('${result['completed_at']}')
                                      ?.toLocal(),
                              amount: amount,
                              onBack: () => navigator.pushAndRemoveUntil(
                                MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const OwnerDashboardScreen()),
                                (route) => false,
                              ),
                            )),
                    (route) => false,
                  );
                },
              )));
    } catch (error) {
      if (mounted) _message(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  static InputDecoration _input(String hint) =>
      AppInputDecoration(hintText: hint);
}

class _BankDetails extends StatelessWidget {
  const _BankDetails({required this.details});
  final Map<String, dynamic> details;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.grey50),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final entry in details.entries)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${entry.key.replaceAll('_', ' ')}: ${entry.value}',
                  style: const TextStyle(color: AppColors.blue900)))
      ]));
}
