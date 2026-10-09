import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/notifications_repository.dart';
import 'notification_model.dart';

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  Future<List<NotificationModel>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];

    // Cancel any previous subscription
    _subscription?.cancel();
    ref.onDispose(() => _subscription?.cancel());

    // Subscribe to real-time changes
    final client = ref.read(supabaseClientProvider);
    _subscription = client
        .from(SupabaseConstants.notificationsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((_) => refresh());

    return ref.read(notificationsRepositoryProvider).fetchNotifications();
  }

  Future<void> refresh() async {
    final notifications =
        await ref.read(notificationsRepositoryProvider).fetchNotifications();
    state = AsyncData(notifications);
  }

  Future<void> markAsRead(String id) async {
    await ref.read(notificationsRepositoryProvider).markAsRead(id);
    state = state.whenData((list) =>
        list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList());
  }

  Future<void> markAllRead() async {
    await ref.read(notificationsRepositoryProvider).markAllRead();
    state = state.whenData(
        (list) => list.map((n) => n.copyWith(isRead: true)).toList());
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).valueOrNull?.where((n) => !n.isRead).length ?? 0;
});
