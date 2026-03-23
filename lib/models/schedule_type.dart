// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';

/// Represents the category/type of a pet schedule.
enum ScheduleType {
  note,
  vaccination,
  checkUp,
  medication,
  grooming,
  exercise,
  vet,
  feeding,
  other;

  /// Human-readable label for the schedule type.
  String get displayName {
    switch (this) {
      case ScheduleType.note:
        return 'Note';
      case ScheduleType.vaccination:
        return 'Vaccination';
      case ScheduleType.checkUp:
        return 'Check-Up';
      case ScheduleType.medication:
        return 'Medication';
      case ScheduleType.grooming:
        return 'Grooming';
      case ScheduleType.exercise:
        return 'Exercise';
      case ScheduleType.vet:
        return 'Vet Visit';
      case ScheduleType.feeding:
        return 'Feeding';
      case ScheduleType.other:
        return 'Other';
    }
  }

  /// Icon for the schedule type.
  IconData get icon {
    switch (this) {
      case ScheduleType.note:
        return Icons.note_alt_rounded;
      case ScheduleType.vaccination:
        return Icons.vaccines_rounded;
      case ScheduleType.checkUp:
        return Icons.local_hospital_rounded;
      case ScheduleType.medication:
        return Icons.medication_rounded;
      case ScheduleType.grooming:
        return Icons.content_cut_rounded;
      case ScheduleType.exercise:
        return Icons.directions_walk_rounded;
      case ScheduleType.vet:
        return Icons.medical_services_rounded;
      case ScheduleType.feeding:
        return Icons.restaurant_rounded;
      case ScheduleType.other:
        return Icons.event_rounded;
    }
  }

  /// Theme color for the schedule type.
  Color get color {
    switch (this) {
      case ScheduleType.note:
        return const Color(0xFF667EEA);
      case ScheduleType.vaccination:
        return const Color(0xFFFFBE0B);
      case ScheduleType.checkUp:
        return const Color(0xFFFF6B6B);
      case ScheduleType.medication:
        return const Color(0xFFFF9F43);
      case ScheduleType.grooming:
        return const Color(0xFF4ECDC4);
      case ScheduleType.exercise:
        return const Color(0xFF45B7D1);
      case ScheduleType.vet:
        return const Color(0xFFFF6B6B);
      case ScheduleType.feeding:
        return const Color(0xFF26DE81);
      case ScheduleType.other:
        return const Color(0xFF667EEA);
    }
  }

  /// Serialise to Firestore string.
  String toFirestore() => name;

  /// Deserialise from Firestore string.
  static ScheduleType fromFirestore(String? value) {
    if (value == null || value.isEmpty) return ScheduleType.other;
    return ScheduleType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ScheduleType.other,
    );
  }
}
