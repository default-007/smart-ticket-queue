// Updated notification_provider.dart file to break the circular dependency

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/services/api_service.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

// First define API service provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Create a provider for the callback function to break the cycle
final notificationCallbackProvider =
    Provider<Function(NotificationItem)>((ref) {
  return (notification) {
    // This will be called by NotificationService when a new notification arrives
    ref.read(notificationProvider.notifier).addNotification(notification);
  };
});

// Now define NotificationService provider with explicit type
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  // Use dummy callback initially - we'll set the real one later in code
  return NotificationService(
    apiService,
    (_) {}, // Placeholder callback - won't actually be used
  );
});

// Define the notification state provider that uses the service
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final service = ref.read(notificationServiceProvider);
  final apiService = ref.read(apiServiceProvider);
  return NotificationNotifier(service, apiService);
});

// Configure the notification service callback after providers are initialized
void initializeNotificationCallback(ProviderContainer container) {
  final service = container.read(notificationServiceProvider);
  final callback = container.read(notificationCallbackProvider);
  service.setNotificationCallback(callback);
}

class NotificationState {
  final bool isLoading;
  final List<NotificationItem> notifications;
  final String? error;
  final int unreadCount;
  final Map<String, int> countsByType;

  NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
    this.unreadCount = 0,
    this.countsByType = const {},
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationItem>? notifications,
    String? error,
    int? unreadCount,
    Map<String, int>? countsByType,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      countsByType: countsByType ?? this.countsByType,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;
  final ApiService apiService;

  NotificationNotifier(this._notificationService, this.apiService)
      : super(NotificationState()) {
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

  Future<void> loadNotificationsWithCounts() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final userId = await _notificationService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not available');
      }

      final response = await apiService.get('/notifications/batched/$userId');

      final notifications = (response.data['data']['unread'] as List)
          .map((json) => NotificationItem.fromJson(json))
          .toList();

      state = state.copyWith(
        isLoading: false,
        notifications: notifications,
        unreadCount: response.data['data']['total'],
        countsByType: Map<String, int>.from(response.data['data']['byType']),
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
