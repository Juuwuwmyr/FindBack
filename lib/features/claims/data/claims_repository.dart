import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/claim_model.dart';

class ClaimsRepository {
  ClaimsRepository(this._client, this._storage);
  final SupabaseClient _client;
  final StorageService _storage;

  Future<ClaimModel> submitClaim({
    required String reportId,
    required String claimantId,
    required String description,
    required List<File> evidenceFiles,
    required ContactPreference contactPreference,
    String? contactDetail,
  }) async {
    if (evidenceFiles.isEmpty) {
      throw const ValidationException('At least one evidence image is required.');
    }
    try {
      // 1. Insert claim row (no evidence paths yet)
      final data = await _client
          .from(SupabaseConstants.claimsTable)
          .insert({
            'report_id': reportId,
            'claimant_id': claimantId,
            'description': description,
            'contact_preference': contactPreference.dbValue,
            if (contactDetail != null) 'contact_detail': contactDetail,
          })
          .select()
          .single();
      final claim = ClaimModel.fromJson(data);

      // 2. Upload evidence images
      final paths = <String>[];
      for (final file in evidenceFiles) {
        final path = await _storage.uploadEvidenceImage(claim.id, file);
        paths.add(path);
      }

      // 3. Update claim with evidence paths
      final updated = await _client
          .from(SupabaseConstants.claimsTable)
          .update({'evidence_image_paths': paths})
          .eq('id', claim.id)
          .select()
          .single();
      return ClaimModel.fromJson(updated);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const ValidationException('You already have an active claim on this report.');
      throw ServerException('Failed to submit claim: ${e.message}');
    } catch (e) {
      if (e is ValidationException || e is AppStorageException) rethrow;
      throw ServerException('Failed to submit claim: $e');
    }
  }

  Future<List<ClaimModel>> fetchClaimsForReport(String reportId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.claimsTable)
          .select('*, profiles(display_name, avatar_url)')
          .eq('report_id', reportId)
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((e) => ClaimModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException('Failed to fetch claims: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to fetch claims: $e');
    }
  }

  Future<ClaimModel?> fetchMyClaim(String reportId, String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.claimsTable)
          .select()
          .eq('report_id', reportId)
          .eq('claimant_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return ClaimModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to fetch claim: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to fetch claim: $e');
    }
  }

  Future<ClaimModel> fetchClaim(String claimId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.claimsTable)
          .select('*, profiles(display_name, avatar_url)')
          .eq('id', claimId)
          .single();
      return ClaimModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to fetch claim: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to fetch claim: $e');
    }
  }

  Future<void> withdrawClaim(String claimId) async {
    try {
      await _client
          .from(SupabaseConstants.claimsTable)
          .update({'status': 'WITHDRAWN'})
          .eq('id', claimId);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to withdraw claim: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to withdraw claim: $e');
    }
  }

  Future<void> approveClaim(String claimId) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw const AuthAppException('Not authenticated.');
      final response = await _client.functions.invoke(
        SupabaseConstants.fnApproveClaim,
        body: {'claim_id': claimId},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.status != 200) {
        final msg = response.data?['error'] ?? 'Failed to approve claim';
        throw ServerException(msg.toString());
      }
    } on FunctionException catch (e) {
      throw ServerException('Failed to approve claim: ${e.details}');
    } catch (e) {
      if (e is ServerException || e is AuthAppException) rethrow;
      throw ServerException('Failed to approve claim: $e');
    }
  }

  Future<void> rejectClaim(String claimId) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw const AuthAppException('Not authenticated.');
      final response = await _client.functions.invoke(
        SupabaseConstants.fnRejectClaim,
        body: {'claim_id': claimId},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.status != 200) {
        final msg = response.data?['error'] ?? 'Failed to reject claim';
        throw ServerException(msg.toString());
      }
    } on FunctionException catch (e) {
      throw ServerException('Failed to reject claim: ${e.details}');
    } catch (e) {
      if (e is ServerException || e is AuthAppException) rethrow;
      throw ServerException('Failed to reject claim: $e');
    }
  }

  Future<void> disputeClaim(String claimId) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw const AuthAppException('Not authenticated.');
      final response = await _client.functions.invoke(
        SupabaseConstants.fnDisputeClaim,
        body: {'claim_id': claimId},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.status != 200) {
        final msg = response.data?['error'] ?? 'Failed to dispute claim';
        throw ServerException(msg.toString());
      }
    } on FunctionException catch (e) {
      throw ServerException('Failed to dispute claim: ${e.details}');
    } catch (e) {
      if (e is ServerException || e is AuthAppException) rethrow;
      throw ServerException('Failed to dispute claim: $e');
    }
  }

  /// Download evidence image bytes using authenticated client (private bucket).
  Future<List<int>> downloadEvidenceImage(String storagePath) async {
    return _client.storage
        .from('claim-evidence')
        .download(storagePath);
  }
}

final claimsRepositoryProvider = Provider<ClaimsRepository>(
  (ref) => ClaimsRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(storageServiceProvider),
  ),
);
