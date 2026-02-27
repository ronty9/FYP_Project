import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../View/scan_history_detail_view.dart';
import '../scan_type.dart';
import 'base_view_model.dart';

class ScanHistoryItem {
  const ScanHistoryItem({
    required this.type,
    required this.topLabel,
    required this.confidence,
    required this.dateLabel,
    required this.timestamp,
    this.imageUrl,
  });

  final ScanType type;
  final String topLabel;
  final double confidence;
  final String dateLabel;
  final DateTime timestamp;
  final String? imageUrl;

  bool get isDisease => type == ScanType.skinDisease;
}

class ScanHistoryViewModel extends BaseViewModel {
  ScanHistoryViewModel() {
    _fetchHistoryFromFirebase();
  }

  List<ScanHistoryItem> _history = [];

  List<ScanHistoryItem> get history => List.unmodifiable(_history);

  bool get hasHistory => _history.isNotEmpty;

  // --- FETCH DATA FROM FIREBASE (FAIL-PROOF) ---
  void _fetchHistoryFromFirebase() {
    runAsync(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("DEBUG: No user is currently logged in!");
        return;
      }

      try {
        // We removed .orderBy() to bypass the Firebase Index Error!
        final snapshot = await FirebaseFirestore.instance
            .collection('ScanHistory')
            .where('userId', isEqualTo: user.uid)
            .get();

        final fetchedList = snapshot.docs.map((doc) {
          final data = doc.data();

          // 1. Determine Scan Type
          final scanTypeStr = data['scanType'] as String?;
          final type = scanTypeStr == 'breed'
              ? ScanType.breed
              : ScanType.skinDisease;

          // 2. Format Timestamp to readable String
          final timestamp = data['date'] as Timestamp?;
          final dateTime = timestamp?.toDate() ?? DateTime.now();
          final dateStr = _formatDate(timestamp);

          return ScanHistoryItem(
            type: type,
            topLabel: data['topLabel'] ?? 'Unknown',
            confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
            dateLabel: dateStr,
            timestamp: dateTime,
            imageUrl: data['imageUrl'] as String?,
          );
        }).toList();

        // 3. Sort the list locally in Flutter (Newest first)
        fetchedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // 4. Update the UI
        _history = fetchedList;
        notifyListeners();

        print("DEBUG: Successfully fetched ${_history.length} records.");
      } catch (e) {
        print("DEBUG: Error fetching scan history: $e");
      }
    });
  }

  void openHistoryItem(BuildContext context, ScanHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScanHistoryDetailView(item: item)),
    );
  }

  // --- HELPER: FORMAT DATE ---
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Date';

    final date = timestamp.toDate();
    final now = DateTime.now();

    // Format Time (e.g., 8:05 PM)
    int hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    String period = date.hour >= 12 ? 'PM' : 'AM';
    String minute = date.minute.toString().padLeft(2, '0');
    String timeStr = '$hour:$minute $period';

    // Format Date (e.g., 24 Nov 2025)
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String monthStr = months[date.month - 1];

    // Check if it's Today or Yesterday
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today · $timeStr';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday · $timeStr';
    }

    // Default formatting
    return '${date.day} $monthStr ${date.year} · $timeStr';
  }
}
