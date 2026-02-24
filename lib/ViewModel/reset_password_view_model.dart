import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // 1. Find User in Firestore to verify they exist
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('userEmail', isEqualTo: _email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        isLoading = false;
        errorMessage = 'User not found.';
        notifyListeners();
        return;
      }

      final docId = querySnapshot.docs.first.id;
      final newPassword = newPasswordController.text;

      // 2. Store the new password temporarily (for manual update via reset link)
      // In production, you should hash this and use Cloud Functions
      await FirebaseFirestore.instance
          .collection('pending_password_resets')
          .doc(docId)
          .set({
            'email': _email,
            'requestedPassword':
                newPassword, // Store securely/hash in production!
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': DateTime.now().add(const Duration(hours: 1)),
            'used': false,
            'verifiedViaOTP': true,
          });

      // 3. Send Firebase Auth password reset email
      // User will click this link to complete the password reset
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);

      isLoading = false;
      notifyListeners();

      if (context.mounted) {
        // Show success message with instructions
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 64,
            ),
            title: const Text(
              'Almost Done!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'We\'ve sent a password reset link to $_email.\n\n'
              'Please check your email and click the link to complete '
              'your password reset.\n\n'
              'After clicking the link, you can sign in with your new password.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Navigate back to login screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Back to Login',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to initiate password reset: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
