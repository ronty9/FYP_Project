// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_view_model.dart';
import 'notifications_view_model.dart';

class NotificationDetailViewModel extends BaseViewModel {
  final NotificationItem notification;

  NotificationDetailViewModel({required this.notification});

  void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  void deleteNotification(BuildContext context) async {
    // Delete from Firestore if it has an id
    if (notification.id != null) {
      try {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification.id)
            .delete();
      } catch (e) {
        debugPrint('Error deleting notification: $e');
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
      Navigator.pop(context, true); // Return true to indicate deletion
    }
  }

  // --- UPDATED NAVIGATION ---
  void goToCalendar(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
      arguments: 1,
    );
  }
}
