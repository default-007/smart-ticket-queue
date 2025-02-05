import 'package:smart_ticketing/config/api_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService;
  late IO.Socket _socket;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Function(Notification) onNewNotification;

  NotificationService(
    this._apiService,
    this.onNewNotification,
  ) : _localNotifications = FlutterLocalNotificationsPlugin() {
    _initializeLocalNotifications();
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
      final notification = Notification.fromJson(data);
      _handleNewNotification(notification);
    });

    _socket.on('disconnect', (_) {
      print('Socket disconnected');
    });

    _socket.on('error', (error) {
      print('Socket error: $error');
    });
  }

  void _handleNewNotification(Notification notification) {
    // Show local notification
    _showLocalNotification(notification);

    // Call callback for UI updates
    onNewNotification(notification);
  }

  Future<void> _showLocalNotification(Notification notification) async {
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

  String _getNotificationTitle(Notification notification) {
    switch (notification.notificationType) {
      case NotificationType.ticketAssigned:
        return 'New Ticket Assigned';
      case NotificationType.slaBreached:
        return 'SLA Breach Alert';
      case NotificationType.escalation:
        return 'Ticket Escalated';
      case NotificationType.shiftEnding:
        return 'Shift Ending Soon';
      case NotificationType.handover:
        return 'Ticket Handover';
      case NotificationType.breakReminder:
        return 'Break Time';
      default:
        return 'New Notification';
    }
  }

  Future<List<Notification>> getUnreadNotifications() async {
    try {
      final response = await _apiService.get('/notifications/unread');
      return (response.data['data'] as List)
          .map((json) => Notification.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching unread notifications: $e');
      rethrow;
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

  void dispose() {
    _socket.disconnect();
    _socket.dispose();
  }
}
