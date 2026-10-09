import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../domain/profile_model.dart';
import '../../auth/domain/auth_provider.dart';

final profileByIdProvider = FutureProvider.family<ProfileModel, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
});

final ownProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
});

class ProfileEditNotifier extends StateNotifier<ProfileModel?> {
  ProfileEditNotifier(this._repo) : super(null);
  final ProfileRepository _repo;

  void startEditing(ProfileModel profile) => state = profile;
  void updateDisplayName(String v) => state = state?.copyWith(displayName: v);
  void updateBio(String v) => state = state?.copyWith(bio: v);
  void updateLocationText(String v) => state = state?.copyWith(locationText: v);
  void updateAvatarUrl(String v) => state = state?.copyWith(avatarUrl: v);

  Future<ProfileModel> save(String userId) async {
    if (state == null) throw Exception('No profile to save');
    final saved = await _repo.updateProfile(
      userId: userId,
      displayName: state!.displayName,
      bio: state!.bio,
      locationText: state!.locationText,
      avatarUrl: state!.avatarUrl,
    );
    state = saved;
    return saved;
  }

  void reset() => state = null;
}

final profileEditProvider = StateNotifierProvider<ProfileEditNotifier, ProfileModel?>(
  (ref) => ProfileEditNotifier(ref.watch(profileRepositoryProvider)),
);
