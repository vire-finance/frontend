import 'package:flutter_test/flutter_test.dart';
import 'package:vire/core/services/push_notification_service.dart';

void main() {
  test('rejection banners are visible only to employees', () {
    for (final title in ['Your Request Was Rejected', 'Request ditolak']) {
      expect(shouldDisplayRequestNotification(title, 'EMPLOYEE'), isTrue);
      for (final role in ['OWNER', 'BUSINESS_OWNER', null]) {
        expect(shouldDisplayRequestNotification(title, role), isFalse);
      }
    }
  });

  test('owners still receive incoming request notifications', () {
    expect(shouldDisplayRequestNotification('Request Payment from Rida', 'OWNER'),
        isTrue);
  });
}
