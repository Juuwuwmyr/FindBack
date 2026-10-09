import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/item_report_model.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';

class ReportsRepository {
  ReportsRepository(this._client);

  final SupabaseClient _client;

  static const _profilesSelect = '*, profiles(display_name, avatar_url)';

  Future<List<ItemReportModel>> fetchFeed({
    String? cursorCreatedAt,
    String? cursorId,
    int limit = 20,
  }) async {
    try {
      var query = _client
          .from(SupabaseConstants.itemReportsTable)
          .select(_profilesSelect)
          .inFilter('status', ['ACTIVE', 'RESOLVED'])
          .isFilter('deleted_at', null);

      if (cursorCreatedAt != null && cursorId != null) {
        query = query.or(
          'created_at.lt.$cursorCreatedAt,and(created_at.eq.$cursorCreatedAt,id.lt.$cursorId)',
        );
      }

      final response = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit + 1);

      return (response as List<dynamic>)
          .map((e) => ItemReportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<ItemReportModel> fetchReport(String id) async {
    try {
      final response = await _client
          .from(SupabaseConstants.itemReportsTable)
          .select(_profilesSelect)
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        throw const NotFoundAppException();
      }

      return ItemReportModel.fromJson(response);
    } on NotFoundAppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<ItemReportModel>> fetchReportsByUser(
    String userId, {
    String? cursorCreatedAt,
    String? cursorId,
    int limit = 20,
  }) async {
    try {
      var query = _client
          .from(SupabaseConstants.itemReportsTable)
          .select(_profilesSelect)
          .eq('reporter_id', userId)
          .isFilter('deleted_at', null);

      if (cursorCreatedAt != null && cursorId != null) {
        query = query.or(
          'created_at.lt.$cursorCreatedAt,and(created_at.eq.$cursorCreatedAt,id.lt.$cursorId)',
        );
      }

      final response = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit + 1);

      return (response as List<dynamic>)
          .map((e) => ItemReportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<ItemReportModel> createReport({
    required ReportType type,
    required String title,
    required String description,
    required ItemCategory category,
    required DateTime dateOfIncident,
    required String locationText,
    bool rewardOffered = false,
    String? rewardDescription,
    required String reporterId,
  }) async {
    try {
      final data = {
        'reporter_id': reporterId,
        'type': type.dbValue,
        'title': title,
        'description': description,
        'category': category.dbValue,
        'date_of_incident': dateOfIncident.toIso8601String().split('T').first,
        'location_text': locationText,
        'reward_offered': rewardOffered,
        if (rewardDescription != null)
          'reward_description': rewardDescription,
      };

      final response = await _client
          .from(SupabaseConstants.itemReportsTable)
          .insert(data)
          .select(_profilesSelect)
          .single();

      return ItemReportModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> addImagesToReport(
    String reportId,
    List<String> imageUrls,
  ) async {
    try {
      final existing = await fetchReport(reportId);
      final merged = [...existing.imageUrls, ...imageUrls];

      await _client
          .from(SupabaseConstants.itemReportsTable)
          .update({'image_urls': merged})
          .eq('id', reportId);
    } on NotFoundAppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> updateReport(
    String id, {
    String? title,
    String? description,
    ItemCategory? category,
    DateTime? dateOfIncident,
    String? locationText,
    bool? rewardOffered,
    String? rewardDescription,
    List<String>? imageUrls,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category.dbValue;
      if (dateOfIncident != null) {
        updates['date_of_incident'] =
            dateOfIncident.toIso8601String().split('T').first;
      }
      if (locationText != null) updates['location_text'] = locationText;
      if (rewardOffered != null) updates['reward_offered'] = rewardOffered;
      if (rewardDescription != null) {
        updates['reward_description'] = rewardDescription;
      }
      if (imageUrls != null) updates['image_urls'] = imageUrls;

      if (updates.isEmpty) return;

      await _client
          .from(SupabaseConstants.itemReportsTable)
          .update(updates)
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> softDeleteReport(String id) async {
    try {
      await _client
          .from(SupabaseConstants.itemReportsTable)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(supabaseClientProvider)),
);
