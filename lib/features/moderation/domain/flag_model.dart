import 'package:flutter/foundation.dart';

@immutable
class FlagModel {
  const FlagModel({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.resolved,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String reason;
  final bool resolved;
  final DateTime createdAt;

  factory FlagModel.fromJson(Map<String, dynamic> json) {
    return FlagModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String,
      reason: json['reason'] as String,
      resolved: json['resolved'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
