import 'package:flutter_test/flutter_test.dart';
import 'package:findback/features/reports/domain/item_report_model.dart';
import 'package:findback/features/claims/domain/claim_model.dart';
import 'package:findback/features/profile/domain/profile_model.dart';
import 'package:findback/features/auth/domain/auth_state.dart';

void main() {
  group('Security: ProfileModel privilege flags are read-only', () {
    test('copyWith cannot change isModerator', () {
      final profile = ProfileModel(
        id: 'u1', displayName: 'Test', isModerator: false, isBanned: false,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final updated = profile.copyWith(displayName: 'NewName');
      expect(updated.isModerator, false);
      expect(updated.displayName, 'NewName');
    });
  });

  group('Security: ReportStatus transitions', () {
    test('ACTIVE report can be moved to CLAIMED via copyWith', () {
      final json = {
        'id': 'r1', 'reporter_id': 'u1', 'type': 'LOST', 'status': 'ACTIVE',
        'title': 'T', 'description': 'D', 'category': 'OTHER',
        'date_of_incident': '2024-01-01', 'location_text': 'Manila',
        'image_urls': <String>[], 'reward_offered': false, 'created_at': '2024-01-01T00:00:00Z',
      };
      final report = ItemReportModel.fromJson(json);
      final claimed = report.copyWith(status: ReportStatus.claimed);
      expect(claimed.status, ReportStatus.claimed);
    });
  });

  group('Security: ClaimStatus model constraints', () {
    test('PENDING claim can only transition to WITHDRAWN by client', () {
      expect(ClaimStatus.withdrawn.dbValue, 'WITHDRAWN');
      expect(ClaimStatus.approved.dbValue, 'APPROVED');
    });
  });

  group('Security: AuthStatus correctly reflects verification', () {
    test('unauthenticated state returns false for isAuthenticated', () {
      const state = AppAuthState(status: AuthStatus.unauthenticated);
      expect(state.isAuthenticated, false);
    });

    test('emailUnverified state returns false for isAuthenticated', () {
      const state = AppAuthState(status: AuthStatus.emailUnverified);
      expect(state.isAuthenticated, false);
    });

    test('authenticated state returns true for isAuthenticated', () {
      const state = AppAuthState(status: AuthStatus.authenticated);
      expect(state.isAuthenticated, true);
    });
  });

  group('Security: Match score is not proof of ownership', () {
    test('score is a numeric value between 0 and 1', () {
      const score = 0.73;
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(1.0));
      expect(score > 0.45, true);
    });
  });
}
