import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/flag_model.dart';
import '../domain/audit_log_model.dart';

class ModerationRepository {
  ModerationRepository(this._client);
  final SupabaseClient _client;

  Future<List<FlagModel>> fetchUnresolvedFlags() async {
    final data = await _client
        .from(SupabaseConstants.flagsTable)
        .select()
        .eq('resolved', false)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => FlagModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitFlag({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _client.from(SupabaseConstants.flagsTable).insert({
      'reporter_id': userId,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
    });
  }

  Future<void> performAction({
    required String action,
    required String targetType,
    required String targetId,
    String? reason,
    String? flagId,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');
    await _client.functions.invoke(
      SupabaseConstants.fnModerateAction,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        if (reason != null) 'reason': reason,
        if (flagId != null) 'flag_id': flagId,
      },
    );
  }

  Future<List<AuditLogModel>> fetchAuditLogs({int limit = 50}) async {
    final data = await _client
        .from(SupabaseConstants.auditLogsTable)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => ModerationRepository(ref.watch(supabaseClientProvider)),
);
