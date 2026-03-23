// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/activity_service.dart'; // <--- Import the Logging Service

// --- 1. The Model (Inside the ViewModel file as requested) ---
class CommunityTip {
  final String id; // This corresponds to communityId (e.g., CT000001)
  final String category;
  final String title;
  final String description;
  final DateTime createdAt;

  CommunityTip({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  // Factory to convert Firestore Document to Dart Object
  factory CommunityTip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityTip(
      id: doc.id,
      category: data['tipsCategory'] ?? 'General',
      title: data['tipsTitle'] ?? '',
      description: data['tipsDesc'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// --- 2. The ViewModel ---
class AdminManageCommunityTipsViewModel extends ChangeNotifier {
  List<CommunityTip> _tips = [];
  bool _isLoading = true;

  List<CommunityTip> get tips => _tips;
  bool get isLoading => _isLoading;

  AdminManageCommunityTipsViewModel() {
    fetchTips();
  }

  // --- Fetch Tips ---
  Future<void> fetchTips() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('community_tips')
          .orderBy('createdAt', descending: true)
          .get();

      _tips = snapshot.docs
          .map((doc) => CommunityTip.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("Error fetching tips: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Add Tip (Transaction for CT000001) ---
  Future<void> addTip(
    BuildContext context,
    String category,
    String title,
    String desc,
  ) async {
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    final firestore = FirebaseFirestore.instance;
    final counterRef = firestore
        .collection('counters')
        .doc('communityTipsCounter');

    try {
      String newId = ''; // To store the generated ID

      await firestore.runTransaction((transaction) async {
        // A. Read the current count
        DocumentSnapshot counterSnapshot = await transaction.get(counterRef);
        int currentCount = 0;

        if (counterSnapshot.exists) {
          final data = counterSnapshot.data() as Map<String, dynamic>;
          currentCount = data['count'] ?? 0;
        }

        // B. Generate New ID (Increment and Format)
        int newCount = currentCount + 1;
        newId = 'CT${newCount.toString().padLeft(6, '0')}';

        // C. Reference for the new tip
        final tipRef = firestore.collection('community_tips').doc(newId);

        // D. Write to DB
        transaction.set(counterRef, {'count': newCount});
        transaction.set(tipRef, {
          'communityId': newId,
          'tipsCategory': category,
          'tipsTitle': title,
          'tipsDesc': desc,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // --- LOG ACTIVITY ---
      await ActivityService.log(
        action: 'Community Tip Added',
        description:
            'New tip "$title" added to $category category (ID: $newId)',
        actorName: 'Admin',
        type: 'INFO',
      );

      // Refresh local list
      await fetchTips();

      if (context.mounted) {
        Navigator.pop(context); // Close the bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tip added successfully!')),
        );
      }
    } catch (e) {
      debugPrint("Error adding tip: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding tip: $e')));
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Edit Tip ---
  Future<void> updateTip(
    BuildContext context,
    String id,
    String category,
    String title,
    String desc,
  ) async {
    if (title.isEmpty || desc.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('community_tips')
          .doc(id)
          .update({
            'tipsCategory': category,
            'tipsTitle': title,
            'tipsDesc': desc,
          });

      // --- LOG ACTIVITY ---
      await ActivityService.log(
        action: 'Community Tip Updated',
        description: 'Tip "$title" (ID: $id) was modified',
        actorName: 'Admin',
        type: 'INFO',
      );

      await fetchTips();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tip updated successfully!')),
        );
      }
    } catch (e) {
      debugPrint("Error updating tip: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating tip: $e')));
      }
    }
  }

  // --- Delete Tip ---
  Future<void> deleteTip(BuildContext context, String id) async {
    try {
      // Find the tip title before deleting for the log
      final tipToDelete = _tips.firstWhere(
        (t) => t.id == id,
        orElse: () => CommunityTip(
          id: '',
          category: '',
          title: 'Unknown',
          description: '',
          createdAt: DateTime.now(),
        ),
      );
      final title = tipToDelete.title;

      await FirebaseFirestore.instance
          .collection('community_tips')
          .doc(id)
          .delete();

      // --- LOG ACTIVITY ---
      await ActivityService.log(
        action: 'Community Tip Deleted',
        description: 'Tip "$title" (ID: $id) was removed',
        actorName: 'Admin',
        type: 'CRITICAL', // Red color for deletions
      );

      // Update local list instantly for better UX
      _tips.removeWhere((t) => t.id == id);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tip deleted successfully')),
        );
      }
    } catch (e) {
      debugPrint("Error deleting tip: $e");
    }
  }
}
