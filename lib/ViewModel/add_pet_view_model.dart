// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/pet_info.dart';
import 'base_view_model.dart';

class AddPetViewModel extends BaseViewModel {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController colourController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  final List<String> speciesOptions = const ['Dog', 'Cat'];
  final List<String> genderOptions = const ['Male', 'Female', 'Unknown'];
  String _species = 'Dog';
  String _gender = 'Male';

  // --- NEW STATE: Holds the selected image file ---
  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  final List<File> _galleryImages = [];
  List<File> get galleryImages => List.unmodifiable(_galleryImages);

  String get species => _species;
  String get gender => _gender;

  List<BreedOption> _breeds = [];
  bool _isBreedsLoading = false;
  BreedOption? _selectedBreed;

  List<BreedOption> get breeds => _breeds;
  bool get isBreedsLoading => _isBreedsLoading;
  BreedOption? get selectedBreed => _selectedBreed;
  List<BreedOption> get filteredBreeds =>
      _breeds.where((b) => b.species == _species).toList();

  AddPetViewModel() {
    _loadBreeds();
  }

  void selectSpecies(String value) {
    if (_species == value) {
      return;
    }
    _species = value;
    if (_selectedBreed != null && _selectedBreed!.species != value) {
      _selectedBreed = null;
    }
    notifyListeners();
  }

  void selectGender(String value) {
    if (_gender == value) return;
    _gender = value;
    notifyListeners();
  }

  void selectBreed(BreedOption? value) {
    _selectedBreed = value;
    notifyListeners();
  }

  // --- Image selection ---
  Future<void> pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (pickedFile == null) return;
    _selectedImage = File(pickedFile.path);
    final bytes = await _selectedImage!.length();
    debugPrint('Selected image size: ${bytes ~/ 1024} KB');
    notifyListeners();
  }

  Future<void> pickGalleryImages(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (pickedFiles.isEmpty) return;
    _galleryImages
      ..clear()
      ..addAll(pickedFiles.map((file) => File(file.path)));
    notifyListeners();
  }

  Future<void> pickDateOfBirth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(1990),
      lastDate: now,
    );

    if (picked == null) return;
    dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
    notifyListeners();
  }

  Future<void> savePet(BuildContext context) async {
    final formState = formKey.currentState;
    if (formState == null || !formState.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }
    if (_selectedBreed == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a breed.')));
      return;
    }
    final weightKg = double.tryParse(weightController.text.trim());
    if (weightKg == null || weightKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight.')),
      );
      return;
    }

    setLoading(true);
    setError(null);
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving pet...'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
      final userId = await _resolveUserId();
      if (userId == null || userId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found. Please log in again.'),
            ),
          );
        }
        return;
      }

      final dateOfBirth = DateTime.tryParse(dateOfBirthController.text.trim());
      if (dateOfBirth == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a valid date of birth.'),
            ),
          );
        }
        return;
      }

      final result = await _createPet(
        userId: userId,
        dateOfBirth: dateOfBirth,
        weightKg: weightKg,
      );

      if (!context.mounted || result == null) return;
      Navigator.pop(context, result);
    } catch (error) {
      setError(error.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save pet: $error')));
      }
    } finally {
      setLoading(false);
    }
  }

  Future<PetInfo?> _createPet({
    required String userId,
    required DateTime dateOfBirth,
    required double weightKg,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('pet').doc();
    String? photoUrl;
    final List<String> photoUrls = [];

    if (_selectedImage != null) {
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      debugPrint('Storage upload auth uid: $authUid');
      if (authUid == null) {
        throw Exception('User not authenticated for photo upload.');
      }
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('pets')
          .child(authUid)
          .child('${docRef.id}.jpg');
      try {
        final uploadTask = storageRef.putFile(_selectedImage!);
        uploadTask.snapshotEvents.listen((event) {
          final total = event.totalBytes;
          final transferred = event.bytesTransferred;
          if (total > 0) {
            final pct = (transferred / total * 100).toStringAsFixed(0);
            debugPrint('Upload progress: $pct%');
          }
        });
        await uploadTask.timeout(const Duration(seconds: 60));
        photoUrl = await storageRef.getDownloadURL().timeout(
          const Duration(seconds: 10),
        );
      } on FirebaseException catch (error) {
        throw Exception('Photo upload failed: ${error.code}');
      } on TimeoutException {
        throw Exception('Photo upload timed out. Please try again.');
      }
    }

    if (_galleryImages.isNotEmpty) {
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      if (authUid == null) {
        throw Exception('User not authenticated for photo upload.');
      }
      for (int index = 0; index < _galleryImages.length; index++) {
        final imageFile = _galleryImages[index];
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('pets')
            .child(authUid)
            .child(docRef.id)
            .child('gallery_$index.jpg');
        try {
          await storageRef
              .putFile(imageFile)
              .timeout(const Duration(seconds: 60));
          final url = await storageRef.getDownloadURL().timeout(
            const Duration(seconds: 10),
          );
          photoUrls.add(url);
        } on FirebaseException catch (error) {
          throw Exception('Gallery upload failed: ${error.code}');
        } on TimeoutException {
          throw Exception('Gallery upload timed out. Please try again.');
        }
      }
    }

    await docRef.set({
      'petId': docRef.id,
      'petName': nameController.text.trim(),
      'species': _species,
      'gender': _gender,
      'colour': colourController.text.trim(),
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'breedId': _selectedBreed?.id,
      'userId': userId,
      'photoUrl': photoUrl,
      'photoUrls': photoUrls,
      'weightKg': weightKg,
    });

    return PetInfo(
      id: docRef.id,
      name: nameController.text.trim(),
      species: _species,
      gender: _gender,
      colour: colourController.text.trim(),
      dateOfBirth: dateOfBirth,
      breed: _selectedBreed?.name ?? '',
      breedId: _selectedBreed?.id,
      userId: userId,
      photoUrl: photoUrl,
      photoUrls: photoUrls,
      weightKg: weightKg,
      age: _formatAge(dateOfBirth),
    );
  }

  Future<String?> _resolveUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('providerId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  }

  Future<void> _loadBreeds() async {
    _isBreedsLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('breed')
          .get();
      _breeds = snapshot.docs
          .map((doc) => BreedOption.fromMap(doc.id, doc.data()))
          .toList();
      _breeds.sort((a, b) => a.name.compareTo(b.name));
    } catch (error) {
      setError(error.toString());
    } finally {
      _isBreedsLoading = false;
      notifyListeners();
    }
  }

  String _formatAge(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (now.day < dob.day) {
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    if (years <= 0) {
      return '$months months';
    }
    if (months == 0) {
      return '$years years';
    }
    return '$years years $months months';
  }

  @override
  void dispose() {
    nameController.dispose();
    colourController.dispose();
    dateOfBirthController.dispose();
    weightController.dispose();
    super.dispose();
  }
}

class BreedOption {
  BreedOption({
    required this.id,
    required this.name,
    required this.species,
    required this.sizeCategory,
    required this.description,
  });

  final String id;
  final String name;
  final String species;
  final String sizeCategory;
  final String description;

  factory BreedOption.fromMap(String id, Map<String, dynamic> data) {
    return BreedOption(
      id: id,
      name: (data['breedName'] as String?) ?? '',
      species: (data['species'] as String?) ?? '',
      sizeCategory: (data['sizeCategory'] as String?) ?? '',
      description: (data['breedDescription'] as String?) ?? '',
    );
  }
}
