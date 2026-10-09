import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reports_repository.dart';
import 'item_report_model.dart';

// Feed provider with pagination
class ReportsFeedNotifier extends AsyncNotifier<List<ItemReportModel>> {
  String? _lastCreatedAt;
  String? _lastId;
  bool _hasMore = true;

  @override
  Future<List<ItemReportModel>> build() async {
    _lastCreatedAt = null;
    _lastId = null;
    _hasMore = true;
    final results = await ref.read(reportsRepositoryProvider).fetchFeed();
    if (results.length <= 20) {
      _hasMore = false;
    } else {
      _hasMore = true;
    }
    final items = results.length > 20 ? results.sublist(0, 20) : results;
    if (items.isNotEmpty) {
      _lastCreatedAt = items.last.createdAt.toIso8601String();
      _lastId = items.last.id;
    }
    return items;
  }

  Future<void> loadNextPage() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.valueOrNull ?? [];
    final repo = ref.read(reportsRepositoryProvider);
    final next = await repo.fetchFeed(
      cursorCreatedAt: _lastCreatedAt,
      cursorId: _lastId,
    );
    if (next.length <= 20) {
      _hasMore = false;
    } else {
      _hasMore = true;
    }
    final items = next.length > 20 ? next.sublist(0, 20) : next;
    if (items.isNotEmpty) {
      _lastCreatedAt = items.last.createdAt.toIso8601String();
      _lastId = items.last.id;
    }
    state = AsyncData([...current, ...items]);
  }

  Future<void> refresh() async {
    _lastCreatedAt = null;
    _lastId = null;
    _hasMore = true;
    ref.invalidateSelf();
  }

  bool get hasMore => _hasMore;
}

final reportsFeedProvider =
    AsyncNotifierProvider<ReportsFeedNotifier, List<ItemReportModel>>(
        ReportsFeedNotifier.new);

// Single report detail
final reportDetailProvider =
    FutureProvider.family<ItemReportModel, String>((ref, id) {
  return ref.watch(reportsRepositoryProvider).fetchReport(id);
});

// Reports by a specific user (for profile screen)
final reportsByUserProvider =
    FutureProvider.family<List<ItemReportModel>, String>((ref, userId) {
  return ref.watch(reportsRepositoryProvider).fetchReportsByUser(userId);
});
