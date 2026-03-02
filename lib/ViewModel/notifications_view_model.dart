import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsViewModel extends ChangeNotifier {
  List<NotificationItem> _upcomingNotifications = [];
  List<NotificationItem> _earlierNotifications = [];
  bool _isLoading = true;

  NotificationsViewModel() {
    _loadNotifications();
  }

  /// "Upcoming" section: today's schedules + future schedules + app notifications from today.
  List<NotificationItem> get todayNotifications =>
      List.unmodifiable(_upcomingNotifications);

  /// "Earlier" section: past schedules + older app notification records.
  List<NotificationItem> get earlierNotifications =>
      List.unmodifiable(_earlierNotifications);

  bool get isLoading => _isLoading;

  bool get hasUnread =>
      _upcomingNotifications.any((n) => n.isUnread) ||
      _earlierNotifications.any((n) => n.isUnread);

  int get unreadCount =>
      _upcomingNotifications.where((n) => n.isUnread).length +
      _earlierNotifications.where((n) => n.isUnread).length;

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Resolve user ID from Firestore
      final userSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('providerId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userId = userSnapshot.docs.first.id;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final List<NotificationItem> upcoming = [];
      final List<NotificationItem> earlier = [];

      // ── 1. Explicit notification records ──────────────────────────
      final notifSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final coveredScheduleIds = <String>{};

      for (final doc in notifSnapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final isRead = data['isRead'] as bool? ?? false;
        final typeString = data['type'] as String? ?? 'general';
        final type = NotificationType.values.firstWhere(
          (e) => e.name == typeString,
          orElse: () => NotificationType.general,
        );
        final linkedTimestamp = data['linkedDate'] as Timestamp?;
        final linkedDate = linkedTimestamp?.toDate();

        if (data['scheduleId'] != null) {
          coveredScheduleIds.add(data['scheduleId'] as String);
        }

        final item = NotificationItem(
          id: doc.id,
          title: data['title'] as String? ?? '',
          message: data['message'] as String? ?? '',
          timeLabel: _formatTimeLabel(createdAt),
          type: type,
          isUnread: !isRead,
          linkedDate: linkedDate,
          createdAt: createdAt,
          isFromSchedule: false, // Mark as real notification
        );

        if (createdAt != null && createdAt.isAfter(todayStart)) {
          upcoming.add(item);
        } else {
          earlier.add(item);
        }
      }

      // ── 2. Synthesize from schedules collection ───────────────────
      final schedulesSnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in schedulesSnapshot.docs) {
        // Skip if already referenced by an explicit notification record
        if (coveredScheduleIds.contains(doc.id)) continue;

        final data = doc.data();
        final startTimestamp = data['startDateTime'] as Timestamp?;
        if (startTimestamp == null) continue;

        final startDateTime = startTimestamp.toDate();
        final title = data['scheTitle'] as String? ?? 'Untitled';
        final description = data['scheDescription'] as String? ?? '';
        final isCompleted = data['isCompleted'] as bool? ?? false;
        final scheduleTypeString = data['scheduleType'] as String?;
        final notifType = _scheduleTypeToNotificationType(scheduleTypeString);

        final String notifTitle;
        final String notifMessage;
        final bool isUnread;

        if (isCompleted) {
          notifTitle = 'Completed: $title';
          notifMessage = description.isNotEmpty
              ? description
              : 'This schedule has been marked as completed.';
          isUnread = false;
        } else if (startDateTime.isAfter(now)) {
          notifTitle = 'Upcoming: $title';
          notifMessage = description.isNotEmpty
              ? description
              : 'Scheduled for ${_formatScheduleDate(startDateTime)}.';
          isUnread =
              false; // FIX: Upcoming schedules should not trigger the red dot permanently
        } else {
          notifTitle = 'Reminder: $title';
          notifMessage = description.isNotEmpty
              ? description
              : 'Was scheduled for ${_formatScheduleDate(startDateTime)}.';
          isUnread = false;
        }

        final item = NotificationItem(
          id: doc.id,
          title: notifTitle,
          message: notifMessage,
          timeLabel: _formatTimeLabel(startDateTime),
          type: notifType,
          isUnread: isUnread,
          linkedDate: startDateTime,
          createdAt: startDateTime,
          isFromSchedule: true, // Mark to prevent database crash!
        );

        // Upcoming (today or future) → upcoming section; past → earlier
        if (startDateTime.isAfter(todayStart) ||
            !isCompleted && startDateTime.isAfter(now)) {
          upcoming.add(item);
        } else {
          earlier.add(item);
        }
      }

      // Sort upcoming: soonest first; earlier: most recent first
      upcoming.sort(
        (a, b) => (a.createdAt ?? DateTime(2100)).compareTo(
          b.createdAt ?? DateTime(2100),
        ),
      );
      earlier.sort(
        (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
          a.createdAt ?? DateTime(2000),
        ),
      );

      _upcomingNotifications = upcoming;
      _earlierNotifications = earlier;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }

  String _formatTimeLabel(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('d MMM').format(dateTime);
  }

  // --- FUNCTION CALLED BY THE APP BAR BUTTON ---
  Future<void> markAllAsRead() async {
    final batch = FirebaseFirestore.instance.batch();
    bool anyChanged = false;

    for (final item in _upcomingNotifications) {
      if (item.isUnread) {
        item.isUnread = false; // Update UI immediately
        anyChanged = true;

        // FIX: Only update database if it's a REAL notification
        if (item.id != null && !item.isFromSchedule) {
          batch.update(
            FirebaseFirestore.instance.collection('notifications').doc(item.id),
            {'isRead': true},
          );
        }
      }
    }

    for (final item in _earlierNotifications) {
      if (item.isUnread) {
        item.isUnread = false; // Update UI immediately
        anyChanged = true;

        // FIX: Only update database if it's a REAL notification
        if (item.id != null && !item.isFromSchedule) {
          batch.update(
            FirebaseFirestore.instance.collection('notifications').doc(item.id),
            {'isRead': true},
          );
        }
      }
    }

    if (anyChanged) {
      try {
        await batch.commit(); // This will no longer crash!
      } catch (e) {
        debugPrint('Error marking all as read: $e');
      }
      notifyListeners();
    }
  }

  Future<void> markAsRead(NotificationItem item) async {
    if (!item.isUnread) return;
    item.isUnread = false;
    notifyListeners();

    // FIX: Prevent database crash
    if (item.id != null && !item.isFromSchedule) {
      try {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(item.id)
            .update({'isRead': true});
      } catch (e) {
        debugPrint('Error marking as read: $e');
      }
    }
  }

  Future<void> deleteNotification(NotificationItem item) async {
    _upcomingNotifications.remove(item);
    _earlierNotifications.remove(item);
    notifyListeners();

    // FIX: Prevent database crash
    if (item.id != null && !item.isFromSchedule) {
      try {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(item.id)
            .delete();
      } catch (e) {
        debugPrint('Error deleting notification: $e');
      }
    }
  }

  void openNotificationDetail(BuildContext context, NotificationItem item) {
    markAsRead(item);
    Navigator.pushNamed(context, '/notification_detail', arguments: item);
  }

  String _formatScheduleDate(DateTime dt) {
    return DateFormat('d MMM yyyy, h:mm a').format(dt);
  }

  NotificationType _scheduleTypeToNotificationType(String? scheduleType) {
    switch (scheduleType) {
      case 'vaccination':
        return NotificationType.vaccination;
      case 'checkUp':
        return NotificationType.checkUp;
      case 'medication':
        return NotificationType.medication;
      case 'grooming':
        return NotificationType.grooming;
      case 'exercise':
        return NotificationType.exercise;
      case 'vet':
        return NotificationType.vet;
      case 'feeding':
        return NotificationType.feeding;
      case 'note':
        return NotificationType.note;
      default:
        return NotificationType.general;
    }
  }

  static Future<void> createNotificationRecord({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    DateTime? linkedDate,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'isRead': false,
        'linkedDate': linkedDate != null
            ? Timestamp.fromDate(linkedDate)
            : null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating notification record: $e');
    }
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
  checkUp,
  exercise,
  feeding,
  note,
}

class NotificationItem {
  final String? id;
  final String title;
  final String message;
  final String timeLabel;
  final NotificationType type;
  bool isUnread;
  final DateTime? linkedDate;
  final DateTime? createdAt;
  final bool
  isFromSchedule; // NEW: Tells the app if this is a real notification or a schedule

  NotificationItem({
    this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.type = NotificationType.general,
    this.isUnread = true,
    this.linkedDate,
    this.createdAt,
    this.isFromSchedule = false,
  });
}
