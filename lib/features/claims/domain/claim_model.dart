enum ClaimStatus { pending, approved, rejected, withdrawn, disputed }
enum ContactPreference { inApp, email, phone }

extension ClaimStatusExt on ClaimStatus {
  String get dbValue => name.toUpperCase();
  String get label {
    switch (this) {
      case ClaimStatus.pending: return 'Pending';
      case ClaimStatus.approved: return 'Approved';
      case ClaimStatus.rejected: return 'Rejected';
      case ClaimStatus.withdrawn: return 'Withdrawn';
      case ClaimStatus.disputed: return 'Disputed';
    }
  }
  static ClaimStatus fromDb(String v) =>
      ClaimStatus.values.firstWhere((e) => e.dbValue == v.toUpperCase());
}

extension ContactPreferenceExt on ContactPreference {
  String get dbValue {
    switch (this) {
      case ContactPreference.inApp: return 'IN_APP';
      case ContactPreference.email: return 'EMAIL';
      case ContactPreference.phone: return 'PHONE';
    }
  }
  String get label {
    switch (this) {
      case ContactPreference.inApp: return 'In-App Message';
      case ContactPreference.email: return 'Email';
      case ContactPreference.phone: return 'Phone';
    }
  }
  static ContactPreference fromDb(String v) {
    switch (v.toUpperCase()) {
      case 'EMAIL': return ContactPreference.email;
      case 'PHONE': return ContactPreference.phone;
      default: return ContactPreference.inApp;
    }
  }
}

class ClaimModel {
  const ClaimModel({
    required this.id,
    required this.reportId,
    required this.claimantId,
    required this.status,
    required this.description,
    required this.evidenceImagePaths,
    required this.contactPreference,
    this.contactDetail,
    this.reviewerId,
    this.reviewedAt,
    required this.createdAt,
    this.updatedAt,
    this.claimantName,
    this.claimantAvatarUrl,
  });

  final String id;
  final String reportId;
  final String claimantId;
  final ClaimStatus status;
  final String description;
  final List<String> evidenceImagePaths;
  final ContactPreference contactPreference;
  final String? contactDetail;
  final String? reviewerId;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? claimantName;
  final String? claimantAvatarUrl;

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;
    return ClaimModel(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      claimantId: json['claimant_id'] as String,
      status: ClaimStatusExt.fromDb(json['status'] as String),
      description: json['description'] as String,
      evidenceImagePaths: (json['evidence_image_paths'] as List<dynamic>?)
              ?.map((e) => e as String).toList() ?? [],
      contactPreference: ContactPreferenceExt.fromDb(json['contact_preference'] as String),
      contactDetail: json['contact_detail'] as String?,
      reviewerId: json['reviewer_id'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      claimantName: profileData?['display_name'] as String?,
      claimantAvatarUrl: profileData?['avatar_url'] as String?,
    );
  }
}
