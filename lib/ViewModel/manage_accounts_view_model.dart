// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'base_view_model.dart';
import '../models/user_account.dart';

class ManageAccountsViewModel extends BaseViewModel {
  // Master list (All data from DB)
  List<UserAccount> _allUsers = [];

  // Filtered list (What is shown in the list below)
  List<UserAccount> _filteredUsers = [];

  bool _isLoading = true;

  // --- Getters for UI ---
  List<UserAccount> get users => _filteredUsers;
  @override
  bool get isLoading => _isLoading;

  // Stats Getters
  int get totalUsersCount => _allUsers.length;

  int get activeUsersCount {
    return _allUsers.where((user) {
      return user.status == 'Active';
    }).length;
  }

  ManageAccountsViewModel() {
    fetchUsers();
  }

  // --- Fetch Users ---
  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user')
          .orderBy('dateCreated', descending: true)
          .get();

      // Store raw data
      _allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return UserAccount(
          id: doc.id,
          name: (data['userName'] ?? 'User').toString(),
          email: (data['userEmail'] ?? '').toString(),
          joinDate: _formatJoinDate(data['dateCreated']),
          status: (data['accountStatus'] ?? 'Active')
              .toString(), // Ensure this matches DB field
          phone: data['userPhone']?.toString(),
          petsCount: data['petsCount'] is int ? data['petsCount'] as int : 0,
        );
      }).toList();

      // Initialize filtered list with everything
      _filteredUsers = List.from(_allUsers);
    } catch (e) {
      debugPrint("Error fetching users: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Search Logic ---
  void searchUsers(String query) {
    if (query.isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredUsers = _allUsers.where((user) {
        final name = user.name.toLowerCase();
        final email = user.email.toLowerCase();
        return name.contains(lowerQuery) || email.contains(lowerQuery);
      }).toList();
    }
    notifyListeners();
  }

  // --- Delete Logic ---
  void confirmDeleteUser(BuildContext context, UserAccount user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteUser(context, user);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(BuildContext context, UserAccount user) async {
    try {
      await FirebaseFirestore.instance.collection('user').doc(user.id).delete();

      _allUsers.removeWhere((u) => u.id == user.id);
      _filteredUsers.removeWhere((u) => u.id == user.id);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  void onBackPressed(BuildContext context) {
    Navigator.pop(context);
  }

  // --- CRITICAL FIX: Refresh List on Return ---
  Future<void> onUserCardTapped(BuildContext context, UserAccount user) async {
    // 1. Wait until the Detail Page is closed (popped)
    await Navigator.pushNamed(
      context,
      '/admin/account-detail',
      arguments: user,
    );

    // 2. RE-FETCH DATA IMMEDIATELY
    // This will pull the new 'Suspended' status from Firebase and update the UI
    fetchUsers();
  }

  String _formatJoinDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd MMM yyyy').format(value.toDate());
    }
    if (value is DateTime) {
      return DateFormat('dd MMM yyyy').format(value);
    }
    return 'Unknown';
  }
}
