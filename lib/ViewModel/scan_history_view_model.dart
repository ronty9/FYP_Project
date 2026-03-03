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

  // --- NEW: Separate Master List and Filtered List ---
  List<ScanHistoryItem> _allHistory = [];
  List<ScanHistoryItem> _filteredHistory = [];

  // Active filter states
  DateTime? activeFilterDate;
  ScanType? activeFilterType;

  // The UI will now listen to the FILTERED list
  List<ScanHistoryItem> get history => List.unmodifiable(_filteredHistory);
  bool get hasHistory => _filteredHistory.isNotEmpty;

  // --- FETCH DATA FROM FIREBASE ---
  void _fetchHistoryFromFirebase() {
    runAsync(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("DEBUG: No user is currently logged in!");
        return;
      }

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('ScanHistory')
            .where('userId', isEqualTo: user.uid)
            .get();

        final fetchedList = snapshot.docs.map((doc) {
          final data = doc.data();

          final scanTypeStr = data['scanType'] as String?;
          final type = scanTypeStr == 'breed'
              ? ScanType.breed
              : ScanType.skinDisease;

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

        // Sort the master list locally (Newest first)
        fetchedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Save to master list and apply any active filters
        _allHistory = fetchedList;
        applyFilters(date: activeFilterDate, type: activeFilterType);

        print("DEBUG: Successfully fetched ${_allHistory.length} records.");
      } catch (e) {
        print("DEBUG: Error fetching scan history: $e");
      }
    });
  }

  // --- NEW: FILTER LOGIC ---
  void applyFilters({DateTime? date, ScanType? type, bool clear = false}) {
    if (clear) {
      activeFilterDate = null;
      activeFilterType = null;
      _filteredHistory = List.from(_allHistory); // Reset to show all
    } else {
      activeFilterDate = date;
      activeFilterType = type;

      _filteredHistory = _allHistory.where((item) {
        bool matchesDate = true;
        bool matchesType = true;

        // Check Date Match
        if (activeFilterDate != null) {
          matchesDate =
              item.timestamp.year == activeFilterDate!.year &&
              item.timestamp.month == activeFilterDate!.month &&
              item.timestamp.day == activeFilterDate!.day;
        }

        // Check Type Match
        if (activeFilterType != null) {
          matchesType = item.type == activeFilterType;
        }

        return matchesDate && matchesType;
      }).toList();
    }

    notifyListeners();
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

    int hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    String period = date.hour >= 12 ? 'PM' : 'AM';
    String minute = date.minute.toString().padLeft(2, '0');
    String timeStr = '$hour:$minute $period';

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

    return '${date.day} $monthStr ${date.year} · $timeStr';
  }
}
