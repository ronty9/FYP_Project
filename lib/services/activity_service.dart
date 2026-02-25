import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityService {
  static final CollectionReference _logsRef = FirebaseFirestore.instance
      .collection('system_activity_logs');

  // Log an event
  static Future<void> log({
    required String action, // e.g., 'User Login', 'Account Suspended'
    required String description, // e.g., 'John Doe logged in'
    required String actorName, // Who did it? 'Admin' or 'User Name'
    required String type, // 'INFO', 'WARNING', 'CRITICAL' (determines color)
  }) async {
    try {
      await _logsRef.add({
        'action': action,
        'description': description,
        'actorName': actorName,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Failed to log activity: $e");
    }
  }
}
