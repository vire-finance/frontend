import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../data/pocket_repository.dart';
import 'owner_card_form.dart';
import 'employee_picker_dialog.dart';

class OwnerAccessScreen extends StatefulWidget {
  const OwnerAccessScreen({required this.card, super.key});

  final VireCardData card;

  @override
  State<OwnerAccessScreen> createState() => _OwnerAccessScreenState();
}

class _OwnerAccessScreenState extends State<OwnerAccessScreen> {
  final _repository = PocketRepository.instance;
  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;
  bool _adding = false;
  final Set<String> _removing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _repository.cardEmployees(widget.card.id);
      if (mounted) setState(() => _employees = rows);
    } catch (error) {
      if (mounted) _message(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF8F8FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F8FF),
          foregroundColor: const Color(0xFF18346F),
          elevation: 0,
          centerTitle: true,
          title: const Text('Card Access',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(widget.card.name,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3260CD))),
              const SizedBox(height: 5),
              Text('Card ending in ${widget.card.lastFour}',
                  style: const TextStyle(color: Color(0xFF777777))),
              const SizedBox(height: 22),
              Row(children: [
                const Expanded(
                    child: Text('Employees with access',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18346F)))),
                OutlinedButton.icon(
                  onPressed: _loading || _adding ? null : _addEmployee,
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Add Employee',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2453C5),
                      side: const BorderSide(color: Color(0xFF2453C5))),
                ),
              ]),
              const SizedBox(height: 8),
              if (_loading)
                const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()))
              else if (_employees.isEmpty)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text('No employees have access to this card yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF777777))))
              else
                ..._employees.map(_employeeRow),
            ],
          ),
        ),
      );

  Widget _employeeRow(Map<String, dynamic> employee) {
    final inherited = employee['inherited_from_pocket'] == true;
    final removing = _removing.contains('${employee['id']}');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE1E1E7)),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        EmployeeAvatar(employee: employee),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(employeeDisplayName(employee),
              style: const TextStyle(fontWeight: FontWeight.w500)),
          if (inherited)
            const Text('Access inherited from pocket',
                style: TextStyle(fontSize: 11, color: Color(0xFF777777))),
        ])),
        TextButton(
            onPressed: removing
                ? null
                : () => inherited
                    ? _message(
                        'This access comes from the pocket. Remove pocket access to revoke it.')
                    : _removeEmployee(employee),
            style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD93939),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text(removing ? 'Removing…' : 'Remove',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Future<void> _addEmployee() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      final candidates = _repository.employees();
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => EmployeePickerDialog(
            employees: candidates,
            excludedIds:
                _employees.map((employee) => '${employee['id']}').toSet()),
      );
      if (selected == null || !mounted) return;
      await _repository.setCardEmployeeAccess(
          widget.card.id, '${selected['id']}',
          enabled: true);
      if (mounted) await _load();
    } catch (error) {
      if (mounted) _message(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _removeEmployee(Map<String, dynamic> employee) async {
    final id = '${employee['id']}';
    if (_removing.contains(id)) return;
    setState(() => _removing.add(id));
    try {
      await _repository.setCardEmployeeAccess(widget.card.id, id,
          enabled: false);
      if (mounted) await _load();
    } catch (error) {
      if (mounted) _message(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _removing.remove(id));
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
