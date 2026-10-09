enum MatchStatus { pending, dismissed }

extension MatchStatusExt on MatchStatus {
  String get dbValue => name.toUpperCase();
  static MatchStatus fromDb(String v) =>
      MatchStatus.values.firstWhere((e) => e.dbValue == v.toUpperCase());
}

class ItemMatchModel {
  const ItemMatchModel({
    required this.id,
    required this.lostReportId,
    required this.foundReportId,
    required this.score,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String lostReportId;
  final String foundReportId;
  final double score;
  final MatchStatus status;
  final DateTime createdAt;

  String get scorePercent => '${(score * 100).round()}%';

  factory ItemMatchModel.fromJson(Map<String, dynamic> json) => ItemMatchModel(
    id: json['id'] as String,
    lostReportId: json['lost_report_id'] as String,
    foundReportId: json['found_report_id'] as String,
    score: (json['score'] as num).toDouble(),
    status: MatchStatusExt.fromDb(json['status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
