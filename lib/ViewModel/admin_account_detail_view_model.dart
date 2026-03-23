// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_view_model.dart';
import '../models/user_account.dart';
import '../Services/activity_service.dart'; // <--- Import ActivityService

class AdminAccountDetailViewModel extends BaseViewModel {
  UserAccount? _user;
  bool _isAccountLocked = false;
  String _accountStatus = 'Active';

  UserAccount? get user => _user;
  bool get isAccountLocked => _isAccountLocked;
  String get accountStatus => _accountStatus;

  void initialize(UserAccount user) {
    _user = user;
    // Check if status matches 'Suspended' (case insensitive safety)
    _isAccountLocked = user.status.toLowerCase() == 'suspended';
    _accountStatus = user.status;
    notifyListeners();
  }

  void onBackPressed(BuildContext context) {
    Navigator.pop(context);
  }

  // --- SUSPEND / UNLOCK ACCOUNT ---
  Future<void> toggleAccountLock(BuildContext context) async {
    if (_user == null) return;

    // 1. Determine the new status
    final newStatus = _isAccountLocked ? 'Active' : 'Suspended';
    final actionName = _isAccountLocked
        ? 'Account Unlocked'
        : 'Account Suspended';

    // 2. Optimistic Update
    _isAccountLocked = !_isAccountLocked;
    _accountStatus = newStatus;
    _user = _user!.copyWith(status: newStatus);
    notifyListeners();

    try {
      // 3. Update Firestore
      await FirebaseFirestore.instance.collection('user').doc(_user!.id).update(
        {'accountStatus': newStatus},
      );

      // 4. Log the activity using Service
      await ActivityService.log(
        action: actionName,
        description: 'Admin changed status of ${_user!.name} to $newStatus',
        actorName: 'Admin',
        type: newStatus == 'Suspended' ? 'WARNING' : 'INFO',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account $newStatus successfully'),
            backgroundColor: newStatus == 'Suspended'
                ? Colors.orange
                : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 5. Revert changes if error occurs
      _isAccountLocked = !_isAccountLocked;
      _accountStatus = _isAccountLocked ? 'Suspended' : 'Active';
      _user = _user!.copyWith(status: _accountStatus);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  // --- DELETE ACCOUNT ---
  Future<void> deleteAccount(BuildContext context) async {
    if (_user == null) return;

    try {
      final userId = _user!.id;
      final userName = _user!.name;

      // Log activity before deletion using Service
      await ActivityService.log(
        action: 'Account Deleted',
        description: 'User account deleted: $userName (ID: $userId)',
        actorName: 'Admin',
        type: 'CRITICAL',
      );

      // Delete from Firestore
      await FirebaseFirestore.instance.collection('user').doc(userId).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
        // Go back to the Manage Accounts list
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close page
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
      }
    }
  }

  // --- DIALOGS ---
  void showOptionsMenu(BuildContext context) {
    if (_user == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Send Email'),
              onTap: () {
                Navigator.pop(ctx);
                // Email logic here
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Activity Log'),
              onTap: () {
                Navigator.pop(ctx);
                viewActivityLog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void showSuspendDialog(BuildContext context) {
    if (_user == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.block_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Suspend Account'),
          ],
        ),
        content: Text(
          'Are you sure you want to suspend ${_user!.name}\'s account? They will not be able to login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              toggleAccountLock(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteAccount(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void showLockConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _isAccountLocked ? Icons.lock_open : Icons.block,
              color: _isAccountLocked ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(_isAccountLocked ? 'Unlock Account' : 'Suspend Account'),
          ],
        ),
        content: Text(
          _isAccountLocked
              ? 'Are you sure you want to unlock this account? They will be able to login again.'
              : 'Are you sure you want to suspend this account? They will NOT be able to login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              toggleAccountLock(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAccountLocked ? Colors.green : Colors.orange,
            ),
            child: Text(_isAccountLocked ? 'Unlock' : 'Suspend'),
          ),
        ],
      ),
    );
  }

  // This one still queries the specific user activity, separate from the main system log
  Future<void> viewActivityLog(BuildContext context) async {
    if (_user == null) return;

    try {
      // You might want to update this query to also pull from 'system_activity_logs'
      // if that's where you want to keep ALL records now.
      // For now, I'm keeping your existing logic here for specific user logs.
      final logs = await FirebaseFirestore.instance
          .collection('admin_activity_logs')
          .where('userId', isEqualTo: _user!.id)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text('Activity Log - ${_user!.name}')),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: logs.docs.isEmpty
                  ? const Center(
                      child: Text(
                        'No activity recorded yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: logs.docs.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, index) {
                        final log = logs.docs[index].data();
                        final timestamp = log['timestamp'] as Timestamp?;
                        final date = timestamp?.toDate();
                        final dateStr = date != null
                            ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
                            : 'N/A';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.info_outline, size: 20),
                          ),
                          title: Text(
                            log['action'] ?? 'Unknown Action',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log['description'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading activity log: $e')),
        );
      }
    }
  }
}
