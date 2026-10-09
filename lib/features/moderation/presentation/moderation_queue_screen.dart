import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/flag_model.dart';
import '../domain/moderation_provider.dart';

class ModerationQueueScreen extends ConsumerWidget {
  const ModerationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(moderationQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderation Queue'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: queueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(moderationQueueProvider.notifier).refresh(),
        ),
        data: (flags) {
          if (flags.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 64, color: AppColors.hint),
                    SizedBox(height: 16),
                    Text('Queue is clear',
                        style: AppTextStyles.titleMedium),
                    SizedBox(height: 8),
                    Text('No flagged content to review',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(moderationQueueProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: flags.length,
              itemBuilder: (context, index) {
                return _FlagTile(
                  flag: flags[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FlagTile extends ConsumerStatefulWidget {
  const _FlagTile({required this.flag});
  final FlagModel flag;

  @override
  ConsumerState<_FlagTile> createState() => _FlagTileState();
}

class _FlagTileState extends ConsumerState<_FlagTile> {
  String _reasonText = '';

  void _showActionSheet(
      BuildContext context, WidgetRef ref, FlagModel flag, String action) {
    _reasonText = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatAction(action)} — Add reason (optional)',
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Reason for action...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (v) => _reasonText = v,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Confirm',
                    onPressed: () async {
                      Navigator.pop(sheetCtx);
                      await ref
                          .read(moderationQueueProvider.notifier)
                          .performAction(
                            action: action,
                            targetType: flag.targetType,
                            targetId: flag.targetId,
                            reason: _reasonText.isEmpty ? null : _reasonText,
                            flagId: flag.id,
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Action taken')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAction(String action) {
    return action
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final flag = widget.flag;
    final isReport = flag.targetType == 'report';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isReport
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    flag.targetType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isReport
                          ? AppColors.primary
                          : AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ID: ${flag.targetId.substring(0, 8)}...',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                Text(
                  timeago.format(flag.createdAt),
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: ${flag.reason}',
              style: AppTextStyles.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => context.push(
                    isReport
                        ? '/report/${flag.targetId}'
                        : '/claims/${flag.targetId}',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: () => _showActionSheet(
                    context,
                    ref,
                    flag,
                    'REMOVE_${flag.targetType.toUpperCase()}',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () => ref
                      .read(moderationQueueProvider.notifier)
                      .performAction(
                        action: 'RESOLVE_FLAG',
                        targetType: 'flag',
                        targetId: flag.id,
                        flagId: flag.id,
                      ),
                  child: const Text(
                    'Dismiss',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.hint),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
