import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../domain/notification_model.dart';
import '../domain/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(notificationsProvider.notifier).refresh(),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateView(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications',
              subtitle:
                  'Updates about your reports and claims appear here',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(
                  notification: n,
                  onTap: () => _handleTap(context, ref, n),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleTap(
      BuildContext context, WidgetRef ref, NotificationModel n) {
    ref.read(notificationsProvider.notifier).markAsRead(n.id);
    final payload = n.payload;
    switch (n.type) {
      case NotificationType.newClaim:
        final reportId = payload['report_id'] as String?;
        if (reportId != null) context.push('/claims/list/$reportId');
      case NotificationType.claimApproved:
      case NotificationType.claimRejected:
      case NotificationType.disputeResolved:
        final claimId = payload['claim_id'] as String?;
        if (claimId != null) context.push('/claims/$claimId');
      case NotificationType.matchFound:
        final reportId = payload['report_id'] as String?;
        if (reportId != null) context.push('/report/$reportId');
      case NotificationType.moderatorAction:
        // No navigation
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newClaim:
        return Icons.assignment_ind_outlined;
      case NotificationType.claimApproved:
        return Icons.check_circle_outline;
      case NotificationType.claimRejected:
        return Icons.cancel_outlined;
      case NotificationType.matchFound:
        return Icons.compare_arrows;
      case NotificationType.disputeResolved:
        return Icons.gavel;
      case NotificationType.moderatorAction:
        return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return ListTile(
      tileColor: n.isRead
          ? null
          : AppColors.primary.withValues(alpha: 0.04),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: n.isRead
            ? AppColors.surface
            : AppColors.primary.withValues(alpha: 0.12),
        child: Icon(
          _typeIcon(n.type),
          color: n.isRead ? AppColors.hint : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        n.title,
        style: n.isRead ? AppTextStyles.bodyMedium : AppTextStyles.titleSmall,
      ),
      subtitle: Text(
        n.body,
        style: AppTextStyles.bodySmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeago.format(n.createdAt),
            style: AppTextStyles.labelSmall,
          ),
          if (!n.isRead)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
