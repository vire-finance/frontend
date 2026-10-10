import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/data/dashboard_model.dart';
import '../data/funding_repository.dart';
import '../../setup/data/fund_sources.dart';
import 'fund_account_setup_screen.dart';
import '../../../core/network/api_client.dart';

class FundAccountScreen extends StatefulWidget {
  const FundAccountScreen({super.key});
  @override
  State<FundAccountScreen> createState() => _FundAccountScreenState();
}

class _FundAccountScreenState extends State<FundAccountScreen> {
  final _repo = FundingRepository.instance;
  Map<String, dynamic>? _account;
  bool _loading = true;
  final bool _busy = false;
  String? _error;
  bool _showInfo = false;
  Color get _cardColor => _source?.primaryColor ?? AppColors.blue500;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final account = await _repo.account();
      if (mounted) setState(() { _account = account; _error = null; });
    } catch (error) {
      if (mounted) setState(() => _error = apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => FundAccountSetupScreen(account: _account),
    ));
    if (saved == true && mounted) {
      setState(() => _showInfo = false);
      await _load();
    }
  }

  FundSource? get _source => FundSources.find('${_account?['provider_name'] ?? ''}', accountType: _account?['account_type'] as String?)
      ?? FundSources.find('${_account?['provider_name'] ?? ''}');

  String get _accountNumber => '${_account?['account_number'] ?? ''}';
  String get _lastFour => _accountNumber.length <= 4
      ? _accountNumber
      : _accountNumber.substring(_accountNumber.length - 4);

  Future<void> _copyAccountNumber() async {
    await Clipboard.setData(ClipboardData(text: _accountNumber));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account number copied.')));
  }

  Widget _mask(int count) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(count, (index) => Padding(
      padding: EdgeInsets.only(left: index == 0 ? 0 : 3),
      child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.grey400, shape: BoxShape.circle)),
    )),
  );

  Widget _infoRow(IconData icon, String label, String value, {bool copy = false, int dots = 6, String? suffix}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Icon(icon, color: AppColors.blue500, size: 22),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.grey800, fontSize: 12))),
      const SizedBox(width: 8),
      Flexible(child: Align(
        alignment: Alignment.centerRight,
        child: _showInfo
            ? Text(value, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.blue700, fontSize: 13, fontWeight: FontWeight.w600))
            : Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
                _mask(dots),
                if (suffix != null) ...[const SizedBox(width: 5), Text(suffix, style: const TextStyle(color: AppColors.grey400, fontSize: 12))],
              ]),
      )),
      SizedBox(width: 28, child: copy ? Align(
        alignment: Alignment.centerRight,
        child: InkWell(onTap: _showInfo ? _copyAccountNumber : null, child: Icon(Icons.copy_outlined, size: 20, color: _showInfo ? AppColors.blue500 : AppColors.grey300)),
      ) : null),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    if (!_loading && _error == null && _account == null) {
      return FundAccountSetupScreen(onSaved: _load);
    }
    return Scaffold(
    backgroundColor: AppColors.basicWhite,
    appBar: AppBar(
      title: const FittedBox(fit: BoxFit.scaleDown, child: Text("Main Source of Fund’s Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      centerTitle: true,
      backgroundColor: AppColors.basicWhite,
      foregroundColor: AppColors.blue900,
      elevation: 0,
    ),
    body: Stack(children: [
      Positioned.fill(child: IgnorePointer(child: Opacity(
        opacity: 0.65,
        child: Image.asset('assets/images/Regular Images/Soft Pattern Background.png', fit: BoxFit.cover),
      ))),
      Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: RefreshIndicator(onRefresh: _load, child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(17, 18, 17, 28),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.red700)),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
            if (!_loading && _error == null && _account == null) ...[
              const SizedBox(height: 40),
              const Icon(Icons.account_balance_outlined, size: 64, color: AppColors.blue500),
              const SizedBox(height: 18),
              const Text('Set up your main fund account', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.blue900)),
              const SizedBox(height: 12),
              const Text('Link your bank or e-wallet and set pocket budgets. Your main balance is charged only when a payment succeeds.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: _busy ? null : _edit, child: const Text('Set Up Account')),
            ],
            if (_account != null) ...[
              AspectRatio(
                aspectRatio: 1.6,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [_cardColor, Color.lerp(_cardColor, Colors.white, 0.48)!],
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Align(alignment: Alignment.topLeft, child: SizedBox(
                        width: 110, height: 48,
                        child: _source != null
                            ? Image.asset(_source!.logoPath, fit: BoxFit.contain, alignment: Alignment.centerLeft)
                            : Text('${_account!['provider_name']}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      ))),
                      const Text('Simulation', style: TextStyle(color: Colors.white, fontSize: 9)),
                    ]),
                    const Spacer(),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(child: Text('${_account!['account_holder']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                      const SizedBox(width: 16),
                      Text(_lastFour, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1)),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.82), border: Border.all(color: AppColors.grey100, width: 0.7), borderRadius: BorderRadius.circular(22)),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.credit_card_outlined, color: AppColors.blue500, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Card Information', style: TextStyle(color: AppColors.blue600, fontSize: 16, fontWeight: FontWeight.w700))),
                    SizedBox(height: 36, child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.blue700, side: const BorderSide(color: AppColors.blue700, width: 1.3), padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7))),
                      onPressed: () => setState(() => _showInfo = !_showInfo),
                      child: Text(_showInfo ? 'Hide Info' : 'Show Info', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    )),
                  ]),
                  const SizedBox(height: 6),
                  _infoRow(Icons.currency_exchange, 'Balance', formatDashboardAmount((_account!['balance'] as num).toInt()), dots: 8),
                  _infoRow(Icons.pin_outlined, 'Card no.', _accountNumber, copy: true, dots: 6, suffix: _lastFour),
                  _infoRow(Icons.event_outlined, 'Expiry Date', 'Not applicable', dots: 4),
                  _infoRow(Icons.credit_card_outlined, 'CVV (3 Digit Security Code)', 'Not applicable', dots: 3),
                ]),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: Tooltip(
                  message: 'Unlinking is unavailable for simulation accounts. Use Change Main Fund to update the account.',
                  child: SizedBox(height: 48, child: FilledButton(
                    style: FilledButton.styleFrom(disabledBackgroundColor: AppColors.blue400, disabledForegroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: null,
                    child: const Text('Unlink Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  )),
                )),
                const SizedBox(width: 4),
                Expanded(child: SizedBox(height: 48, child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.blue100, foregroundColor: AppColors.blue600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 8)),
                  onPressed: _busy ? null : _edit,
                  child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Change Main Fund', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                ))),
              ]),
            ],
          ],
        )),
      )),
    ]),
  );
  }
}
