import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import 'supabase_service.dart';

class StorageService {
  StorageService(this._client);
  final SupabaseClient _client;

  /// Picks an image from gallery or camera. Returns null if cancelled.
  Future<XFile?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    return picker.pickImage(source: source, imageQuality: 90);
  }

  /// Compresses an image file to max 800KB, 1920px on the longest side.
  Future<File?> compressImage(String sourcePath) async {
    final targetPath = '${sourcePath}_compressed.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: 85,
      minWidth: 1080,
      minHeight: 1080,
      keepExif: false,
    );
    if (result == null) return null;
    return File(result.path);
  }

  /// Uploads a report image. Returns the public URL.
  Future<String> uploadReportImage(String reportId, File file) async {
    try {
      final compressed = await compressImage(file.path) ?? file;
      final ext = file.path.split('.').last.toLowerCase();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString().replaceAll('#', '')}.$ext';
      final storagePath = '$reportId/$fileName';
      await _client.storage
          .from(AppConstants.reportImagesBucket)
          .upload(storagePath, compressed,
              fileOptions: const FileOptions(upsert: false));
      return _client.storage
          .from(AppConstants.reportImagesBucket)
          .getPublicUrl(storagePath);
    } on StorageException catch (e) {
      throw AppStorageException('Report image upload failed: ${e.message}');
    } catch (e) {
      throw AppStorageException('Report image upload failed: $e');
    }
  }

  /// Uploads a claim evidence image. Returns the storage path (not public URL).
  Future<String> uploadEvidenceImage(String claimId, File file) async {
    try {
      final compressed = await compressImage(file.path) ?? file;
      final ext = file.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storagePath = '$claimId/$fileName';
      await _client.storage
          .from(AppConstants.claimEvidenceBucket)
          .upload(storagePath, compressed,
              fileOptions: const FileOptions(upsert: false));
      return storagePath; // private bucket — return path not public URL
    } on StorageException catch (e) {
      throw AppStorageException('Evidence upload failed: ${e.message}');
    } catch (e) {
      throw AppStorageException('Evidence upload failed: $e');
    }
  }

  /// Downloads evidence image bytes (auth-header pattern, private bucket).
  Future<Uint8List> downloadEvidenceImage(String storagePath) async {
    try {
      return await _client.storage
          .from(AppConstants.claimEvidenceBucket)
          .download(storagePath);
    } on StorageException catch (e) {
      throw AppStorageException('Evidence download failed: ${e.message}');
    } catch (e) {
      throw AppStorageException('Evidence download failed: $e');
    }
  }
}

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(supabaseClientProvider)),
);
