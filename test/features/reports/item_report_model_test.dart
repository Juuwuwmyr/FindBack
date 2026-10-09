import 'package:flutter_test/flutter_test.dart';
import 'package:findback/features/reports/domain/item_report_model.dart';

void main() {
  group('ReportTypeExt', () {
    test('dbValue returns uppercase', () {
      expect(ReportType.lost.dbValue, 'LOST');
      expect(ReportType.found.dbValue, 'FOUND');
    });
    test('fromDb parses correctly', () {
      expect(ReportTypeExt.fromDb('LOST'), ReportType.lost);
      expect(ReportTypeExt.fromDb('FOUND'), ReportType.found);
    });
  });

  group('ItemCategoryExt', () {
    test('all categories round-trip through dbValue', () {
      for (final cat in ItemCategory.values) {
        expect(ItemCategoryExt.fromDb(cat.dbValue), cat);
      }
    });
  });

  group('ItemReportModel.fromJson', () {
    test('parses all required fields', () {
      final json = {
        'id': 'abc123',
        'reporter_id': 'user1',
        'type': 'LOST',
        'status': 'ACTIVE',
        'title': 'Lost phone',
        'description': 'Black iPhone',
        'category': 'ELECTRONICS',
        'date_of_incident': '2024-01-15',
        'location_text': 'Makati City',
        'image_urls': <String>[],
        'reward_offered': false,
        'created_at': '2024-01-15T10:00:00Z',
      };
      final model = ItemReportModel.fromJson(json);
      expect(model.id, 'abc123');
      expect(model.type, ReportType.lost);
      expect(model.status, ReportStatus.active);
      expect(model.category, ItemCategory.electronics);
      expect(model.imageUrls, isEmpty);
      expect(model.rewardOffered, false);
    });

    test('copyWith preserves unchanged fields', () {
      final json = {
        'id': 'abc123', 'reporter_id': 'user1', 'type': 'LOST', 'status': 'ACTIVE',
        'title': 'Lost phone', 'description': 'Black iPhone', 'category': 'ELECTRONICS',
        'date_of_incident': '2024-01-15', 'location_text': 'Makati City',
        'image_urls': <String>[], 'reward_offered': false, 'created_at': '2024-01-15T10:00:00Z',
      };
      final original = ItemReportModel.fromJson(json);
      final copy = original.copyWith(title: 'Updated title');
      expect(copy.title, 'Updated title');
      expect(copy.id, original.id);
      expect(copy.type, original.type);
    });
  });
}
