import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/features/dashboard/data/dashboard_model.dart';
import 'package:vire/features/dashboard/presentation/widgets/pending_requests_section.dart';
import 'package:vire/shared/widgets/notification_sheet.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);
  test('notification groups handle days, calendar weeks and month boundaries', () {
    expect(notificationDateGroup(DateTime(2026, 10, 14), now), 'Today');
    expect(notificationDateGroup(DateTime(2026, 10, 13), now), 'Yesterday');
    expect(notificationDateGroup(DateTime(2026, 10, 12), now), 'This Week');
    expect(notificationDateGroup(DateTime(2026, 10, 8), now), 'Last Week');
    expect(notificationDateGroup(DateTime(2026, 10, 1), now), 'This Month');
    expect(notificationDateGroup(DateTime(2026, 9, 15), now), 'Last Month');
    expect(notificationDateGroup(DateTime(2026, 8, 15), now), 'Earlier');
    expect(notificationDateGroup(null, now), 'Earlier');
    expect(notificationDateGroup(DateTime(2025, 12, 15), DateTime(2026, 1, 15)), 'Last Month');
  });

  testWidgets('notification sheet displays chronological headings and returns selected item', (tester) async {
    tester.view.physicalSize = const Size(480, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rows = [
      for (final day in [DateTime(2026, 9, 15), DateTime(2026, 10, 8), DateTime(2026, 10, 13), now])
        {'id': '${day.day}', 'created_at': day.toIso8601String(), 'title': 'Request ${day.day}', 'message': 'Details'}
    ];
    Map<String, dynamic>? selected;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () async {
        selected = await showModalBottomSheet<Map<String, dynamic>>(context: context,
          isScrollControlled: true, builder: (_) => NotificationSheet(rows: rows, now: now));
      }, child: const Text('Inbox'))))));
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    for (final label in ['Today', 'Yesterday', 'Last Week', 'Last Month']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.getTopLeft(find.text('Today')).dy, lessThan(tester.getTopLeft(find.text('Yesterday')).dy));
    await tester.tap(find.text('Request 14'));
    await tester.pumpAndSettle();
    expect(selected?['id'], '14');
  });

  testWidgets('pending requests paginate, sort, search, filter and open the selected request', (tester) async {
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requests = [for (var i = 1; i <= 3; i++) PaymentRequest(
      id: '$i', reference: 'PO-000$i', createdAt: '2026-10-0$i',
      description: i == 1 ? 'Taxi' : 'Stock', category: i == 1 ? 'Operational' : 'Production',
      amount: 100000 * i, status: 'Waiting')];
    String? opened;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PendingRequestsSection(
      requests: requests, onRequestTap: (r) => opened = r.id))));
    expect(find.text('Pending Payment Requests (3)'), findsOneWidget);
    expect(find.text('PO-0003'), findsOneWidget);
    expect(find.text('PO-0001'), findsNothing);
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('PO-0001'), findsOneWidget);
    await tester.tap(find.text('PO-0001'));
    expect(opened, '1');
    await tester.enterText(find.byType(TextField), 'Stock');
    await tester.pumpAndSettle();
    expect(find.text('PO-0001'), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.byTooltip('Filter requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Operational'));
    await tester.pumpAndSettle();
    expect(find.text('PO-0001'), findsOneWidget);
    expect(find.text('PO-0002'), findsNothing);
    await tester.tap(find.byTooltip('Filter requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sort requests'));
    await tester.pumpAndSettle();
    expect(find.text('PO-0001'), findsOneWidget);
    expect(find.text('PO-0003'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
