enum NotificationItemType {
  ticketAssigned,
  slaBreached,
  escalation,
  shiftEnding,
  handover,
  breakReminder,
  other
}

extension NotificationItemTypeExtension on NotificationItemType {
  static NotificationItemType fromString(String type) {
    switch (type) {
      case 'ticket_assigned':
        return NotificationItemType.ticketAssigned;
      case 'sla_breach':
        return NotificationItemType.slaBreached;
      case 'escalation':
        return NotificationItemType.escalation;
      case 'shift_ending':
        return NotificationItemType.shiftEnding;
      case 'handover':
        return NotificationItemType.handover;
      case 'break_reminder':
        return NotificationItemType.breakReminder;
      default:
        return NotificationItemType.other;
    }
  }
}
