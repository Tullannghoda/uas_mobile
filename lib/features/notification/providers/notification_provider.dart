import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

class NotificationState {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.hasLoaded = false,
  });

  final bool hasLoaded;

  int get unreadCount =>
      notifications.where((n) => n['is_read'] == false).length;

  NotificationState copyWith({
    List<Map<String, dynamic>>? notifications,
    bool? isLoading,
    bool? hasLoaded,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  final _supabase = SupabaseService.client;
  RealtimeChannel? _subscription;

  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      state = state.copyWith(
        notifications: List<Map<String, dynamic>>.from(data),
        isLoading: false,
        hasLoaded: true,
      );

      // Setup Realtime listening
      _subscription?.unsubscribe();
      _subscription = _supabase
          .channel('public:notifications:user_id=eq.$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              final newNotif = payload.newRecord;
              state = state.copyWith(
                notifications: [newNotif, ...state.notifications],
              );
            },
          )
          .subscribe();
    } catch (e) {
      state = state.copyWith(isLoading: false, hasLoaded: true);
    }
  }

  Future<void> markRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);

    final updated = state.notifications.map((n) {
      if (n['id'] == id) {
        return {...n, 'is_read': true};
      }
      return n;
    }).toList();

    state = state.copyWith(notifications: updated);
  }

  Future<void> markAllRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);

    final updated = state.notifications
        .map((n) => {...n, 'is_read': true})
        .toList();

    state = state.copyWith(notifications: updated);
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final notificationProvider =
StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});