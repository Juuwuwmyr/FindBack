import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../../reports/domain/item_report_model.dart';
import '../domain/search_filter_model.dart';

class SearchRepository {
  SearchRepository(this._client);
  final SupabaseClient _client;

  Future<List<ItemReportModel>> search({
    required SearchFilterModel filter,
    String? cursorCreatedAt,
    String? cursorId,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_limit': limit + 1,
      };
      if (filter.query.isNotEmpty) params['p_query'] = filter.query.trim();
      if (filter.type != null) params['p_type'] = filter.type!.dbValue;
      if (filter.category != null) {
        params['p_category'] = filter.category!.dbValue;
      }
      if (filter.dateFrom != null) {
        params['p_date_from'] =
            filter.dateFrom!.toIso8601String().split('T').first;
      }
      if (filter.dateTo != null) {
        params['p_date_to'] =
            filter.dateTo!.toIso8601String().split('T').first;
      }
      if (filter.locationText.isNotEmpty) {
        params['p_location'] = filter.locationText.trim();
      }
      if (cursorCreatedAt != null) {
        params['p_cursor_created_at'] = cursorCreatedAt;
      }
      if (cursorId != null) params['p_cursor_id'] = cursorId;

      final response = await _client.rpc('search_reports', params: params);
      return (response as List<dynamic>)
          .map((e) => ItemReportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException('Search failed: ${e.message}');
    } catch (e) {
      throw ServerException('Search failed: $e');
    }
  }
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(supabaseClientProvider)),
);
