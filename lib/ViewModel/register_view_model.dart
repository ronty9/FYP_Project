// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Ensure you have this package: flutter pub add intl
import '../services/otp_service.dart';
import '../View/otp_verification_view.dart';
import 'base_view_model.dart';

class RegisterViewModel extends BaseViewModel {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController dateOfBirthController =
      TextEditingController(); // NEW

  DateTime? _selectedDate; // To store the actual date object

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get errorMessage => _errorMessage;

  // --- Visibility Toggles ---
  void onTogglePasswordPressed() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void onToggleConfirmPressed() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  // --- Date Picker Logic (NEW) ---
  Future<void> onDateOfBirthPressed(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      // Format the date for display (e.g., 2023-10-25)
      dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      notifyListeners();
    }
  }

  // --- Registration Logic ---
  Future<void> onRegisterPressed(BuildContext context) async {
    final validationError = _validateInputs();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Send OTP to user's email
      final otpService = OtpService();
      final otpSent = await otpService.sendOTP(
        emailController.text.trim(),
        nameController.text.trim(),
      );

      _isLoading = false;
      notifyListeners();

      if (otpSent != null) {
        // Navigate to OTP verification screen
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationView(
                email: emailController.text.trim(),
                userName: nameController.text.trim(),
                onVerificationSuccess: (context) =>
                    _completeRegistration(context),
              ),
            ),
          );
        }
      } else {
        _errorMessage = 'Failed to send verification code. Please try again.';
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
    }
  }

  // Complete registration after OTP verification
  Future<void> _completeRegistration(BuildContext context) async {
    try {
      // 1. Create Auth User
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      // 2. Create Firestore Entry
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!.uid);

        if (context.mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to login
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_handleAuthError(e)),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context); // Go back to register screen
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context); // Go back to register screen
      }
    }
  }

  Future<void> _saveUserToFirestore(String authUid) async {
    final firestore = FirebaseFirestore.instance;

    // Using a transaction to generate the custom ID (U000001)
    final counterRef = firestore.collection('counters').doc('userCounter');

    await firestore.runTransaction((transaction) async {
      DocumentSnapshot counterSnapshot = await transaction.get(counterRef);

      int currentCount = 0;
      if (counterSnapshot.exists) {
        currentCount = counterSnapshot.get('count') as int;
      }

      int newCount = currentCount + 1;
      String customUserId = 'U${newCount.toString().padLeft(6, '0')}';
      final userDocRef = firestore.collection('user').doc(customUserId);

      final userData = {
        'userName': usernameController.text.trim(),
        'userEmail': emailController.text.trim(),
        'password_hash': 'SECURED_IN_FIREBASE_AUTH',
        'authProvider': 'email',
        'providerId': authUid,
        'userRole': 'User',
        'accountStatus': 'Active',
        'dateCreated': FieldValue.serverTimestamp(),
        // NEW: Saving the date of birth
        'dateOfBirth': _selectedDate != null
            ? Timestamp.fromDate(_selectedDate!)
            : null,
      };

      transaction.set(counterRef, {'count': newCount});
      transaction.set(userDocRef, userData);
    });
  }

  void onGoToLoginPressed(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String? _validateInputs() {
    if (usernameController.text.isEmpty ||
        nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        dateOfBirthController.text.isEmpty || // NEW Validation
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      return 'All fields are required.';
    }
    if (passwordController.text.length < 6) {
      return 'Password should be at least 6 characters long.';
    }
    if (passwordController.text != confirmPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    dateOfBirthController.dispose(); // Dispose new controller
    super.dispose();
  }
}
