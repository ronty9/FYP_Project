// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscureNew = true;
  bool obscureConfirm = true;
  bool isLoading = false;
  String? errorMessage;

  late String _email;

  void initialize(String email) {
    _email = email;
  }

  void toggleNewVisibility() {
    obscureNew = !obscureNew;
    notifyListeners();
  }

  void toggleConfirmVisibility() {
    obscureConfirm = !obscureConfirm;
    notifyListeners();
  }

  Future<void> resetPassword(BuildContext context) async {
    errorMessage = null;
    notifyListeners();

    if (newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      errorMessage = 'Please enter all fields.';
      notifyListeners();
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      errorMessage = 'Passwords do not match.';
      notifyListeners();
      return;
    }

    if (newPasswordController.text.length < 6) {
      errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      // Call the Firebase Cloud Function instead of the local backend
      final callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('resetPassword');

      await callable.call<dynamic>({
        'email': _email,
        'newPassword': newPasswordController.text,
      });

      isLoading = false;
      notifyListeners();

      if (context.mounted) {
        _showSuccessDialog(context);
      }
    } on FirebaseFunctionsException catch (e) {
      isLoading = false;

      // Map Cloud Function error codes to user-friendly messages
      switch (e.code) {
        case 'not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'invalid-argument':
          errorMessage = e.message ?? 'Invalid input. Please check your data.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to reset password.';
      }

      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Could not reach the server. Please check your internet '
          'connection and try again.';
      notifyListeners();
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 64,
        ),
        title: const Text(
          'Password Reset!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your password has been updated successfully. '
          'Please sign in with your new password.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
