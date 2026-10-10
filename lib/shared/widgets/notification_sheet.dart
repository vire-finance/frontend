import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../features/document/presentation/purchase_requests_screen.dart';

String notificationDateGroup(DateTime? date, DateTime now) {
  if (date == null) return 'Earlier';
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Today';
  if (day == DateTime(now.year, now.month, now.day - 1)) return 'Yesterday';
  final thisWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
  final lastWeek = DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7);
  if (!day.isBefore(thisWeek)) return 'This Week';
  if (!day.isBefore(lastWeek)) return 'Last Week';
  if (day.year == now.year && day.month == now.month) return 'This Month';
  final previousMonth = DateTime(now.year, now.month - 1);
  if (day.year == previousMonth.year && day.month == previousMonth.month) {
    return 'Last Month';
  }
  return 'Earlier';
}

Future<void> showNotificationSheet(BuildContext context,
    {required bool owner}) async {
  try {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'limit': 200});
    if (!context.mounted) return;
    final rows = (response.data?['items'] as List? ?? [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NotificationSheet(rows: rows),
    );
    if (selected == null || !context.mounted) return;
    await ApiClient.instance.dio.patch('/notifications/${selected['id']}/read');
    final id = selected['request_id'];
    if (id != null && context.mounted) {
      await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) =>
                  PurchaseRequestDetailScreen(id: '$id', owner: owner)));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
    }
  }
}

class NotificationSheet extends StatelessWidget {
  const NotificationSheet({required this.rows, this.now, super.key});
  final List<Map<String, dynamic>> rows;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final current = now ?? DateTime.now();
    DateTime? date(Map<String, dynamic> row) =>
        DateTime.tryParse('${row['created_at']}')?.toLocal();
    final sorted = [...rows]..sort((a, b) =>
        (date(b) ?? DateTime(1970)).compareTo(date(a) ?? DateTime(1970)));
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in sorted) {
      groups
          .putIfAbsent(notificationDateGroup(date(row), current), () => [])
          .add(row);
    }
    return SafeArea(
        child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .65,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Notifications',
                      style: TextStyle(
                          color: AppColors.blue900,
                          fontWeight: FontWeight.w700,
                          fontSize: 18))),
              if (rows.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(22),
                    child: Text('No notifications yet.',
                        textAlign: TextAlign.center)),
              for (final group in [
                'Today',
                'Yesterday',
                'This Week',
                'Last Week',
                'This Month',
                'Last Month',
                'Earlier'
              ])
                if (groups.containsKey(group)) ...[
                  Padding(
                      padding: const EdgeInsets.fromLTRB(8, 18, 8, 6),
                      child: Text(group,
                          style: const TextStyle(
                              color: AppColors.blue600,
                              fontWeight: FontWeight.w700,
                              fontSize: 15))),
                  for (final row in groups[group]!)
                    ListTile(
                      leading: Icon(
                          row['is_read'] == true
                              ? Icons.notifications_none
                              : Icons.notifications_active_outlined,
                          color: AppColors.blue500),
                      title: Text('${row['title'] ?? ''}'),
                      subtitle: Text('${row['message'] ?? ''}'),
                      onTap: () => Navigator.pop(context, row),
                    ),
                ],
            ])));
  }
}
