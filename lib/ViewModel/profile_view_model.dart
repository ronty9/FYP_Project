import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../View/account_details_view.dart';
import '../View/feedback_view.dart';
import '../View/help_faq_view.dart';
import '../View/notification_settings_view.dart';
import '../View/privacy_security_view.dart';
import 'base_view_model.dart';

class ProfileViewModel extends BaseViewModel {
  // --- State Variables (Not Final anymore) ---
  String _userName = 'Loading...';
  String _email = '';
  String? _profileImageUrl;
  int _totalPets = 0;
  final int _totalScans = 0; // Placeholder until you have a 'scans' collection
  int _daysActive = 0; // Placeholder

  // --- Getters ---
  String get userName => _userName;
  String get email => _email;
  String? get profileImageUrl => _profileImageUrl;
  int get totalPets => _totalPets;
  int get totalScans => _totalScans;
  int get daysActive => _daysActive;

  // --- Constructor ---
  ProfileViewModel() {
    _fetchUserProfile();
  }

  // --- Fetch Data Logic ---
  Future<void> _fetchUserProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) {
      _userName = 'Guest';
      _email = 'No email';
      notifyListeners();
      return;
    }

    // 1. Set Email directly from Auth
    _email = authUser.email ?? 'No Email';

    // Calculate Days Active (Simple approximation based on creation time)
    if (authUser.metadata.creationTime != null) {
      final difference = DateTime.now().difference(
        authUser.metadata.creationTime!,
      );
      _daysActive = difference.inDays;
    }

    try {
      // 2. Fetch User Details from Firestore
      // We query the 'user' collection where 'providerId' matches the Auth UID
      final userSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('providerId', isEqualTo: authUser.uid)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final data = userSnapshot.docs.first.data();
        _userName = data['userName'] ?? 'User';
        _profileImageUrl = (data['profileImageUrl'] ?? data['photoUrl'])
            ?.toString();

        // Save the Custom User ID (e.g. U000001) for fetching pets
        final customUserId = userSnapshot.docs.first.id;

        // 3. Fetch Total Pets Count
        // Assuming you have a 'pets' collection where 'ownerId' or 'userId' links to the user
        final petsSnapshot = await FirebaseFirestore.instance
            .collection(
              'pets',
            ) // Change this if your collection is named differently
            .where('userId', isEqualTo: customUserId)
            .get();

        _totalPets = petsSnapshot.docs.length;
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      _userName = 'Error loading';
    }

    notifyListeners();
  }

  // --- Actions ---

  // Public method to refresh profile data
  Future<void> refreshProfile() async {
    await _fetchUserProfile();
  }

  void onEditProfilePressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile editing coming soon.')),
    );
  }

  Future<void> onAccountDetailsPressed(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountDetailsView()),
    );
    // Refresh profile data when returning from account details
    await refreshProfile();
  }

  void onNotificationsPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationSettingsView()),
    );
  }

  void onPrivacySecurityPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacySecurityView()),
    );
  }

  void onHelpPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpFaqView()),
    );
  }

  void onFeedbackPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackView()),
    );
  }

  // --- Logout Logic ---
  Future<void> onLogoutPressed(BuildContext context) async {
    try {
      // 1. Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // 2. Navigate back to Login Screen
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }
}
