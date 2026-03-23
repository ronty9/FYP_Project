// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'base_view_model.dart';

class AnalysisRecordViewModel extends BaseViewModel {
  // Dummy data representing scans from various users
  final List<AnalysisRecord> _records = [
    AnalysisRecord(
      id: 'rec_001',
      userName: 'John Doe',
      userEmail: 'john@example.com',
      scanType: 'Skin Disease',
      result: 'Ringworm',
      confidence: 0.94, // 94%
      date: '2025-01-26 10:30 AM',
      imageUrl: 'assets/images/cat_skin_1.jpg', // Placeholder path
    ),
    AnalysisRecord(
      id: 'rec_002',
      userName: 'Jane Smith',
      userEmail: 'jane@test.com',
      scanType: 'Breed',
      result: 'Golden Retriever',
      confidence: 0.88, // 88%
      date: '2025-01-25 04:15 PM',
      imageUrl: 'assets/images/dog_breed_1.jpg',
    ),
    AnalysisRecord(
      id: 'rec_003',
      userName: 'Mike Ross',
      userEmail: 'mike@law.com',
      scanType: 'Skin Disease',
      result: 'Healthy / No Issues',
      confidence: 0.99,
      date: '2025-01-24 09:00 AM',
      imageUrl: 'assets/images/dog_skin_1.jpg',
    ),
  ];

  List<AnalysisRecord> get records => List.unmodifiable(_records);

  // Navigate to details
  void openRecordDetail(BuildContext context, AnalysisRecord record) {
    Navigator.pushNamed(context, '/analysis_record_detail', arguments: record);
  }

  // Delete a record (e.g., inappropriate image or test data)
  void deleteRecord(BuildContext context, AnalysisRecord record) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _performDelete(context, record);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performDelete(BuildContext context, AnalysisRecord record) {
    _records.remove(record);
    notifyListeners();
    // If we are in the detail view, we might want to pop back
    // Check if the current route is the detail view before popping?
    // For simplicity, we assume this is called from List or Details.
    // If called from Detail View, we should pop.
  }
}

class AnalysisRecord {
  final String id;
  final String userName;
  final String userEmail;
  final String scanType; // 'Breed' or 'Skin Disease'
  final String result;
  final double confidence; // 0.0 to 1.0
  final String date;
  final String imageUrl; // In real app, this is a URL

  AnalysisRecord({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.scanType,
    required this.result,
    required this.confidence,
    required this.date,
    required this.imageUrl,
  });
}
