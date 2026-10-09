import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/search_repository.dart';
import '../domain/search_filter_model.dart';
import '../../reports/domain/item_report_model.dart';

class SearchState {
  const SearchState({
    this.filter = const SearchFilterModel(),
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = false,
    this.cursorCreatedAt,
    this.cursorId,
  });

  final SearchFilterModel filter;
  final List<ItemReportModel> results;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final String? cursorCreatedAt;
  final String? cursorId;

  bool get hasResults => results.isNotEmpty;
  bool get hasSearched => !filter.isEmpty;

  SearchState copyWith({
    SearchFilterModel? filter,
    List<ItemReportModel>? results,
    bool? isLoading,
    String? error,
    bool? hasMore,
    String? cursorCreatedAt,
    String? cursorId,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return SearchState(
      filter: filter ?? this.filter,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      cursorCreatedAt:
          clearCursor ? null : (cursorCreatedAt ?? this.cursorCreatedAt),
      cursorId: clearCursor ? null : (cursorId ?? this.cursorId),
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._repo) : super(const SearchState());

  final SearchRepository _repo;
  Timer? _debounce;
  static const _debounceMs = 400;
  static const _pageSize = 20;

  void updateQuery(String query) {
    state = state.copyWith(filter: state.filter.copyWith(query: query));
    _debounce?.cancel();
    if (query.trim().isEmpty && !state.filter.hasActiveFilters) {
      state = state.copyWith(
        results: [],
        clearError: true,
        clearCursor: true,
        hasMore: false,
      );
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: _debounceMs), _executeSearch);
  }

  void updateFilter(SearchFilterModel filter) {
    state = state.copyWith(filter: filter);
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: _debounceMs), _executeSearch);
  }

  void clearSearch() {
    _debounce?.cancel();
    state = const SearchState();
  }

  Future<void> _executeSearch() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      results: [],
      clearCursor: true,
      hasMore: false,
    );
    try {
      final results =
          await _repo.search(filter: state.filter, limit: _pageSize);
      final hasMore = results.length > _pageSize;
      final trimmed = hasMore ? results.sublist(0, _pageSize) : results;
      state = state.copyWith(
        results: trimmed,
        isLoading: false,
        hasMore: hasMore,
        cursorCreatedAt: trimmed.isNotEmpty
            ? trimmed.last.createdAt.toIso8601String()
            : null,
        cursorId: trimmed.isNotEmpty ? trimmed.last.id : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final next = await _repo.search(
        filter: state.filter,
        cursorCreatedAt: state.cursorCreatedAt,
        cursorId: state.cursorId,
        limit: _pageSize,
      );
      final hasMore = next.length > _pageSize;
      final trimmed = hasMore ? next.sublist(0, _pageSize) : next;
      state = state.copyWith(
        results: [...state.results, ...trimmed],
        isLoading: false,
        hasMore: hasMore,
        cursorCreatedAt: trimmed.isNotEmpty
            ? trimmed.last.createdAt.toIso8601String()
            : state.cursorCreatedAt,
        cursorId:
            trimmed.isNotEmpty ? trimmed.last.id : state.cursorId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(ref.watch(searchRepositoryProvider)),
);
