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
  // --- State Variables ---
  String _userName = 'Loading...';
  String _email = '';
  String? _profileImageUrl;

  int _totalPets = 0;
  int _totalScans = 0;
  int _daysActive = 0;

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

    // 2. Calculate Days Active (Based on Auth creation time)
    if (authUser.metadata.creationTime != null) {
      final difference = DateTime.now().difference(
        authUser.metadata.creationTime!,
      );
      // If they just created the account today, show 1 day instead of 0
      _daysActive = difference.inDays == 0 ? 1 : difference.inDays;
    }

    try {
      // 3. Fetch User Details from Firestore
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

        // 4. Fetch Total Pets Count (Using count() is faster and cheaper)
        final petsSnapshot = await FirebaseFirestore.instance
            .collection(
              'pet',
            ) // Using singular 'pet' based on your previous code
            .where('userId', isEqualTo: customUserId)
            .count()
            .get();
        _totalPets = petsSnapshot.count ?? 0;
      }

      // 5. Fetch Total Scans Count
      // The ScanHistory collection uses the Auth UID (authUser.uid)
      final scansSnapshot = await FirebaseFirestore.instance
          .collection('ScanHistory')
          .where('userId', isEqualTo: authUser.uid)
          .count()
          .get();
      _totalScans = scansSnapshot.count ?? 0;
    } catch (e) {
      debugPrint("Error fetching profile data: $e");
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
