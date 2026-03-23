// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

/// Pure-logic validation utilities used across the PetScan app.
///
/// Every method here is a static, side-effect-free function so it can be
/// tested without any Flutter widget or Firebase dependency.
class ValidationUtils {
  ValidationUtils._(); // prevent instantiation

  // ───────────────────────────── Authentication ─────────────────────────────

  /// Returns `true` when [email] has a basic valid format:
  /// - contains exactly one `@`
  /// - has a non-empty local part
  /// - the domain part contains at least one `.` with a TLD of ≥2 characters
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    // Simple regex: local@domain.tld (TLD ≥ 2 chars)
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  /// Returns `true` when all three registration fields are non-empty
  /// (after trimming whitespace).
  static bool isValidRegistration(String name, String email, String password) {
    return name.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        password.trim().isNotEmpty;
  }

  // ──────────────────────────── Pet Management ──────────────────────────────

  /// Returns `true` when [weight] is strictly positive.
  static bool isValidPetWeight(double weight) {
    return weight > 0;
  }

  /// Returns `true` when every detail field is non-empty (after trimming).
  static bool isValidPetDetails(
    String name,
    String species,
    String breed,
    String gender,
  ) {
    return name.trim().isNotEmpty &&
        species.trim().isNotEmpty &&
        breed.trim().isNotEmpty &&
        gender.trim().isNotEmpty;
  }

  /// Calculates a human-friendly age string from [dob] to [now].
  ///
  /// Returns one of:
  /// - `'<n>Y'` if the difference is ≥ 1 year
  /// - `'<n>M'` if the difference is ≥ 1 month but < 1 year
  /// - `'<n>D'` otherwise (including 0 days)
  static String calculateAge(DateTime dob, DateTime now) {
    int years = now.year - dob.year;
    int months = now.month - dob.month;

    if (now.day < dob.day) {
      months--;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years >= 1) return '${years}Y';
    if (months >= 1) return '${months}M';

    final days = now.difference(dob).inDays;
    return '${days}D';
  }

  // ─────────────────────────── Calendar / Schedule ──────────────────────────

  /// Returns `true` when [end] is strictly after [start].
  static bool isValidScheduleTime(DateTime start, DateTime end) {
    return end.isAfter(start);
  }

  /// Returns `true` when [scheduleDate] is after [now].
  static bool isFutureSchedule(DateTime scheduleDate, DateTime now) {
    return scheduleDate.isAfter(now);
  }

  // ──────────────────────────── AI Scanner ──────────────────────────────────

  /// Returns `true` when [confidence] is at or above the 50 % threshold.
  static bool isAcceptableConfidence(double confidence) {
    return confidence >= 0.50;
  }

  // ─────────────────────────── Admin Dashboard ──────────────────────────────

  /// Formats the difference between [timestamp] and [now] as a short string:
  ///
  /// - `'Just now'`   — less than 60 seconds
  /// - `'<n>m ago'`   — less than 60 minutes
  /// - `'<n>h ago'`   — less than 24 hours
  /// - `'<n>d ago'`   — everything else
  static String formatActivityTime(DateTime timestamp, DateTime now) {
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
