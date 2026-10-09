class SupabaseConstants {
  SupabaseConstants._();

  // Table names
  static const String profilesTable = 'profiles';
  static const String itemReportsTable = 'item_reports';
  static const String claimsTable = 'claims';
  static const String itemMatchesTable = 'item_matches';
  static const String notificationsTable = 'notifications';
  static const String flagsTable = 'flags';
  static const String auditLogsTable = 'audit_logs';

  // Edge Function names
  static const String fnCreateProfile = 'create-profile';
  static const String fnApproveClaim = 'approve-claim';
  static const String fnRejectClaim = 'reject-claim';
  static const String fnDisputeClaim = 'dispute-claim';
  static const String fnResolveDispute = 'resolve-dispute';
  static const String fnComputeMatches = 'compute-matches';
  static const String fnModerateAction = 'moderate-action';
  static const String fnSetModerator = 'set-moderator';

  // RPC function names
  static const String rpcSearchReports = 'search_reports';
}
