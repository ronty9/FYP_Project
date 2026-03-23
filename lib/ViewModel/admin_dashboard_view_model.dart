// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_view_model.dart';
import '../View/activity_log_view.dart';

class AdminDashboardViewModel extends BaseViewModel {
  int _userCount = 0;
  int _scanCount = 0;
  bool _isLoadingStats = true;

  int get userCount => _userCount;
  int get scanCount => _scanCount;
  bool get isLoadingStats => _isLoadingStats;

  // Constructor: Fetch stats immediately when initialized
  AdminDashboardViewModel() {
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      // 1. Count Users
      final userSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .count()
          .get();

      _userCount = userSnapshot.count ?? 0;

      // 2. Count Total Scans from ScanHistory collection
      final scanSnapshot = await FirebaseFirestore.instance
          .collection('ScanHistory')
          .count()
          .get();

      _scanCount = scanSnapshot.count ?? 0;
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }

    _isLoadingStats = false;
    notifyListeners();
  }

  // -- Navigation Methods --
  void onManageAccountsPressed(BuildContext context) {
    Navigator.pushNamed(context, '/manage_accounts').then((_) => _fetchStats());
  }

  void onAnalysisRecordsPressed(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/analysis_records',
    ).then((_) => _fetchStats());
  }

  void onUserFeedbackPressed(BuildContext context) {
    Navigator.pushNamed(context, '/admin_feedback_list');
  }

  void onManageFaqPressed(BuildContext context) {
    Navigator.pushNamed(context, '/manage_faq');
  }

  void onManageCommunityTipsPressed(BuildContext context) {
    Navigator.pushNamed(context, '/manage_community_tips');
  }

  void onLogoutPressed(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // MOVING THIS INSIDE THE CLASS
  void onViewAllActivityPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActivityLogView()),
    );
  }
} // <-- This is the end of the class now
