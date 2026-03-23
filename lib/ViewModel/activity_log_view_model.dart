// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_view_model.dart';

class ActivityLogViewModel extends BaseViewModel {
  final List<String> filters = ['All', 'INFO', 'WARNING', 'CRITICAL'];

  String _selectedFilter = 'All';
  String get selectedFilter => _selectedFilter;

  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  // We change this to return a List of DocumentSnapshots that we filter locally!
  Stream<List<DocumentSnapshot>> get activityStream {
    return FirebaseFirestore.instance
        .collection('system_activity_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          // If 'All' is selected, return everything
          if (_selectedFilter == 'All') {
            return snapshot.docs;
          }
          // Otherwise, filter locally in Dart to avoid Firebase Index errors!
          return snapshot.docs.where((doc) {
            final data = doc.data();
            final type = data['type']?.toString() ?? 'INFO';
            return type == _selectedFilter;
          }).toList();
        });
  }
}
