import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/matches_repository.dart';

final matchesForReportProvider =
    FutureProvider.family<List<MatchWithReport>, String>((ref, reportId) {
  return ref.watch(matchesRepositoryProvider).fetchMatchesForReport(reportId);
});
