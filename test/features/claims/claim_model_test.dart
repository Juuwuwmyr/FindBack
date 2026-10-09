import 'package:flutter_test/flutter_test.dart';
import 'package:findback/features/claims/domain/claim_model.dart';

void main() {
  group('ClaimStatusExt', () {
    test('all statuses have labels', () {
      for (final s in ClaimStatus.values) {
        expect(s.label, isNotEmpty);
        expect(ClaimStatusExt.fromDb(s.dbValue), s);
      }
    });
  });

  group('ContactPreferenceExt', () {
    test('round-trips through dbValue', () {
      for (final p in ContactPreference.values) {
        expect(ContactPreferenceExt.fromDb(p.dbValue), p);
      }
    });
  });

  group('ClaimModel.fromJson', () {
    test('parses required fields correctly', () {
      final json = {
        'id': 'claim1',
        'report_id': 'report1',
        'claimant_id': 'user1',
        'status': 'PENDING',
        'description': 'This is my item',
        'evidence_image_paths': <String>[],
        'contact_preference': 'IN_APP',
        'created_at': '2024-01-15T10:00:00Z',
      };
      final model = ClaimModel.fromJson(json);
      expect(model.id, 'claim1');
      expect(model.status, ClaimStatus.pending);
      expect(model.contactPreference, ContactPreference.inApp);
      expect(model.evidenceImagePaths, isEmpty);
    });
  });
}
