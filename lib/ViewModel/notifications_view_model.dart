import 'package:flutter/material.dart';

class NotificationsViewModel extends ChangeNotifier {
  final List<NotificationItem> _todayNotifications = [
    NotificationItem(
      title: 'Upcoming vaccination',
      message: 'Milo has a vaccination scheduled for today at 4:00 PM.',
      timeLabel: 'Just now',
      type: NotificationType.vaccination,
      linkedDate: DateTime(2025, 1, 10),
      isUnread: true,
    ),
    NotificationItem(
      title: 'Scan reminder',
      message: "It's been a week since Luna's last skin scan.",
      timeLabel: '10 min ago',
      type: NotificationType.scan,
      isUnread: true,
    ),
  ];

  final List<NotificationItem> _earlierNotifications = [
    NotificationItem(
      title: 'New feature',
      message: 'Try the new scan history feature in your Scan tab.',
      timeLabel: 'Yesterday',
      type: NotificationType.appUpdate,
      isUnread: false,
    ),
    NotificationItem(
      title: 'Welcome to PetCare AI',
      message:
          'Thanks for joining! Add your pets to get personalized insights.',
      timeLabel: '2 days ago',
      type: NotificationType.welcome,
      isUnread: false,
    ),
  ];

  List<NotificationItem> get todayNotifications =>
      List.unmodifiable(_todayNotifications);
  List<NotificationItem> get earlierNotifications =>
      List.unmodifiable(_earlierNotifications);

  bool get hasUnread =>
      _todayNotifications.any((n) => n.isUnread) ||
      _earlierNotifications.any((n) => n.isUnread);

  int get unreadCount =>
      _todayNotifications.where((n) => n.isUnread).length +
      _earlierNotifications.where((n) => n.isUnread).length;

  // --- FUNCTION CALLED BY THE APP BAR BUTTON ---
  void markAllAsRead() {
    for (final item in _todayNotifications) {
      item.isUnread = false;
    }
    for (final item in _earlierNotifications) {
      item.isUnread = false;
    }
    notifyListeners();
  }

  void markAsRead(NotificationItem item) {
    if (!item.isUnread) return;
    item.isUnread = false;
    notifyListeners();
  }

  void openNotificationDetail(BuildContext context, NotificationItem item) {
    markAsRead(item);
    // Assuming '/notification_detail' is configured in main.dart
    Navigator.pushNamed(context, '/notification_detail', arguments: item);
  }
}

enum NotificationType {
  vaccination,
  medication,
  vet,
  grooming,
  walk,
  scan,
  appUpdate,
  welcome,
  general,
}

class NotificationItem {
  final String title;
  final String message;
  final String timeLabel;
  final NotificationType type;
  bool isUnread;
  final DateTime? linkedDate;

  NotificationItem({
    required this.title,
    required this.message,
    required this.timeLabel,
    this.type = NotificationType.general,
    this.isUnread = true,
    this.linkedDate,
  });
}
