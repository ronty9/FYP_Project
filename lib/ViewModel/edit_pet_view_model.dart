// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pet_info.dart';
import 'base_view_model.dart';

class EditPetViewModel extends BaseViewModel {
  EditPetViewModel(this._pet) {
    _initializeControllers();
    _loadBreeds();
  }

  final PetInfo _pet;
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController nameController;
  late final TextEditingController colourController;
  late final TextEditingController weightController;

  final List<BreedOption> _breeds = [];
  BreedOption? _selectedBreed;

  File? _profilePhotoFile;
  String? _selectedGalleryUrl;

  bool _hasChanges = false;

  String get species => _pet.species;
  String get gender => _pet.gender ?? 'Unknown';
  List<BreedOption> get breeds => _breeds;
  BreedOption? get selectedBreed => _selectedBreed;
  bool get hasChanges => _hasChanges;
  PetInfo get pet => _pet;
  File? get profilePhotoFile => _profilePhotoFile;
  String? get selectedGalleryUrl => _selectedGalleryUrl;

  String get _initialName => _pet.name;
  String get _initialColour => _pet.colour ?? '';
  double? get _initialWeightKg => _pet.weightKg;
  String? get _initialBreedId => _pet.breedId;

  void _initializeControllers() {
    nameController = TextEditingController(text: _pet.name);
    colourController = TextEditingController(text: _pet.colour ?? '');
    weightController = TextEditingController(
      text: _pet.weightKg?.toStringAsFixed(1) ?? '',
    );

    nameController.addListener(_onFieldChanged);
    colourController.addListener(_onFieldChanged);
    weightController.addListener(_onFieldChanged);
  }

  Future<void> _loadBreeds() async {
    final snapshot = await FirebaseFirestore.instance.collection('breed').get();
    _breeds
      ..clear()
      ..addAll(
        snapshot.docs.map((doc) => BreedOption.fromMap(doc.id, doc.data())),
      );
    _breeds.sort((a, b) => a.name.compareTo(b.name));
    BreedOption? selected;
    if (_pet.breedId != null && _pet.breedId!.isNotEmpty) {
      for (final breed in _breeds) {
        if (breed.id == _pet.breedId) {
          selected = breed;
          break;
        }
      }
    }
    if (selected == null && _pet.breed.isNotEmpty) {
      for (final breed in _breeds) {
        if (breed.name == _pet.breed) {
          selected = breed;
          break;
        }
      }
    }
    _selectedBreed = selected;
    notifyListeners();
  }

  void setSelectedBreed(BreedOption? value) {
    _selectedBreed = value;
    _onFieldChanged();
  }

  Future<void> pickProfilePhotoFromCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image == null) return;
    _profilePhotoFile = File(image.path);
    _selectedGalleryUrl = null;
    _onFieldChanged();
  }

  Future<void> pickProfilePhotoFromLocal() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image == null) return;
    _profilePhotoFile = File(image.path);
    _selectedGalleryUrl = null;
    _onFieldChanged();
  }

  void setProfilePhotoFromGallery(String url) {
    _selectedGalleryUrl = url;
    _profilePhotoFile = null;
    _onFieldChanged();
  }

  void _onFieldChanged() {
    final nameChanged = nameController.text.trim() != _initialName;
    final colourChanged = colourController.text.trim() != _initialColour;
    final weightValue = double.tryParse(weightController.text.trim());
    final weightChanged = weightValue != _initialWeightKg;
    final breedChanged = _selectedBreed?.id != _initialBreedId;
    final photoChanged =
        _profilePhotoFile != null ||
        (_selectedGalleryUrl != null && _selectedGalleryUrl!.isNotEmpty);

    final newHasChanges =
        nameChanged ||
        colourChanged ||
        weightChanged ||
        breedChanged ||
        photoChanged;

    if (newHasChanges != _hasChanges) {
      _hasChanges = newHasChanges;
      notifyListeners();
    }
  }

  Future<void> saveChanges(BuildContext context) async {
    final name = nameController.text.trim();
    final colour = colourController.text.trim();
    final weightKg = double.tryParse(weightController.text.trim());
    if (name.isEmpty || colour.isEmpty || weightKg == null || weightKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    if (_pet.id == null || _pet.id!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pet not found.')));
      return;
    }

    setLoading(true);
    setError(null);
    try {
      String? photoUrl = _pet.photoUrl;
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      if (authUid == null) {
        throw Exception('User not authenticated.');
      }

      if (_profilePhotoFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('pets')
            .child(authUid)
            .child('${_pet.id}_profile.jpg');
        await storageRef
            .putFile(_profilePhotoFile!)
            .timeout(const Duration(seconds: 60));
        photoUrl = await storageRef.getDownloadURL().timeout(
          const Duration(seconds: 10),
        );
      } else if (_selectedGalleryUrl != null &&
          _selectedGalleryUrl!.isNotEmpty) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('pets')
            .child(authUid)
            .child('${_pet.id}_profile.jpg');
        final data = await NetworkAssetBundle(
          Uri.parse(_selectedGalleryUrl!),
        ).load(_selectedGalleryUrl!);
        final bytes = data.buffer.asUint8List();
        await storageRef.putData(bytes).timeout(const Duration(seconds: 60));
        photoUrl = await storageRef.getDownloadURL().timeout(
          const Duration(seconds: 10),
        );
      }

      await FirebaseFirestore.instance.collection('pet').doc(_pet.id).update({
        'petName': name,
        'breedId': _selectedBreed?.id,
        'colour': colour,
        'weightKg': weightKg,
        'photoUrl': photoUrl,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pet details updated successfully!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } on TimeoutException {
      setError('Update timed out. Please try again.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update timed out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setError(error.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    colourController.dispose();
    weightController.dispose();
    super.dispose();
  }
}

class BreedOption {
  BreedOption({required this.id, required this.name});

  final String id;
  final String name;

  factory BreedOption.fromMap(String id, Map<String, dynamic> data) {
    return BreedOption(id: id, name: (data['breedName'] as String?) ?? '');
  }
}
