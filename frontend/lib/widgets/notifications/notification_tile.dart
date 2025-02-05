import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/models/notification_item.dart';
import 'package:smart_ticketing/services/notification_item.dart';
import 'package:timeago/timeago.dart' as timeago;
//import '../../models/notification.dart';
import '../../providers/notification_provider.dart';

class NotificationTile extends ConsumerWidget {
  final NotificationItem notification;

  const NotificationTile({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        // Implement delete logic
      },
      child: InkWell(
        onTap: () {
          if (!notification.read) {
            ref.read(notificationProvider.notifier).markAsRead(notification.id);
          }
          _handleNotificationTap(context);
        },
        child: Container(
          color: notification.read ? null : Colors.blue.withOpacity(0.1),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: notification.typeColor.withOpacity(0.2),
              child: Icon(
                _getNotificationIcon(),
                color: notification.typeColor,
                size: 20,
              ),
            ),
            title: Text(
              _getNotificationTitle(),
              style: TextStyle(
                fontWeight:
                    notification.read ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(notification.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
            trailing: !notification.read
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.notificationType) {
      case NotificationItemType.ticketAssigned:
        return Icons.assignment;
      case NotificationItemType.slaBreached:
        return Icons.warning;
      case NotificationItemType.escalation:
        return Icons.arrow_upward;
      case NotificationItemType.shiftEnding:
        return Icons.access_time;
      case NotificationItemType.handover:
        return Icons.swap_horiz;
      case NotificationItemType.breakReminder:
        return Icons.coffee;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationTitle() {
    switch (notification.notificationType) {
      case NotificationItemType.ticketAssigned:
        return 'New Ticket Assignment';
      case NotificationItemType.slaBreached:
        return 'SLA Breach Alert';
      case NotificationItemType.escalation:
        return 'Ticket Escalation';
      case NotificationItemType.shiftEnding:
        return 'Shift Ending Soon';
      case NotificationItemType.handover:
        return 'Ticket Handover';
      case NotificationItemType.breakReminder:
        return 'Break Reminder';
      default:
        return 'Notification';
    }
  }

  void _handleNotificationTap(BuildContext context) {
    if (notification.ticketId != null) {
      Navigator.pushNamed(
        context,
        '/tickets/detail',
        arguments: notification.ticketId,
      );
    }
  }
}
