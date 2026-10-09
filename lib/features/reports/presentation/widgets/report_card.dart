import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/item_report_model.dart';

IconData _categoryIcon(ItemCategory cat) {
  switch (cat) {
    case ItemCategory.electronics:
      return Icons.devices;
    case ItemCategory.documentsKeys:
      return Icons.badge;
    case ItemCategory.bagsLuggage:
      return Icons.luggage;
    case ItemCategory.clothingAccessories:
      return Icons.checkroom;
    case ItemCategory.pets:
      return Icons.pets;
    case ItemCategory.jewelry:
      return Icons.diamond;
    case ItemCategory.sportsEquipment:
      return Icons.sports_soccer;
    case ItemCategory.booksStationery:
      return Icons.menu_book;
    case ItemCategory.toys:
      return Icons.toys;
    case ItemCategory.vehicles:
      return Icons.directions_car;
    case ItemCategory.moneyCards:
      return Icons.credit_card;
    case ItemCategory.other:
      return Icons.category;
  }
}

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report});
  final ItemReportModel report;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/report/${report.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: report.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: report.imageUrls.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: report.type == ReportType.lost
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            report.type == ReportType.lost ? 'LOST' : 'FOUND',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: report.type == ReportType.lost
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeago.format(report.createdAt),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.title,
                      style: AppTextStyles.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: AppColors.hint),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.locationText,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            report.category.label,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        if (report.rewardOffered) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star,
                              size: 12, color: AppColors.accent),
                          Text(
                            'Reward',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.accent),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.surface,
      child: Icon(
        _categoryIcon(report.category),
        color: AppColors.hint,
        size: 32,
      ),
    );
  }
}
