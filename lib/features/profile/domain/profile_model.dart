class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.locationText,
    required this.isModerator,
    required this.isBanned,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String? locationText;
  final bool isModerator;
  final bool isBanned;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as String,
    displayName: json['display_name'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    bio: json['bio'] as String?,
    locationText: json['location_text'] as String?,
    isModerator: json['is_moderator'] as bool? ?? false,
    isBanned: json['is_banned'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  ProfileModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? locationText,
  }) => ProfileModel(
    id: id,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    bio: bio ?? this.bio,
    locationText: locationText ?? this.locationText,
    isModerator: isModerator,
    isBanned: isBanned,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
