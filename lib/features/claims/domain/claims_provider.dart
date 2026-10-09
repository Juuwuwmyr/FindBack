import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/claims_repository.dart';
import '../domain/claim_model.dart';
import '../../auth/domain/auth_provider.dart';

// All claims for a report (reporter view)
final claimsForReportProvider =
    FutureProvider.family<List<ClaimModel>, String>((ref, reportId) {
  return ref.watch(claimsRepositoryProvider).fetchClaimsForReport(reportId);
});

// Single claim by id
final claimDetailProvider =
    FutureProvider.family<ClaimModel, String>((ref, claimId) {
  return ref.watch(claimsRepositoryProvider).fetchClaim(claimId);
});

// Current user's own claim on a report
final myClaimForReportProvider =
    FutureProvider.family<ClaimModel?, String>((ref, reportId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(claimsRepositoryProvider).fetchMyClaim(reportId, userId);
});
