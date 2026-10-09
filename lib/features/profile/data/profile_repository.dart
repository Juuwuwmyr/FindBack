import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  Future<ProfileModel> fetchProfile(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.profilesTable)
          .select()
          .eq('id', userId)
          .single();
      return ProfileModel.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundAppException('Profile not found.');
      throw ServerException('Failed to load profile: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to load profile: $e');
    }
  }

  Future<ProfileModel> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? locationText,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (locationText != null) updates['location_text'] = locationText;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (updates.isEmpty) return await fetchProfile(userId);
      final data = await _client
          .from(SupabaseConstants.profilesTable)
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return ProfileModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to update profile: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to update profile: $e');
    }
  }

  Future<String> uploadAvatar({required String userId, required File file}) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storagePath = '$userId/$fileName';
      await _client.storage.from(AppConstants.avatarsBucket).upload(
        storagePath, file, fileOptions: const FileOptions(upsert: true));
      return _client.storage.from(AppConstants.avatarsBucket).getPublicUrl(storagePath);
    } on StorageException catch (e) {
      throw AppStorageException('Avatar upload failed: ${e.message}');
    } catch (e) {
      throw AppStorageException('Avatar upload failed: $e');
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);
