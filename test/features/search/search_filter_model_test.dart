import 'package:flutter_test/flutter_test.dart';
import 'package:findback/features/search/domain/search_filter_model.dart';
import 'package:findback/features/reports/domain/item_report_model.dart';

void main() {
  group('SearchFilterModel', () {
    test('isEmpty is true for default', () {
      expect(const SearchFilterModel().isEmpty, isTrue);
    });

    test('hasActiveFilters false when only query set', () {
      expect(const SearchFilterModel(query: 'phone').hasActiveFilters, isFalse);
    });

    test('hasActiveFilters true when type set', () {
      expect(const SearchFilterModel(type: ReportType.lost).hasActiveFilters, isTrue);
    });

    test('copyWith clearType removes type', () {
      const filter = SearchFilterModel(type: ReportType.lost);
      final cleared = filter.copyWith(clearType: true);
      expect(cleared.type, isNull);
    });

    test('copyWith preserves other fields', () {
      const filter = SearchFilterModel(query: 'phone', type: ReportType.lost);
      final updated = filter.copyWith(query: 'bag');
      expect(updated.query, 'bag');
      expect(updated.type, ReportType.lost);
    });
  });
}
