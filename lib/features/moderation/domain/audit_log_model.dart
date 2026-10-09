import 'package:flutter/foundation.dart';

@immutable
class AuditLogModel {
  const AuditLogModel({
    required this.id,
    this.actorId,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.reason,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String? actorId;
  final String action;
  final String targetType;
  final String targetId;
  final String? reason;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String,
      actorId: json['actor_id'] as String?,
      action: json['action'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String,
      reason: json['reason'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
