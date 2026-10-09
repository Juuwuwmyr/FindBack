import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/domain/auth_provider.dart';
import '../domain/item_report_model.dart';
import '../domain/reports_provider.dart';
import 'widgets/report_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollCtrl = ScrollController();
  ReportType? _typeFilter;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent * 0.8) {
      ref.read(reportsFeedProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(reportsFeedProvider);
    final authenticated =
        ref.watch(authNotifierProvider).valueOrNull?.isAuthenticated ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.manage_search, color: Colors.white),
            SizedBox(width: 8),
            Text('FindBack'),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _typeFilter == null,
                  onTap: () => setState(() => _typeFilter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Lost',
                  selected: _typeFilter == ReportType.lost,
                  onTap: () => setState(() => _typeFilter = ReportType.lost),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Found',
                  selected: _typeFilter == ReportType.found,
                  onTap: () => setState(() => _typeFilter = ReportType.found),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(reportsFeedProvider.notifier).refresh(),
              child: feedAsync.when(
                loading: () => _buildShimmer(),
                error: (e, _) => Center(
                  child: ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(reportsFeedProvider),
                  ),
                ),
                data: (reports) {
                  final filtered = _typeFilter == null
                      ? reports
                      : reports
                          .where((r) => r.type == _typeFilter)
                          .toList();
                  if (filtered.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64, color: AppColors.hint),
                              SizedBox(height: 16),
                              Text('No reports yet',
                                  style: AppTextStyles.titleMedium),
                              SizedBox(height: 8),
                              Text(
                                'Be the first to report a lost or found item',
                                style: AppTextStyles.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  final notifier =
                      ref.read(reportsFeedProvider.notifier);
                  return ListView.builder(
                    controller: _scrollCtrl,
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, i) {
                      if (i == filtered.length) {
                        return notifier.hasMore
                            ? const SizedBox(
                                height: 60,
                                child: Center(
                                    child: CircularProgressIndicator()),
                              )
                            : const SizedBox(height: 20);
                      }
                      return ReportCard(report: filtered[i]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Report'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        onPressed: () {
          if (authenticated) {
            context.push('/report/create');
          } else {
            context.push('/auth/login');
          }
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            height: 104,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.onBackground,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
