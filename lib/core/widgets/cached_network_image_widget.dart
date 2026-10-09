import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class CachedNetworkImageWidget extends StatelessWidget {
  const CachedNetworkImageWidget({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius = 0,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _placeholder();
    }

    final image = CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.surface,
        child: Container(
          width: width,
          height: height,
          color: AppColors.divider,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: AppColors.surface,
        child: const Icon(
          Icons.broken_image,
          color: AppColors.hint,
        ),
      ),
    );

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }
    return image;
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(
        Icons.image,
        color: AppColors.hint,
      ),
    );
  }
}
