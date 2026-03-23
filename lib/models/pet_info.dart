// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

class PetInfo {
  const PetInfo({
    this.id,
    required this.name,
    required this.species,
    this.gender,
    this.colour,
    this.dateOfBirth,
    required this.breed,
    this.breedId,
    this.userId,
    this.photoUrl,
    this.photoUrls = const [],
    this.weightKg,
    required this.age,
    this.galleryImages = const [],
    this.notes,
  });

  final String? id;
  final String name;
  final String species;
  final String? gender;
  final String? colour;
  final DateTime? dateOfBirth;
  final String breed;
  final String? breedId;
  final String? userId;
  final String? photoUrl;
  final List<String> photoUrls;
  final double? weightKg;
  final String age;
  final List<String> galleryImages;
  final String? notes;
}
