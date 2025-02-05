import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/services/api_service.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final notifier = NotificationNotifier(
    NotificationService(apiService, (notification) {}),
  );

  return NotificationService(
    apiService,
    (notification) {
      notifier.addNotification(notification);
    },
  );
});

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationNotifier(service);
});

class NotificationState {
  final bool isLoading;
  final List<NotificationItem> notifications;
  final String? error;
  final int unreadCount;

  NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationItem>? notifications,
    String? error,
    int? unreadCount,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;

  NotificationNotifier(this._notificationService) : super(NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final notifications = await _notificationService.getUnreadNotifications();
      state = state.copyWith(
        isLoading: false,
        notifications: notifications,
        unreadCount: notifications.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void addNotification(NotificationItem notification) {
    final updatedNotifications = [notification, ...state.notifications];
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: state.unreadCount + 1,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return NotificationItem(
            id: notification.id,
            type: notification.type,
            message: notification.message,
            recipient: notification.recipient,
            read: true,
            ticketId: notification.ticketId,
            createdAt: notification.createdAt,
            metadata: notification.metadata,
          );
        }
        return notification;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount - 1,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      final updatedNotifications = state.notifications.map((notification) {
        return NotificationItem(
          id: notification.id,
          type: notification.type,
          message: notification.message,
          recipient: notification.recipient,
          read: true,
          ticketId: notification.ticketId,
          createdAt: notification.createdAt,
          metadata: notification.metadata,
        );
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
