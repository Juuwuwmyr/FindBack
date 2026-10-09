import 'package:flutter/foundation.dart';

enum NotificationType {
  newClaim,
  claimApproved,
  claimRejected,
  matchFound,
  disputeResolved,
  moderatorAction,
}

extension NotificationTypeExt on NotificationType {
  String get dbValue {
    switch (this) {
      case NotificationType.newClaim: return 'NEW_CLAIM';
      case NotificationType.claimApproved: return 'CLAIM_APPROVED';
      case NotificationType.claimRejected: return 'CLAIM_REJECTED';
      case NotificationType.matchFound: return 'MATCH_FOUND';
      case NotificationType.disputeResolved: return 'DISPUTE_RESOLVED';
      case NotificationType.moderatorAction: return 'MODERATOR_ACTION';
    }
  }

  static NotificationType fromDb(String value) {
    switch (value) {
      case 'NEW_CLAIM': return NotificationType.newClaim;
      case 'CLAIM_APPROVED': return NotificationType.claimApproved;
      case 'CLAIM_REJECTED': return NotificationType.claimRejected;
      case 'MATCH_FOUND': return NotificationType.matchFound;
      case 'DISPUTE_RESOLVED': return NotificationType.disputeResolved;
      case 'MODERATOR_ACTION': return NotificationType.moderatorAction;
      default: return NotificationType.moderatorAction;
    }
  }
}

@immutable
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationTypeExt.fromDb(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      payload: payload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
