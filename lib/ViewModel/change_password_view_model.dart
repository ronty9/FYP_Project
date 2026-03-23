// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordViewModel extends ChangeNotifier {
  // Text Controllers
  final TextEditingController currentPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  // Visibility States (to toggle the "eye" icon)
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  bool isLoading = false;

  // --- Toggles for Password Visibility ---
  void toggleCurrentVisibility() {
    obscureCurrent = !obscureCurrent;
    notifyListeners();
  }

  void toggleNewVisibility() {
    obscureNew = !obscureNew;
    notifyListeners();
  }

  void toggleConfirmVisibility() {
    obscureConfirm = !obscureConfirm;
    notifyListeners();
  }

  // --- Real Firebase Logic to Update Password ---
  Future<void> updatePassword(BuildContext context) async {
    // 1. Basic Local Validation
    if (currentPassController.text.isEmpty ||
        newPassController.text.isEmpty ||
        confirmPassController.text.isEmpty) {
      _showSnackBar(context, 'Please fill in all fields.', isError: true);
      return;
    }

    // ⭐ NEW LOGIC: Prevent using the same password ⭐
    if (newPassController.text == currentPassController.text) {
      _showSnackBar(
        context,
        'New password must be different from the current password.',
        isError: true,
      );
      return;
    }

    if (newPassController.text != confirmPassController.text) {
      _showSnackBar(context, 'New passwords do not match.', isError: true);
      return;
    }

    if (newPassController.text.length < 6) {
      _showSnackBar(
        context,
        'Password must be at least 6 characters.',
        isError: true,
      );
      return;
    }

    // 2. Start Loading State
    isLoading = true;
    notifyListeners();

    try {
      // Get the currently logged in user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && user.email != null) {
        // 3. Re-authenticate the user with their CURRENT password
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassController.text,
        );

        await user.reauthenticateWithCredential(credential);

        // 4. If re-auth is successful, update to the NEW password
        await user.updatePassword(newPassController.text);

        // 5. Success Feedback & Navigation
        isLoading = false;
        notifyListeners();

        if (context.mounted) {
          _showSnackBar(context, 'Password updated successfully!');
          Navigator.pop(context); // Go back to profile screen
        }
      } else {
        throw Exception("No user logged in.");
      }
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();

      // Handle specific Firebase errors
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        errorMessage = 'Your current password is incorrect.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Your new password is too weak.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage =
            'Please log out and log in again to change your password.';
      }

      if (context.mounted) {
        _showSnackBar(context, errorMessage, isError: true);
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      if (context.mounted) {
        _showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    currentPassController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }
}
