import 'package:flutter/material.dart';
import '../../models/notification_item.dart';
import 'notification_tile.dart';
import '../common/error_display.dart';
import '../common/loading_indicator.dart';

class NotificationList extends StatelessWidget {
  final List<NotificationItem> notifications;
  final bool isLoading;
  final String? error;

  const NotificationList({
    Key? key,
    required this.notifications,
    required this.isLoading,
    this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (error != null) {
      return ErrorDisplay(
        message: error!,
        onRetry: () {
          // Implement retry logic
        },
      );
    }

    if (notifications.isEmpty) {
      return const Center(
        child: Text(
          'No notifications',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return NotificationTile(
          notification: notifications[index],
        );
      },
    );
  }
}
