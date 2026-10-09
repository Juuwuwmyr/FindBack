import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/claim_model.dart';
import '../domain/claims_provider.dart';

class ClaimsListScreen extends ConsumerWidget {
  const ClaimsListScreen({super.key, required this.reportId});
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(claimsForReportProvider(reportId));

    return Scaffold(
      appBar: AppBar(
        title: claimsAsync.maybeWhen(
          data: (claims) => Text('Claims (${claims.length})'),
          orElse: () => const Text('Claims'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: claimsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(claimsForReportProvider(reportId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (claims) {
          if (claims.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: AppColors.hint),
                  SizedBox(height: 16),
                  Text('No claims yet', style: AppTextStyles.titleMedium),
                  SizedBox(height: 8),
                  Text('Claims will appear here when people submit them', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: claims.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _ClaimListTile(claim: claims[i]),
          );
        },
      ),
    );
  }
}

class _ClaimListTile extends StatelessWidget {
  const _ClaimListTile({required this.claim});
  final ClaimModel claim;

  Color _statusColor(ClaimStatus s) {
    switch (s) {
      case ClaimStatus.pending: return AppColors.statusPending;
      case ClaimStatus.approved: return AppColors.statusApproved;
      case ClaimStatus.rejected: return AppColors.statusRejected;
      case ClaimStatus.withdrawn: return AppColors.statusWithdrawn;
      case ClaimStatus.disputed: return AppColors.statusDisputed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: claim.claimantAvatarUrl != null ? NetworkImage(claim.claimantAvatarUrl!) : null,
        child: claim.claimantAvatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(claim.claimantName ?? 'Anonymous', style: AppTextStyles.titleSmall),
      subtitle: Text(claim.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StatusChip(status: claim.status, color: _statusColor(claim.status)),
          const SizedBox(height: 4),
          Text(timeago.format(claim.createdAt), style: AppTextStyles.bodySmall),
        ],
      ),
      onTap: () => context.push('/claims/${claim.id}'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});
  final ClaimStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
