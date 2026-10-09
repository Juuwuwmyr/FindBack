import 'package:flutter_test/flutter_test.dart';
import 'package:findback/features/notifications/domain/notification_model.dart';

void main() {
  group('NotificationTypeExt', () {
    test('all types round-trip through dbValue', () {
      for (final t in NotificationType.values) {
        expect(NotificationTypeExt.fromDb(t.dbValue), t);
      }
    });
  });

  group('NotificationModel.fromJson', () {
    test('parses correctly', () {
      final json = {
        'id': 'n1',
        'user_id': 'u1',
        'type': 'NEW_CLAIM',
        'title': 'New claim on your report',
        'body': 'Someone submitted a claim',
        'payload': {'report_id': 'r1'},
        'is_read': false,
        'created_at': '2024-01-15T10:00:00Z',
      };
      final model = NotificationModel.fromJson(json);
      expect(model.type, NotificationType.newClaim);
      expect(model.isRead, false);
      expect(model.payload['report_id'], 'r1');
    });
  });
}
