import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../history/presentation/history_screen.dart';
import '../../data/pocket_repository.dart';
import 'owner_access_screen.dart';
import 'employee_picker_dialog.dart';
import 'owner_card_form.dart';
import 'owner_card_settings_screen.dart';

class OwnerCardDetailScreen extends StatefulWidget {
  const OwnerCardDetailScreen({required this.card, super.key});

  final VireCardData card;

  @override
  State<OwnerCardDetailScreen> createState() => _OwnerCardDetailScreenState();
}

class _OwnerCardDetailScreenState extends State<OwnerCardDetailScreen> {
  bool _showCardNumber = false;
  bool _showCvv = false;
  List<Map<String, dynamic>> _employees = [];
  bool _addingEmployee = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final values = await Future.wait([
        PocketRepository.instance.loadCardDetail(widget.card.id),
        PocketRepository.instance.cardEmployees(widget.card.id),
      ]);
      if (mounted)
        setState(() => _employees = values[1] as List<Map<String, dynamic>>);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = PocketRepository.instance;

    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final card = repository.cards.firstWhere(
          (item) => item.id == widget.card.id,
          orElse: () => widget.card,
        );
        final theme = vireCardThemes[card.themeIndex % vireCardThemes.length];
        final used = card.limit <= 0
            ? 0.0
            : (card.balance / card.limit).clamp(0.0, 1.0).toDouble();

        return Scaffold(
          backgroundColor: const Color(0xFFF8F8FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F8FF),
            foregroundColor: const Color(0xFF18346F),
            elevation: 0,
            centerTitle: true,
            title: const Text('Card Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _VirtualCardVisual(card: card, colors: theme),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: card.locked
                          ? Icons.lock_open_outlined
                          : Icons.lock_outline,
                      label: card.blocked
                          ? 'Blocked'
                          : card.singleUseConsumed
                              ? 'Used'
                              : card.locked
                                  ? 'Unlock Card'
                                  : 'Lock Card',
                      onTap: () => card.blocked || card.singleUseConsumed
                          ? _showSettings(context)
                          : _toggleLock(card),
                    ),
                    _ActionButton(
                      icon: Icons.history,
                      label: 'History',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => HistoryScreen(cardId: card.id))),
                    ),
                    _ActionButton(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => _showSettings(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _InfoPanel(
                  title: 'Card Information',
                  trailing: OutlinedButton(
                    onPressed: () =>
                        setState(() => _showCardNumber = !_showCardNumber),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2453C5),
                      side: const BorderSide(color: Color(0xFF2453C5)),
                      minimumSize: const Size(76, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(_showCardNumber ? 'Hide Info' : 'Show Info',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  children: [
                    _InfoRow(
                      icon: Icons.pin_outlined,
                      label: 'Card no.',
                      value: _showCardNumber
                          ? (card.simulatedCardNumber ??
                              card.maskedNumber ??
                              card.lastFour)
                          : (card.maskedNumber ??
                              '•••• •••• •••• ${card.lastFour}'),
                    ),
                    _InfoRow(
                        icon: Icons.event_outlined,
                        label: 'Expiry Date',
                        value: _expiry(card)),
                    _InfoRow(
                        icon: Icons.credit_card_outlined,
                        label: 'Card type',
                        value: card.usageLabel),
                    _InfoRow(
                        icon: Icons.info_outline,
                        label: 'Status',
                        value: card.blocked
                            ? 'Blocked'
                            : card.singleUseConsumed
                                ? 'Single use completed'
                                : !card.canPay && !card.locked
                                    ? 'Expired'
                                    : card.locked
                                        ? 'Locked'
                                        : 'Active'),
                    _InfoRow(
                      icon: Icons.credit_card_outlined,
                      label: 'CVV (3 Digit Security Code)',
                      value: _showCvv ? (card.cvv ?? '—') : '•••',
                      onTap: () => setState(() => _showCvv = !_showCvv),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly limit',
                            style: TextStyle(
                                color: Color(0xFF52617F), fontSize: 12)),
                        Text(formatIdr(card.limit),
                            style: const TextStyle(
                                color: Color(0xFF18346F),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: used,
                        minHeight: 14,
                        backgroundColor: const Color(0xFFEAEAEA),
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF39BF4A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _InfoPanel(
                  title: 'Employees',
                  trailing: OutlinedButton.icon(
                    onPressed: _addingEmployee ? null : _addEmployee,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Employee',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2453C5),
                      side: const BorderSide(color: Color(0xFF2453C5)),
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                  children: _employees.isEmpty
                      ? const [
                          Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Text(
                                  'No employees are assigned to this card yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF777777))))
                        ]
                      : [
                          Align(
                              alignment: Alignment.centerLeft,
                              child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (final employee in _employees)
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8, top: 10, bottom: 4),
                                              child: Tooltip(
                                                  message:
                                                      'Manage employee access',
                                                  child: InkWell(
                                                      onTap: () =>
                                                          _showEmployees(
                                                              context),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: SizedBox(
                                                          width: 82,
                                                          child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                EmployeeAvatar(
                                                                    employee:
                                                                        employee,
                                                                    radius: 26),
                                                                const SizedBox(
                                                                    height: 7),
                                                                Text(
                                                                    employeeDisplayName(
                                                                        employee),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    maxLines: 2,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        color: Color(
                                                                            0xFF555555))),
                                                              ]))))),
                                      ])))
                        ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    final card = PocketRepository.instance.cards.firstWhere(
        (item) => item.id == widget.card.id,
        orElse: () => widget.card);
    Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => OwnerCardSettingsScreen(card: card)));
  }

  Future<void> _toggleLock(VireCardData card) async {
    try {
      await PocketRepository.instance.toggleLock(card);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
    }
  }

  static String _expiry(VireCardData card) {
    if (card.expiresOn != null) {
      final date = card.expiresOn!;
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    final month = card.expiryMonth;
    final year = card.expiryYear;
    if (month == null || year == null) return '—';
    return '${month.toString().padLeft(2, '0')}/${(year % 100).toString().padLeft(2, '0')}';
  }

  Future<void> _addEmployee() async {
    if (_addingEmployee) return;
    setState(() => _addingEmployee = true);
    try {
      final repository = PocketRepository.instance;
      final candidates = repository.employees();
      final selected = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => EmployeePickerDialog(
              employees: candidates,
              excludedIds:
                  _employees.map((employee) => '${employee['id']}').toSet()));
      if (selected == null || !mounted) return;
      await repository.setCardEmployeeAccess(
          widget.card.id, '${selected['id']}',
          enabled: true);
      if (mounted) await _loadDetail();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _addingEmployee = false);
    }
  }

  Future<void> _showEmployees(BuildContext context) async {
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => OwnerAccessScreen(card: widget.card)));
    if (mounted) await _loadDetail();
  }
}

class _VirtualCardVisual extends StatelessWidget {
  const _VirtualCardVisual({required this.card, required this.colors});

  final VireCardData card;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Container(
        height: 346,
        margin: const EdgeInsets.symmetric(horizontal: 68),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text('Balance:\n${formatIdr(card.balance)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    height: 1.35)),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700))),
                Text(card.lastFour,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 92,
          child: Column(
            children: [
              CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFFFFF1E2),
                  child: Icon(icon, color: const Color(0xFFFF8200), size: 34)),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel(
      {required this.title, required this.trailing, required this.children});

  final String title;
  final Widget trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            border: Border.all(color: const Color(0xFFD9D9E2)),
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.people_alt_outlined,
                  color: Color(0xFF3260CD), size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Color(0xFF3260CD),
                          fontWeight: FontWeight.w700))),
              trailing
            ]),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF3260CD)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
            InkWell(
                onTap: onTap,
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF777777)))),
          ],
        ),
      );
}
