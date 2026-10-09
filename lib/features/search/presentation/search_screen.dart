import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../reports/domain/item_report_model.dart';
import '../../reports/presentation/widgets/report_card.dart';
import '../domain/search_filter_model.dart';
import '../domain/search_provider.dart';

// ---------------------------------------------------------------------------
// Search Screen
// ---------------------------------------------------------------------------

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _queryCtrl;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController();
    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      ref.read(searchProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _queryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet(SearchFilterModel currentFilter) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        currentFilter: currentFilter,
        onApply: (filter) =>
            ref.read(searchProvider.notifier).updateFilter(filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final filter = state.filter;
    final hasActiveFilters = filter.hasActiveFilters;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: TextField(
          controller: _queryCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search lost & found...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: (v) {
            setState(() {});
            ref.read(searchProvider.notifier).updateQuery(v);
          },
        ),
        actions: [
          if (_queryCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _queryCtrl.clear();
                setState(() {});
                ref.read(searchProvider.notifier).clearSearch();
              },
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _showFilterSheet(filter),
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (hasActiveFilters)
            _ActiveFiltersRow(
              filter: filter,
              onFilterChanged: (updated) =>
                  ref.read(searchProvider.notifier).updateFilter(updated),
              onClearAll: () {
                _queryCtrl.clear();
                setState(() {});
                ref.read(searchProvider.notifier).clearSearch();
              },
            ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    if (!state.hasSearched) {
      return const EmptyStateView(
        icon: Icons.search,
        title: 'Search FindBack',
        subtitle: 'Find lost or found items by keyword, category, or location',
      );
    }

    if (state.isLoading && !state.hasResults) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return ErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(searchProvider.notifier).updateQuery(_queryCtrl.text),
      );
    }

    if (!state.hasResults) {
      return const EmptyStateView(
        icon: Icons.search_off,
        title: 'No results',
        subtitle: 'Try different keywords or adjust your filters',
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      itemCount: state.results.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ReportCard(report: state.results[index]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Active Filters Row
// ---------------------------------------------------------------------------

class _ActiveFiltersRow extends StatelessWidget {
  const _ActiveFiltersRow({
    required this.filter,
    required this.onFilterChanged,
    required this.onClearAll,
  });

  final SearchFilterModel filter;
  final ValueChanged<SearchFilterModel> onFilterChanged;
  final VoidCallback onClearAll;

  String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (filter.type != null) {
      chips.add(_FilterChip(
        label: filter.type!.label,
        onDeleted: () => onFilterChanged(filter.copyWith(clearType: true)),
      ));
    }

    if (filter.category != null) {
      chips.add(_FilterChip(
        label: filter.category!.label,
        onDeleted: () =>
            onFilterChanged(filter.copyWith(clearCategory: true)),
      ));
    }

    if (filter.dateFrom != null || filter.dateTo != null) {
      final from = filter.dateFrom;
      final to = filter.dateTo;
      final String dateLabel;
      if (from != null && to != null) {
        dateLabel = '${_fmt(from)} – ${_fmt(to)}';
      } else if (from != null) {
        dateLabel = 'From ${_fmt(from)}';
      } else {
        dateLabel = 'Until ${_fmt(to!)}';
      }
      chips.add(_FilterChip(
        label: dateLabel,
        onDeleted: () => onFilterChanged(
          filter.copyWith(clearDateFrom: true, clearDateTo: true),
        ),
      ));
    }

    if (filter.locationText.isNotEmpty) {
      chips.add(_FilterChip(
        label: filter.locationText,
        onDeleted: () => onFilterChanged(filter.copyWith(locationText: '')),
      ));
    }

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...chips,
            TextButton(
              onPressed: onClearAll,
              child: const Text('Clear all'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: AppTextStyles.bodySmall),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onDeleted,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Bottom Sheet
// ---------------------------------------------------------------------------

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.currentFilter,
    required this.onApply,
  });

  final SearchFilterModel currentFilter;
  final ValueChanged<SearchFilterModel> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  ReportType? _type;
  ItemCategory? _category;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  late final TextEditingController _locationCtrl;

  @override
  void initState() {
    super.initState();
    final f = widget.currentFilter;
    _type = f.type;
    _category = f.category;
    _dateFrom = f.dateFrom;
    _dateTo = f.dateTo;
    _locationCtrl = TextEditingController(text: f.locationText);
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _type = null;
      _category = null;
      _dateFrom = null;
      _dateTo = null;
      _locationCtrl.clear();
    });
  }

  void _applyFilters() {
    final filter = widget.currentFilter.copyWith(
      type: _type,
      clearType: _type == null,
      category: _category,
      clearCategory: _category == null,
      dateFrom: _dateFrom,
      clearDateFrom: _dateFrom == null,
      dateTo: _dateTo,
      clearDateTo: _dateTo == null,
      locationText: _locationCtrl.text.trim(),
    );
    widget.onApply(filter);
    Navigator.of(context).pop();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_dateFrom ?? DateTime.now())
        : (_dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const Text('Filters', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 20),

                    // ── Report Type ──────────────────────────────────────
                    const Text('Report Type', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _type == null,
                          onSelected: (_) => setState(() => _type = null),
                        ),
                        ChoiceChip(
                          label: const Text('LOST'),
                          selected: _type == ReportType.lost,
                          onSelected: (_) =>
                              setState(() => _type = ReportType.lost),
                        ),
                        ChoiceChip(
                          label: const Text('FOUND'),
                          selected: _type == ReportType.found,
                          onSelected: (_) =>
                              setState(() => _type = ReportType.found),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Category ─────────────────────────────────────────
                    const Text('Category', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: ItemCategory.values.map((cat) {
                        return ChoiceChip(
                          label: Text(cat.label),
                          selected: _category == cat,
                          onSelected: (selected) => setState(
                            () => _category = selected ? cat : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── Date Range ───────────────────────────────────────
                    const Text('Date Range', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickDate(isFrom: true),
                            child: Text(
                              _dateFrom != null
                                  ? _fmtDate(_dateFrom!)
                                  : 'From date',
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickDate(isFrom: false),
                            child: Text(
                              _dateTo != null
                                  ? _fmtDate(_dateTo!)
                                  : 'To date',
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Location ─────────────────────────────────────────
                    const Text('Location', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Makati City',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Actions ──────────────────────────────────────────
                    Row(
                      children: [
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Reset'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
