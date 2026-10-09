import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/reports_repository.dart';
import '../domain/item_report_model.dart';
import '../domain/reports_provider.dart';
import '../../matches/presentation/matches_section_widget.dart';
import '../../claims/domain/claims_provider.dart';
import '../../claims/domain/claim_model.dart';
import '../../moderation/data/moderation_repository.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportDetailProvider(id));

    return reportAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Report'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(reportDetailProvider(id)),
        ),
      ),
      data: (report) => _ReportDetailView(id: id, report: report),
    );
  }
}

class _ReportDetailView extends ConsumerStatefulWidget {
  const _ReportDetailView({required this.id, required this.report});
  final String id;
  final ItemReportModel report;

  @override
  ConsumerState<_ReportDetailView> createState() => _ReportDetailViewState();
}

class _ReportDetailViewState extends ConsumerState<_ReportDetailView> {
  void _showFlagDialog(BuildContext context, WidgetRef ref) {
    String reason = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Flag this report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Why are you flagging this report?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
              onChanged: (v) => reason = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (reason.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(moderationRepositoryProvider)
                    .submitFlag(
                      targetType: 'report',
                      targetId: widget.id,
                      reason: reason.trim(),
                    );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report flagged for review. Thank you.'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _closeReport() async {
    try {
      await ref.read(reportsRepositoryProvider).softDeleteReport(widget.id);
      ref.invalidate(reportDetailProvider(widget.id));
      ref.invalidate(reportsFeedProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final currentUserId = ref.watch(currentUserIdProvider);
    final isAuthenticated =
        ref.watch(authNotifierProvider).valueOrNull?.isAuthenticated ?? false;
    final isOwnReport = currentUserId == report.reporterId;
    final myClaimAsync = ref.watch(myClaimForReportProvider(widget.id));
    final myClaim = myClaimAsync.valueOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: report.imageUrls.isNotEmpty ? 260.0 : 0,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Text(
              report.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (isOwnReport)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      context.push('/report/${widget.id}/edit');
                    } else if (v == 'close') {
                      _closeReport();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'close',
                      child: Row(children: [
                        Icon(Icons.close, size: 16),
                        SizedBox(width: 8),
                        Text('Close Report'),
                      ]),
                    ),
                  ],
                ),
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                onPressed: isAuthenticated ? () => _showFlagDialog(context, ref) : null,
              ),
            ],
            flexibleSpace: report.imageUrls.isNotEmpty
                ? FlexibleSpaceBar(
                    background: PageView.builder(
                      itemCount: report.imageUrls.length,
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: report.imageUrls[i],
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeBadge(type: report.type),
                      const SizedBox(width: 8),
                      _StatusBadge(status: report.status),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(report.title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: AppColors.hint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(report.locationText,
                            style: AppTextStyles.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: AppColors.hint),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy')
                            .format(report.dateOfIncident),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Description', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  Text(report.description, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 16),
                  if (report.rewardOffered) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accent),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reward: ${report.rewardDescription ?? "Contact reporter for details"}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: report.reporterAvatarUrl != null
                            ? CachedNetworkImageProvider(
                                report.reporterAvatarUrl!)
                            : null,
                        child: report.reporterAvatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.reporterName ?? 'User',
                            style: AppTextStyles.titleSmall,
                          ),
                          Text(
                            'Posted ${timeago.format(report.createdAt)}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isOwnReport && report.status == ReportStatus.active)
                    MatchesSectionWidget(
                      reportId: report.id,
                      reportType: report.type,
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(
          context, ref, report, isOwnReport, isAuthenticated, myClaim),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    WidgetRef ref,
    ItemReportModel report,
    bool isOwnReport,
    bool isAuthenticated,
    ClaimModel? myClaim,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _actionBarContent(
            context, ref, report, isOwnReport, isAuthenticated, myClaim),
      ),
    );
  }

  Widget _actionBarContent(
    BuildContext context,
    WidgetRef ref,
    ItemReportModel report,
    bool isOwnReport,
    bool isAuthenticated,
    ClaimModel? myClaim,
  ) {
    if (isOwnReport && report.status == ReportStatus.active) {
      return OutlinedButton(
        onPressed: () => context.push('/claims/list/${widget.id}'),
        style:
            OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
        child: const Text('View Claims'),
      );
    } else if (!isOwnReport &&
        report.status == ReportStatus.active &&
        isAuthenticated) {
      if (myClaim != null) {
        return AppButton(
          label: 'View My Claim',
          onPressed: () => context.push('/claims/${myClaim.id}'),
        );
      }
      return AppButton(
        label: 'Submit a Claim',
        onPressed: () =>
            context.push('/claims/submit/${widget.id}'),
      );
    } else if (!isAuthenticated && report.status == ReportStatus.active) {
      return AppButton(
        label: 'Sign In to Claim',
        onPressed: () => context.push('/auth/login'),
      );
    } else {
      return Text(
        report.status.label,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall,
      );
    }
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final ReportType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: type == ReportType.lost
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type == ReportType.lost ? 'LOST' : 'FOUND',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: type == ReportType.lost ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ReportStatus status;

  Color get _color {
    switch (status) {
      case ReportStatus.active:
        return AppColors.statusActive;
      case ReportStatus.claimed:
        return AppColors.statusClaimed;
      case ReportStatus.resolved:
        return AppColors.statusResolved;
      case ReportStatus.closed:
        return AppColors.statusClosed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
