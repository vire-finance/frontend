import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_search_bar.dart';

String employeeDisplayName(Map<String, dynamic> employee) =>
    '${employee['full_name'] ?? employee['name'] ?? 'Employee'}';

class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({required this.employee, this.radius = 24, super.key});
  final Map<String, dynamic> employee;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final url = employee['avatar_url'] as String?;
    Widget fallback() => Image.asset('assets/images/Profiles/Group 212.png',
        width: radius * 2, height: radius * 2, fit: BoxFit.cover);
    return ClipOval(
        child: url == null || url.isEmpty
            ? fallback()
            : Image.network(url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => fallback()));
  }
}

class EmployeePickerDialog extends StatefulWidget {
  const EmployeePickerDialog(
      {required this.employees, required this.excludedIds, super.key});
  final Future<List<Map<String, dynamic>>> employees;
  final Set<String> excludedIds;
  @override
  State<EmployeePickerDialog> createState() => _EmployeePickerDialogState();
}

class _EmployeePickerDialogState extends State<EmployeePickerDialog> {
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppColors.basicWhite,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
        title: Row(children: [
          const Expanded(
              child: Text('Add Employee',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue900))),
          IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 20))
        ]),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        content: SizedBox(
            width: 360,
            height: math.min(420, MediaQuery.sizeOf(context).height * 0.5),
            child: Column(children: [
              AppSearchBar(
                  controller: _search,
                  hint: 'Search employees...',
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase())),
              const SizedBox(height: 12),
              Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: widget.employees,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text(apiErrorMessage(snapshot.error!),
                                  textAlign: TextAlign.center));
                        }
                        final candidates = (snapshot.data ?? [])
                            .where((employee) =>
                                !widget.excludedIds
                                    .contains('${employee['id']}') &&
                                '${employeeDisplayName(employee)} ${employee['name'] ?? ''}'
                                    .toLowerCase()
                                    .contains(_query))
                            .toList();
                        if (candidates.isEmpty) {
                          return Center(
                              child: Text(
                                  _query.isEmpty
                                      ? 'No additional employees are available.'
                                      : 'No matching employees.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.grey500)));
                        }
                        return ListView.separated(
                            itemCount: candidates.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final employee = candidates[index];
                              return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  leading: EmployeeAvatar(employee: employee),
                                  title: Text(employeeDisplayName(employee),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: const Text('Employee'),
                                  trailing: const Icon(Icons.add_circle_outline,
                                      color: AppColors.blue500),
                                  onTap: () =>
                                      Navigator.pop(context, employee));
                            });
                      })),
            ])),
      );
}
