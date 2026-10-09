import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cached_network_image_widget.dart';
import '../../reports/domain/item_report_model.dart';
import '../data/matches_repository.dart';
import '../domain/matches_provider.dart';

class MatchesSectionWidget extends ConsumerStatefulWidget {
  const MatchesSectionWidget({
    super.key,
    required this.reportId,
    required this.reportType,
  });

  final String reportId;
  final ReportType reportType;

  @override
  ConsumerState<MatchesSectionWidget> createState() =>
      _MatchesSectionWidgetState();
}

class _MatchesSectionWidgetState extends ConsumerState<MatchesSectionWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final matchesAsync =
        ref.watch(matchesForReportProvider(widget.reportId));

    return matchesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (matches) {
        if (matches.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.compare_arrows,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Possible Matches (${matches.length})',
                      style: AppTextStyles.titleSmall
                          .copyWith(color: AppColors.primary),
                    ),
                    const Spacer(),
                    Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: matches
                    .map((mwr) => _MatchCard(
                          mwr: mwr,
                          reportId: widget.reportId,
                          reportType: widget.reportType,
                        ))
                    .toList(),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        );
      },
    );
  }
}

class _MatchCard extends ConsumerWidget {
  const _MatchCard({
    required this.mwr,
    required this.reportId,
    required this.reportType,
  });

  final MatchWithReport mwr;
  final String reportId;
  final ReportType reportType;

  ReportType get _oppositeType =>
      reportType == ReportType.lost ? ReportType.found : ReportType.lost;

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    await ref.read(matchesRepositoryProvider).dismissMatch(mwr.match.id);
    ref.invalidate(matchesForReportProvider(reportId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Match dismissed')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opp = mwr.oppositeReport;
    final thumbnailUrl =
        opp.imageUrls.isNotEmpty ? opp.imageUrls.first : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImageWidget(
                    url: thumbnailUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _oppositeType == ReportType.lost
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _oppositeType.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _oppositeType == ReportType.lost
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opp.title,
                        style: AppTextStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: AppColors.hint),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              opp.locationText,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Score badge
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        mwr.match.scorePercent,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('match', style: AppTextStyles.labelSmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/report/${opp.id}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('View Report'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _dismiss(context, ref),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: AppColors.hint,
                    side: const BorderSide(color: AppColors.divider),
                  ),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
