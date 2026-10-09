import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../../reports/domain/item_report_model.dart';
import '../domain/item_match_model.dart';

class MatchWithReport {
  const MatchWithReport({required this.match, required this.oppositeReport});
  final ItemMatchModel match;
  final ItemReportModel oppositeReport;
}

class MatchesRepository {
  MatchesRepository(this._client);
  final SupabaseClient _client;

  /// Returns PENDING matches for a report, with the opposite report joined.
  Future<List<MatchWithReport>> fetchMatchesForReport(String reportId) async {
    try {
      // Find if reportId is a lost or found report
      final reportData = await _client
          .from(SupabaseConstants.itemReportsTable)
          .select('type')
          .eq('id', reportId)
          .single();
      final type = (reportData['type'] as String).toUpperCase();

      // Fetch pending matches where reportId appears on the appropriate side
      final String filterCol =
          type == 'LOST' ? 'lost_report_id' : 'found_report_id';
      final String oppositeCol =
          type == 'LOST' ? 'found_report_id' : 'lost_report_id';

      final matchesData = await _client
          .from(SupabaseConstants.itemMatchesTable)
          .select()
          .eq(filterCol, reportId)
          .eq('status', 'PENDING')
          .order('score', ascending: false);

      final List<MatchWithReport> result = [];
      for (final m in (matchesData as List<dynamic>)) {
        final match = ItemMatchModel.fromJson(m as Map<String, dynamic>);
        final oppositeId = m[oppositeCol] as String;
        try {
          final oppData = await _client
              .from(SupabaseConstants.itemReportsTable)
              .select('*, profiles(display_name, avatar_url)')
              .eq('id', oppositeId)
              .single();
          result.add(MatchWithReport(
            match: match,
            oppositeReport: ItemReportModel.fromJson(oppData),
          ));
        } catch (_) {
          // Skip if opposite report not accessible
        }
      }
      return result;
    } on PostgrestException catch (e) {
      throw ServerException('Failed to load matches: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to load matches: $e');
    }
  }

  Future<void> dismissMatch(String matchId) async {
    try {
      await _client
          .from(SupabaseConstants.itemMatchesTable)
          .update({'status': 'DISMISSED'})
          .eq('id', matchId);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to dismiss match: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to dismiss match: $e');
    }
  }
}

final matchesRepositoryProvider = Provider<MatchesRepository>(
  (ref) => MatchesRepository(ref.watch(supabaseClientProvider)),
);
