import 'package:smart_ticketing/config/api_config.dart';
import 'package:smart_ticketing/services/notification_item.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_item.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService;
  late IO.Socket _socket;
  final FlutterLocalNotificationsPlugin _localNotifications;
  Function(NotificationItem)? onNewNotification; // Make it nullable

  NotificationService(this._apiService,
      [this.onNewNotification] // Make it optional
      )
      : _localNotifications = FlutterLocalNotificationsPlugin() {
    _initializeLocalNotifications();
  }

  // Add this method to set the callback after initialization
  void setNotificationCallback(Function(NotificationItem) callback) {
    onNewNotification = callback;
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  void _handleNotificationTap(NotificationResponse response) {
    // Handle notification tap based on payload
    final payload = response.payload;
    if (payload != null) {
      // Navigate to appropriate screen based on notification type
      // Implementation depends on your navigation setup
    }
  }

  void initializeSocket(String token) {
    _socket = IO.io(
      ApiConfig.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']).setAuth({'token': token}).build(),
    );

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socket.on('connect', (_) {
      print('Socket connected');
    });

    _socket.on('notification', (data) {
      final notification = NotificationItem.fromJson(data);
      _handleNewNotification(notification);
    });

    _socket.on('disconnect', (_) {
      print('Socket disconnected');
    });

    _socket.on('error', (error) {
      print('Socket error: $error');
    });
  }

  void _handleNewNotification(NotificationItem notification) {
    // Show local notification
    _showLocalNotification(notification);

    // Call callback for UI updates if it exists
    if (onNewNotification != null) {
      onNewNotification!(notification);
    }
  }

  Future<void> _showLocalNotification(NotificationItem notification) async {
    const androidDetails = AndroidNotificationDetails(
      'ticketing_system',
      'Ticketing System',
      channelDescription: 'Notifications from ticketing system',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      _getNotificationTitle(notification),
      notification.message,
      details,
      payload: notification.id,
    );
  }

  String _getNotificationTitle(NotificationItem notification) {
    switch (notification.notificationType) {
      case NotificationItemType.ticketAssigned:
        return 'New Ticket Assigned';
      case NotificationItemType.slaBreached:
        return 'SLA Breach Alert';
      case NotificationItemType.escalation:
        return 'Ticket Escalated';
      case NotificationItemType.shiftEnding:
        return 'Shift Ending Soon';
      case NotificationItemType.handover:
        return 'Ticket Handover';
      case NotificationItemType.breakReminder:
        return 'Break Time';
      case NotificationItemType.other:
        return 'New Notification';
    }
  }

  Future<List<NotificationItem>> getUnreadNotifications() async {
    try {
      final response = await _apiService.get('/notifications/unread');
      if (response.data == null || response.data['data'] == null) {
        return [];
      }

      List<dynamic> notificationList = response.data['data'] as List;
      return notificationList
          .map((json) => NotificationItem.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching unread notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.put('/notifications/$notificationId/read', {});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.put('/notifications/mark-all-read', {});
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Add method to get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      final response = await _apiService.get('/auth/me');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data']['id'].toString();
      }
      return null;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  void dispose() {
    _socket.disconnect();
    _socket.dispose();
  }
}
