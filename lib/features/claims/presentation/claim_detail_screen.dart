import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/domain/auth_provider.dart';
import '../../reports/domain/reports_provider.dart';
import '../data/claims_repository.dart';
import '../domain/claim_model.dart';
import '../domain/claims_provider.dart';

class ClaimDetailScreen extends ConsumerStatefulWidget {
  const ClaimDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends ConsumerState<ClaimDetailScreen> {
  // ── Helper methods ──────────────────────────────────────────────────────────

  Color _statusColor(ClaimStatus s) {
    switch (s) {
      case ClaimStatus.pending:
        return AppColors.statusPending;
      case ClaimStatus.approved:
        return AppColors.statusApproved;
      case ClaimStatus.rejected:
        return AppColors.statusRejected;
      case ClaimStatus.withdrawn:
        return AppColors.statusWithdrawn;
      case ClaimStatus.disputed:
        return AppColors.statusDisputed;
    }
  }

  IconData _statusIcon(ClaimStatus s) {
    switch (s) {
      case ClaimStatus.pending:
        return Icons.hourglass_empty;
      case ClaimStatus.approved:
        return Icons.check_circle;
      case ClaimStatus.rejected:
        return Icons.cancel;
      case ClaimStatus.withdrawn:
        return Icons.undo;
      case ClaimStatus.disputed:
        return Icons.gavel;
    }
  }

  IconData _contactIcon(ContactPreference p) {
    switch (p) {
      case ContactPreference.inApp:
        return Icons.chat_bubble_outline;
      case ContactPreference.email:
        return Icons.email_outlined;
      case ContactPreference.phone:
        return Icons.phone_outlined;
    }
  }

  // ── Action methods ──────────────────────────────────────────────────────────

  Future<void> _approve(ClaimModel claim) async {
    try {
      await ref.read(claimsRepositoryProvider).approveClaim(claim.id);
      ref.invalidate(claimDetailProvider(widget.id));
      ref.invalidate(claimsForReportProvider(claim.reportId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Claim approved')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _reject(ClaimModel claim) async {
    try {
      await ref.read(claimsRepositoryProvider).rejectClaim(claim.id);
      ref.invalidate(claimDetailProvider(widget.id));
      ref.invalidate(claimsForReportProvider(claim.reportId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Claim rejected')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _withdraw(ClaimModel claim) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Claim'),
        content: const Text(
            'Are you sure you want to withdraw your claim? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Withdraw',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(claimsRepositoryProvider).withdrawClaim(claim.id);
      ref.invalidate(claimDetailProvider(widget.id));
      ref.invalidate(claimsForReportProvider(claim.reportId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Claim withdrawn')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _dispute(ClaimModel claim) async {
    try {
      await ref.read(claimsRepositoryProvider).disputeClaim(claim.id);
      ref.invalidate(claimDetailProvider(widget.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Dispute submitted — a moderator will review')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final claimAsync = ref.watch(claimDetailProvider(widget.id));
    final currentUserId = ref.watch(currentUserIdProvider);

    final appBar = AppBar(
      title: const Text('Claim Details'),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    );

    return claimAsync.when(
      loading: () => Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: appBar,
        body: ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(claimDetailProvider(widget.id)),
        ),
      ),
      data: (claim) {
        final reportAsync = ref.watch(reportDetailProvider(claim.reportId));
        final isReporter =
            reportAsync.valueOrNull?.reporterId == currentUserId;
        final isClaimant = claim.claimantId == currentUserId;

        return Scaffold(
          appBar: appBar,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusColor(claim.status)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusColor(claim.status)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusIcon(claim.status),
                        color: _statusColor(claim.status),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            claim.status.label,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: _statusColor(claim.status),
                            ),
                          ),
                          if (claim.reviewedAt != null)
                            Text(
                              'Reviewed ${timeago.format(claim.reviewedAt!)}',
                              style: AppTextStyles.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),

                // 4. Claimant section
                const Text('Claimant', style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: claim.claimantAvatarUrl != null
                          ? NetworkImage(claim.claimantAvatarUrl!)
                          : null,
                      child: claim.claimantAvatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          claim.claimantName ?? 'User',
                          style: AppTextStyles.titleSmall,
                        ),
                        Text(
                          timeago.format(claim.createdAt),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 8. Description section
                const Text('Description', style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),
                Text(claim.description, style: AppTextStyles.bodyMedium),

                const SizedBox(height: 16),

                // 12. Evidence photos section
                const Text('Evidence Photos', style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),

                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: claim.evidenceImagePaths.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FutureBuilder<List<int>>(
                        future: ref
                            .read(claimsRepositoryProvider)
                            .downloadEvidenceImage(
                                claim.evidenceImagePaths[i]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              width: 120,
                              height: 120,
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: AppColors.surface,
                              child:
                                  const Icon(Icons.broken_image_outlined),
                            );
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              Uint8List.fromList(snapshot.data!),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),

                // 17. Contact preference section
                const Text('Contact Preference',
                    style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      _contactIcon(claim.contactPreference),
                      size: 18,
                      color: AppColors.hint,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      claim.contactPreference.label,
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (claim.contactDetail != null && isReporter)
                      Text(
                        ' — ${claim.contactDetail}',
                        style: AppTextStyles.bodyMedium,
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // 21. Action buttons
                _buildActions(claim, isReporter: isReporter, isClaimant: isClaimant),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(
    ClaimModel claim, {
    required bool isReporter,
    required bool isClaimant,
  }) {
    if (isReporter) {
      if (claim.status == ClaimStatus.pending) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Approve Claim',
                onPressed: () => _approve(claim),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Reject',
                variant: AppButtonVariant.destructive,
                onPressed: () => _reject(claim),
              ),
            ),
          ],
        );
      } else if (claim.status == ClaimStatus.disputed) {
        return const SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Dispute escalated to moderator',
            onPressed: null,
          ),
        );
      }
    }

    if (isClaimant) {
      if (claim.status == ClaimStatus.pending) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Withdraw Claim',
            variant: AppButtonVariant.destructive,
            onPressed: () => _withdraw(claim),
          ),
        );
      } else if (claim.status == ClaimStatus.rejected) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Dispute Decision',
            variant: AppButtonVariant.secondary,
            onPressed: () => _dispute(claim),
          ),
        );
      } else if (claim.status == ClaimStatus.approved) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.statusApproved.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColors.statusApproved),
              const SizedBox(width: 8),
              Text(
                'Your claim was approved!',
                style: AppTextStyles.titleSmall
                    .copyWith(color: AppColors.statusApproved),
              ),
            ],
          ),
        );
      } else if (claim.status == ClaimStatus.disputed) {
        return const Text(
          'Your dispute is under moderator review',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        );
      } else if (claim.status == ClaimStatus.withdrawn) {
        return const Text(
          'You withdrew this claim',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        );
      }
    }

    return const SizedBox.shrink();
  }
}
