// lib/utils/validation_utils.dart

class ValidationUtils {
  // ════════════════════════════════════════════════════════════════════════
  // 1. AUTHENTICATION MODULE
  // ════════════════════════════════════════════════════════════════════════

  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  static bool isValidRegistration(String name, String email, String password) {
    // All register fields cannot be empty
    return name.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        password.trim().isNotEmpty;
  }

  // ════════════════════════════════════════════════════════════════════════
  // 2. PET MANAGEMENT MODULE
  // ════════════════════════════════════════════════════════════════════════

  static bool isValidPetWeight(double weight) {
    // Weight must be positive
    return weight > 0.0;
  }

  static bool isValidPetDetails(
    String name,
    String species,
    String breed,
    String gender,
  ) {
    // All pet fields are required
    return name.trim().isNotEmpty &&
        species.trim().isNotEmpty &&
        breed.trim().isNotEmpty &&
        gender.trim().isNotEmpty;
  }

  static String calculateAge(DateTime dob, DateTime now) {
    // Calculates age accurately for the UI
    final difference = now.difference(dob);
    final days = difference.inDays;

    if (days >= 365) return '${(days / 365).floor()}Y';
    if (days >= 30) return '${(days / 30).floor()}M';
    return '${days}D';
  }

  // ════════════════════════════════════════════════════════════════════════
  // 3. CALENDAR & SCHEDULE MODULE
  // ════════════════════════════════════════════════════════════════════════

  static bool isValidScheduleTime(DateTime start, DateTime end) {
    // End time must be AFTER start time
    return end.isAfter(start);
  }

  static bool isFutureSchedule(DateTime start, DateTime now) {
    // Cannot book an event in the past
    return start.isAfter(now);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 4. AI SCANNER MODULE
  // ════════════════════════════════════════════════════════════════════════

  static bool isAcceptableConfidence(double score) {
    // AI predictions must be 50% or higher to be considered valid
    return score >= 0.50;
  }

  // ════════════════════════════════════════════════════════════════════════
  // 5. ADMIN DASHBOARD MODULE
  // ════════════════════════════════════════════════════════════════════════

  static String formatActivityTime(DateTime timestamp, DateTime now) {
    // Tests the admin dashboard "Time Ago" formatter
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
