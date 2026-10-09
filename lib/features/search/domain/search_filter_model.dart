import '../../reports/domain/item_report_model.dart';

class SearchFilterModel {
  const SearchFilterModel({
    this.query = '',
    this.type,
    this.category,
    this.dateFrom,
    this.dateTo,
    this.locationText = '',
  });

  final String query;
  final ReportType? type;
  final ItemCategory? category;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String locationText;

  bool get hasActiveFilters =>
      type != null ||
      category != null ||
      dateFrom != null ||
      dateTo != null ||
      locationText.isNotEmpty;

  bool get isEmpty => query.isEmpty && !hasActiveFilters;

  SearchFilterModel copyWith({
    String? query,
    ReportType? type,
    bool clearType = false,
    ItemCategory? category,
    bool clearCategory = false,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    String? locationText,
  }) {
    return SearchFilterModel(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      category: clearCategory ? null : (category ?? this.category),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      locationText: locationText ?? this.locationText,
    );
  }
}
