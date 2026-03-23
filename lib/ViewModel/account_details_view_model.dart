// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'base_view_model.dart';

class AccountDetailsViewModel extends BaseViewModel {
  // --- Controllers ---
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController nameController =
      TextEditingController(); // For Full Name
  final TextEditingController emailController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _currentImageUrl;

  // --- State Variables ---
  bool _isLoading = false;
  String? _docId; // To store the Firestore Document ID (e.g., U00001)

  @override
  bool get isLoading => _isLoading;

  File? get selectedImage => _selectedImage;
  String? get currentImageUrl => _currentImageUrl;

  // --- Constructor ---
  AccountDetailsViewModel() {
    _loadUserData();
  }

  // --- 1. Load User Data ---
  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Find the user document in Firestore based on Auth UID
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('providerId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();

        _docId = doc.id; // Save ID for updating later

        // Populate Controllers
        userNameController.text = data['userName'] ?? '';
        nameController.text =
            data['fullName'] ?? ''; // Assuming 'fullName' key exists
        emailController.text = data['userEmail'] ?? '';
        _currentImageUrl = (data['profileImageUrl'] ?? data['photoUrl'])
            ?.toString();
      }
    } catch (e) {
      debugPrint("Error loading account details: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- 2. Save Changes ---
  void onSaveChangesPressed(BuildContext context) {
    if (_docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User profile not found.')),
      );
      return;
    }

    _updateUserProfile(context);
  }

  Future<void> _updateUserProfile(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        throw Exception('User not authenticated.');
      }

      String? newProfileImageUrl = _currentImageUrl;

      // Upload profile image to Firebase Storage if a new image was selected
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${authUser.uid}_profile.jpg');

        await storageRef
            .putFile(_selectedImage!)
            .timeout(const Duration(seconds: 60));

        newProfileImageUrl = await storageRef.getDownloadURL().timeout(
          const Duration(seconds: 10),
        );
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection('user').doc(_docId).update({
        'userName': userNameController.text.trim(),
        'fullName': nameController.text.trim(),
        'userEmail': emailController.text.trim(),
        if (newProfileImageUrl != null) 'profileImageUrl': newProfileImageUrl,
        // Note: We are NOT updating the Firebase Auth email here to avoid re-authentication flows.
        // We are only updating the database record.
      });

      // Update local state with the new image URL
      if (newProfileImageUrl != null) {
        _currentImageUrl = newProfileImageUrl;
      }
      _selectedImage = null; // Clear selected image after successful upload

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  Future<void> pickImage(BuildContext context) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile == null) {
        return;
      }
      _selectedImage = File(pickedFile.path);
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  @override
  void dispose() {
    userNameController.dispose();
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
