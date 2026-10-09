import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/profile_provider.dart';
import '../../auth/domain/auth_provider.dart';
import '../../reports/domain/reports_provider.dart';
import '../../reports/presentation/widgets/report_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(userId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnProfile = currentUserId == userId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () => context.push('/profile/edit'),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Could not load profile',
                  style: AppTextStyles.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(profileByIdProvider(userId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          if (profile.isBanned && !isOwnProfile) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, color: AppColors.error, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'This account is suspended.',
                      style: AppTextStyles.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor:
                      AppColors.primaryLight.withValues(alpha: 0.2),
                  child: profile.avatarUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profile.avatarUrl!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                _buildInitialsAvatar(profile.displayName),
                          ),
                        )
                      : _buildInitialsAvatar(profile.displayName),
                ),
                const SizedBox(height: 16),
                // Display name
                Text(
                  profile.displayName,
                  style: AppTextStyles.titleLarge,
                  textAlign: TextAlign.center,
                ),
                // Location
                if (profile.locationText != null &&
                    profile.locationText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.hint, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        profile.locationText!,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
                // Bio
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      profile.bio!,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Reports',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 16),
                ref.watch(reportsByUserProvider(userId)).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Center(
                      child: Text('Could not load reports',
                          style: AppTextStyles.bodySmall)),
                  data: (reports) => reports.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No reports yet',
                                style: AppTextStyles.bodySmall)))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reports.length,
                          itemBuilder: (_, i) => ReportCard(report: reports[i]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitialsAvatar(String displayName) {
    final initials = displayName.isNotEmpty
        ? displayName
            .trim()
            .split(' ')
            .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
            .take(2)
            .join()
        : '?';
    return Text(
      initials,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}
