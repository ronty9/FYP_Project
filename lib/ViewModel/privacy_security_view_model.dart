import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth

import 'base_view_model.dart';
import '../View/privacy_policy_view.dart';

class PrivacySecurityViewModel extends BaseViewModel {
  bool _isGoogleSignIn = false;
  bool get isGoogleSignIn => _isGoogleSignIn;

  PrivacySecurityViewModel() {
    _checkLoginProvider();
  }

  void _checkLoginProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if any of the linked providers is Google
      for (var userInfo in user.providerData) {
        if (userInfo.providerId == 'google.com') {
          _isGoogleSignIn = true;
          break;
        }
      }
      notifyListeners();
    }
  }

  void onChangePasswordPressed(BuildContext context) {
    if (_isGoogleSignIn) {
      _showSnack(
        context,
        'You logged in with Google. Passwords are managed via your Google account.',
      );
      return;
    }
    Navigator.pushNamed(context, '/change_password');
  }

  void manageSessions(BuildContext context) {
    _showSnack(context, 'Login session management coming soon.');
  }

  void openPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyView()),
    );
  }

  void deleteAccount(BuildContext context) {
    _showSnack(
      context,
      'Account deletion is handled via support. Please contact support for assistance.',
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
