class AppConstants {
  AppConstants._();

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String reportImagesBucket = 'report-images';
  static const String claimEvidenceBucket = 'claim-evidence';

  // Image limits
  static const int maxAvatarSizeBytes = 2 * 1024 * 1024;     // 2 MB
  static const int maxReportImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxClaimEvidenceSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxReportImages = 5;
  static const int minClaimEvidenceImages = 1;
  static const int maxClaimEvidenceImages = 5;
  static const int imageCompressionTargetBytes = 800 * 1024; // 800 KB
  static const int imageMaxDimension = 1920;

  // Pagination
  static const int feedPageSize = 20;
  static const int searchPageSize = 20;
  static const int notificationsLimit = 50;

  // Validation
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 2000;
  static const int maxClaimDescriptionLength = 1000;
  static const int maxBioLength = 280;
  static const int maxLocationLength = 200;
  static const int maxDisplayNameLength = 100;
  static const int minPasswordLength = 8;

  // Match algorithm
  static const double matchThreshold = 0.45;
  static const double matchWeightCategory = 0.40;
  static const double matchWeightText = 0.40;
  static const double matchWeightDate = 0.10;
  static const double matchWeightLocation = 0.10;
  static const int matchDateWindowDays = 14;

  // Search debounce
  static const Duration searchDebounce = Duration(milliseconds: 400);
}
