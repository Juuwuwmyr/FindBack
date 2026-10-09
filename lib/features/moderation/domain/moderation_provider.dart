import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/moderation_repository.dart';
import 'flag_model.dart';

class ModerationQueueNotifier extends AsyncNotifier<List<FlagModel>> {
  @override
  Future<List<FlagModel>> build() async {
    return ref.read(moderationRepositoryProvider).fetchUnresolvedFlags();
  }

  Future<void> refresh() async {
    final flags =
        await ref.read(moderationRepositoryProvider).fetchUnresolvedFlags();
    state = AsyncData(flags);
  }

  Future<void> performAction({
    required String action,
    required String targetType,
    required String targetId,
    String? reason,
    String? flagId,
  }) async {
    await ref.read(moderationRepositoryProvider).performAction(
          action: action,
          targetType: targetType,
          targetId: targetId,
          reason: reason,
          flagId: flagId,
        );
    if (flagId != null) {
      state = state.whenData(
          (flags) => flags.where((f) => f.id != flagId).toList());
    }
    await refresh();
  }
}

final moderationQueueProvider =
    AsyncNotifierProvider<ModerationQueueNotifier, List<FlagModel>>(
  ModerationQueueNotifier.new,
);
