// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../View/add_pet_view.dart';
import '../View/pet_detail_view.dart';
import '../models/pet_info.dart';
import 'base_view_model.dart';

class PetProfileViewModel extends BaseViewModel {
  final List<PetInfo> _pets = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _petsSubscription;
  Map<String, String> _breedNameById = {};

  PetProfileViewModel() {
    _listenToPets();
  }

  List<PetInfo> get pets => List.unmodifiable(_pets);

  bool get hasPets => _pets.isNotEmpty;

  Future<void> refreshPets() async {
    await _listenToPets();
  }

  Future<void> openAddPet(BuildContext context) async {
    final newPet = await Navigator.push<PetInfo?>(
      context,
      MaterialPageRoute(builder: (_) => const AddPetView()),
    );

    if (newPet == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    _showSnack(context, '${newPet.name} added successfully.');
  }

  Future<void> openPetDetail(BuildContext context, PetInfo pet) async {
    final removed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PetDetailView(pet: pet)),
    );

    if (removed == true) {
      _pets.remove(pet);
      notifyListeners();
      if (!context.mounted) {
        return;
      }
      _showSnack(context, '${pet.name} has been removed.');
    }
  }

  Future<void> seedBreeds(BuildContext context) async {
    runAsync(() async {
      final collection = FirebaseFirestore.instance.collection('breed');
      final snapshot = await collection.get();
      final existing = <String>{};
      int maxDog = 0;
      int maxCat = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['breedName'] ?? '').toString().trim();
        final species = (data['species'] ?? '').toString().trim();
        if (name.isNotEmpty && species.isNotEmpty) {
          existing.add('$name|$species');
        }

        final breedId = (data['breedId'] ?? '').toString().trim();
        if (breedId.length == 6) {
          final prefix = breedId.substring(0, 2);
          final number = int.tryParse(breedId.substring(2)) ?? 0;
          if (prefix == 'BD' && number > maxDog) maxDog = number;
          if (prefix == 'BC' && number > maxCat) maxCat = number;
        }
      }

      final breeds = [
        {
          'breedName': 'Mixed Breed',
          'species': 'Dog',
          'sizeCategory': 'Medium',
          'breedDescription': 'General mixed dog breed.',
        },
        {
          'breedName': 'Labrador Retriever',
          'species': 'Dog',
          'sizeCategory': 'Large',
          'breedDescription': 'Friendly, outgoing, active.',
        },
        {
          'breedName': 'Golden Retriever',
          'species': 'Dog',
          'sizeCategory': 'Large',
          'breedDescription': 'Kind, intelligent, friendly.',
        },
        {
          'breedName': 'German Shepherd',
          'species': 'Dog',
          'sizeCategory': 'Large',
          'breedDescription': 'Confident and smart.',
        },
        {
          'breedName': 'French Bulldog',
          'species': 'Dog',
          'sizeCategory': 'Small',
          'breedDescription': 'Adaptable and playful.',
        },
        {
          'breedName': 'Bulldog',
          'species': 'Dog',
          'sizeCategory': 'Medium',
          'breedDescription': 'Calm and courageous.',
        },
        {
          'breedName': 'Poodle',
          'species': 'Dog',
          'sizeCategory': 'Medium',
          'breedDescription': 'Active and proud.',
        },
        {
          'breedName': 'Beagle',
          'species': 'Dog',
          'sizeCategory': 'Medium',
          'breedDescription': 'Curious and friendly.',
        },
        {
          'breedName': 'Rottweiler',
          'species': 'Dog',
          'sizeCategory': 'Large',
          'breedDescription': 'Loyal and confident.',
        },
        {
          'breedName': 'Yorkshire Terrier',
          'species': 'Dog',
          'sizeCategory': 'Small',
          'breedDescription': 'Bold and affectionate.',
        },
        {
          'breedName': 'Dachshund',
          'species': 'Dog',
          'sizeCategory': 'Small',
          'breedDescription': 'Spunky and curious.',
        },
        {
          'breedName': 'Boxer',
          'species': 'Dog',
          'sizeCategory': 'Large',
          'breedDescription': 'Bright and energetic.',
        },
        {
          'breedName': 'Siberian Husky',
          'species': 'Dog',
          'sizeCategory': 'Large',
          'breedDescription': 'Friendly and outgoing.',
        },
        {
          'breedName': 'Great Dane',
          'species': 'Dog',
          'sizeCategory': 'Large',
          'breedDescription': 'Gentle giant.',
        },
        {
          'breedName': 'Doberman Pinscher',
          'species': 'Dog',
          'sizeCategory': 'Large',
          'breedDescription': 'Alert and loyal.',
        },
        {
          'breedName': 'Australian Shepherd',
          'species': 'Dog',
          'sizeCategory': 'Medium',
          'breedDescription': 'Smart and work-oriented.',
        },
        {
          'breedName': 'Shetland Sheepdog',
          'species': 'Dog',
          'sizeCategory': 'Small',
          'breedDescription': 'Bright and eager.',
        },
        {
          'breedName': 'Corgi',
          'species': 'Dog',
          'sizeCategory': 'Small',
          'breedDescription': 'Alert and affectionate.',
        },
        {
          'breedName': 'Shih Tzu',
          'species': 'Dog',
          'sizeCategory': 'Small',
          'breedDescription': 'Outgoing and friendly.',
        },
        {
          'breedName': 'Chihuahua',
          'species': 'Dog',
          'sizeCategory': 'Small',
          'breedDescription': 'Charming and confident.',
        },
        {
          'breedName': 'Border Collie',
          'species': 'Dog',
          'sizeCategory': 'Medium',
          'breedDescription': 'Very smart and athletic.',
        },
        {
          'breedName': 'Cocker Spaniel',
          'species': 'Dog',
          'sizeCategory': 'Medium',
          'breedDescription': 'Gentle and happy.',
        },
        {
          'breedName': 'Maltese',
          'species': 'Dog',
          'sizeCategory': 'Small',
          'breedDescription': 'Playful and gentle.',
        },
        {
          'breedName': 'Pomeranian',
          'species': 'Dog',
          'sizeCategory': 'Small',
          'breedDescription': 'Lively and bold.',
        },
        {
          'breedName': 'Boston Terrier',
          'species': 'Dog',
          'sizeCategory': 'Small',
          'breedDescription': 'Friendly and bright.',
        },
        {
          'breedName': 'Akita',
          'species': 'Dog',
          'sizeCategory': 'Large',
          'breedDescription': 'Dignified and loyal.',
        },
        {
          'breedName': 'Shar Pei',
          'species': 'Dog',
          'sizeCategory': 'Medium',
          'breedDescription': 'Calm and independent.',
        },
        {
          'breedName': 'Saint Bernard',
          'species': 'Dog',
          'sizeCategory': 'Large',
          'breedDescription': 'Gentle and patient.',
        },
        {
          'breedName': 'Whippet',
          'species': 'Dog',
          'sizeCategory': 'Medium',
          'breedDescription': 'Quiet and affectionate.',
        },
        {
          'breedName': 'Bull Terrier',
          'species': 'Dog',
          'sizeCategory': 'Medium',
          'breedDescription': 'Playful and energetic.',
        },
        {
          'breedName': 'Shiba Inu',
          'species': 'Dog',
          'sizeCategory': 'Small',
          'breedDescription': 'Alert and agile.',
        },
        {
          'breedName': 'British Shorthair',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Calm and easygoing.',
        },
        {
          'breedName': 'Domestic Shorthair',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Common mixed cat breed.',
        },
        {
          'breedName': 'Siamese',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Vocal and social.',
        },
        {
          'breedName': 'Maine Coon',
          'species': 'Cat',
          'sizeCategory': 'Large',
          'breedDescription': 'Gentle and friendly.',
        },
        {
          'breedName': 'Ragdoll',
          'species': 'Cat',
          'sizeCategory': 'Large',
          'breedDescription': 'Relaxed and affectionate.',
        },
        {
          'breedName': 'Bengal',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Energetic and playful.',
        },
        {
          'breedName': 'Persian',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Quiet and sweet.',
        },
        {
          'breedName': 'Abyssinian',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Active and curious.',
        },
        {
          'breedName': 'Scottish Fold',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Sweet and calm.',
        },
        {
          'breedName': 'Sphynx',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Affectionate and lively.',
        },
        {
          'breedName': 'Norwegian Forest Cat',
          'species': 'Cat',
          'sizeCategory': 'Large',
          'breedDescription': 'Gentle and friendly.',
        },
        {
          'breedName': 'Birman',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Gentle and social.',
        },
        {
          'breedName': 'Russian Blue',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Quiet and reserved.',
        },
        {
          'breedName': 'American Shorthair',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Easygoing and adaptable.',
        },
        {
          'breedName': 'Oriental Shorthair',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Talkative and social.',
        },
        {
          'breedName': 'Devon Rex',
          'species': 'Cat',
          'sizeCategory': 'Small',
          'breedDescription': 'Playful and people-oriented.',
        },
        {
          'breedName': 'Cornish Rex',
          'species': 'Cat',
          'sizeCategory': 'Small',
          'breedDescription': 'Active and affectionate.',
        },
        {
          'breedName': 'Balinese',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Elegant and vocal.',
        },
        {
          'breedName': 'Himalayan',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Calm and affectionate.',
        },
        {
          'breedName': 'Turkish Angora',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Graceful and playful.',
        },
        {
          'breedName': 'British Longhair',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Calm and affectionate.',
        },
        {
          'breedName': 'American Curl',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Friendly and curious.',
        },
        {
          'breedName': 'Manx',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Adaptable and playful.',
        },
        {
          'breedName': 'Exotic Shorthair',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Sweet and relaxed.',
        },
        {
          'breedName': 'Chartreux',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Quiet and affectionate.',
        },
        {
          'breedName': 'Burmese',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Social and playful.',
        },
        {
          'breedName': 'Tonkinese',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Friendly and vocal.',
        },
        {
          'breedName': 'Snowshoe',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Affectionate and social.',
        },
        {
          'breedName': 'RagaMuffin',
          'species': 'Cat',
          'sizeCategory': 'Large',
          'breedDescription': 'Gentle and friendly.',
        },
        {
          'breedName': 'Ocicat',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Active and outgoing.',
        },
        {
          'breedName': 'Japanese Bobtail',
          'species': 'Cat',
          'sizeCategory': 'Medium',
          'breedDescription': 'Playful and social.',
        },
      ];

      final batch = FirebaseFirestore.instance.batch();
      int added = 0;

      for (final breed in breeds) {
        final name = breed['breedName'] as String;
        final species = breed['species'] as String;
        final key = '$name|$species';
        if (existing.contains(key)) continue;

        final breedId = _nextBreedId(
          species: species,
          maxDog: maxDog,
          maxCat: maxCat,
        );
        if (breedId.startsWith('BD')) {
          maxDog++;
        } else if (breedId.startsWith('BC')) {
          maxCat++;
        }

        final docRef = collection.doc(breedId);
        batch.set(docRef, {'breedId': breedId, ...breed});
        added++;
      }

      if (added > 0) {
        await batch.commit();
      }

      if (context.mounted) {
        _showSnack(context, 'Breed seed completed. Added $added item(s).');
      }
    });
  }

  Future<void> _listenToPets() async {
    setLoading(true);
    setError(null);

    try {
      final userId = await _resolveUserId();
      if (userId == null || userId.isEmpty) {
        setError('User not found. Please log in again.');
        return;
      }

      await _loadBreeds();

      await _petsSubscription?.cancel();
      _petsSubscription = FirebaseFirestore.instance
          .collection('pet')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen(
            (snapshot) {
              _pets
                ..clear()
                ..addAll(snapshot.docs.map(_mapPetDoc));
              notifyListeners();
            },
            onError: (error) {
              setError(error.toString());
            },
          );
    } finally {
      setLoading(false);
    }
  }

  Future<void> _loadBreeds() async {
    final snapshot = await FirebaseFirestore.instance.collection('breed').get();
    _breedNameById = {
      for (final doc in snapshot.docs)
        doc.id: (doc.data()['breedName'] as String?) ?? '',
    };
  }

  PetInfo _mapPetDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final dobValue = data['dateOfBirth'];
    final DateTime? dateOfBirth = dobValue is Timestamp
        ? dobValue.toDate()
        : null;
    final breedId = data['breedId'] as String?;
    final photoUrls = (data['photoUrls'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final weightValue = data['weightKg'];
    final double? weightKg = weightValue is num ? weightValue.toDouble() : null;

    return PetInfo(
      id: data['petId'] as String? ?? doc.id,
      name: (data['petName'] as String?) ?? 'Unknown',
      species: (data['species'] as String?) ?? '',
      gender: data['gender'] as String?,
      colour: data['colour'] as String?,
      dateOfBirth: dateOfBirth,
      breedId: breedId,
      breed: _breedNameById[breedId] ?? '',
      userId: data['userId'] as String?,
      photoUrl: data['photoUrl'] as String?,
      photoUrls: photoUrls,
      weightKg: weightKg,
      age: dateOfBirth != null ? _formatAge(dateOfBirth) : 'Unknown',
      galleryImages: const [],
      notes: data['notes'] as String?,
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

  String _nextBreedId({
    required String species,
    required int maxDog,
    required int maxCat,
  }) {
    final normalized = species.toLowerCase();
    if (normalized == 'dog') {
      return 'BD${(maxDog + 1).toString().padLeft(4, '0')}';
    }
    if (normalized == 'cat') {
      return 'BC${(maxCat + 1).toString().padLeft(4, '0')}';
    }
    return 'BX${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  void _showSnack(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _petsSubscription?.cancel();
    super.dispose();
  }
}
