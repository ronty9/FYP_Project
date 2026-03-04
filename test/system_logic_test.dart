// test/system_logic_test.dart
//
// Comprehensive automated unit test suite for PetScan FYP project.
// Tests every pure-logic unit across all modules, then prints a
// formatted summary report with pass / fail counts.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_project/utils/validation_utils.dart';
import 'package:fyp_project/models/user_account.dart';
import 'package:fyp_project/models/schedule_type.dart';
import 'package:fyp_project/models/reminder_duration.dart';
import 'package:fyp_project/models/scan_prediction.dart';
import 'package:fyp_project/models/pet_info.dart';
import 'package:fyp_project/models/breed_option.dart';
import 'package:fyp_project/calendar_event.dart';
import 'package:fyp_project/models/feedback_model.dart';
import 'package:fyp_project/scan_type.dart';

// ─── Custom Summary Reporter ────────────────────────────────────────
/// Tracks every test result so we can print a table at the end.
class _TestReport {
  static final List<_TestEntry> _results = [];
  static int _currentIndex = 0;

  static void record(String id, String module, String description) {
    _results.add(_TestEntry(id: id, module: module, description: description));
    _currentIndex = _results.length - 1;
  }

  static void markPassed() {
    _results[_currentIndex].passed = true;
  }

  static void markFailed() {
    _results[_currentIndex].passed = false;
  }

  static void printReport() {
    final passed = _results.where((r) => r.passed).length;
    final failed = _results.where((r) => !r.passed).length;
    final total = _results.length;

    debugPrint('');
    debugPrint(
      '╔══════════════════════════════════════════════════════════════════════════════╗',
    );
    debugPrint(
      '║                   FYP AUTOMATED UNIT TEST — FULL REPORT                    ║',
    );
    debugPrint(
      '╠══════════════════════════════════════════════════════════════════════════════╣',
    );
    debugPrint(
      '║  ID     │ Module          │ Description                        │ Status     ║',
    );
    debugPrint(
      '╠══════════════════════════════════════════════════════════════════════════════╣',
    );

    for (final r in _results) {
      final status = r.passed ? '✅ PASS' : '❌ FAIL';
      final id = r.id.padRight(6);
      final mod = r.module.padRight(15);
      final desc = r.description.length > 34
          ? '${r.description.substring(0, 31)}...'
          : r.description.padRight(34);
      debugPrint('║  $id │ $mod │ $desc │ $status   ║');
    }

    debugPrint(
      '╠══════════════════════════════════════════════════════════════════════════════╣',
    );
    debugPrint(
      '║  TOTAL: $total tests   |   ✅ PASSED: $passed   |   ❌ FAILED: $failed${' ' * (28 - total.toString().length - passed.toString().length - failed.toString().length)}║',
    );
    debugPrint(
      '╚══════════════════════════════════════════════════════════════════════════════╝',
    );
    debugPrint('');
  }
}

class _TestEntry {
  _TestEntry({
    required this.id,
    required this.module,
    required this.description,
  });
  final String id;
  final String module;
  final String description;
  bool passed = false;
}

// ─── Helpers ─────────────────────────────────────────────────────────
/// Wraps a test body: records the test, marks pass/fail automatically.
void trackedTest(
  String testId,
  String module,
  String description,
  dynamic Function() body,
) {
  test('$testId — $description', () {
    _TestReport.record(testId, module, description);
    try {
      body();
      _TestReport.markPassed();
    } catch (e) {
      _TestReport.markFailed();
      rethrow; // let Flutter test framework also report the failure
    }
  });
}

// ═════════════════════════════════════════════════════════════════════
//  MAIN TEST SUITE
// ═════════════════════════════════════════════════════════════════════
void main() {
  // Print the report after ALL tests finish.
  tearDownAll(() {
    _TestReport.printReport();
  });

  // ──────────────────────────────────────────────────────────────────
  //  1. AUTHENTICATION MODULE
  // ──────────────────────────────────────────────────────────────────
  group('Authentication Module', () {
    trackedTest('TC-01', 'Auth', 'Reject invalid email (no TLD)', () {
      expect(ValidationUtils.isValidEmail('user@com'), false);
    });

    trackedTest('TC-02', 'Auth', 'Accept valid email', () {
      expect(ValidationUtils.isValidEmail('admin@petscan.com.my'), true);
    });

    trackedTest('TC-03', 'Auth', 'Reject empty email', () {
      expect(ValidationUtils.isValidEmail(''), false);
    });

    trackedTest('TC-04', 'Auth', 'Reject registration with empty field', () {
      expect(ValidationUtils.isValidRegistration('John', '', 'pass123'), false);
    });

    trackedTest('TC-05', 'Auth', 'Accept valid registration', () {
      expect(
        ValidationUtils.isValidRegistration('John', 'j@e.com', 'p1'),
        true,
      );
    });

    trackedTest('TC-06', 'Auth', 'Reject whitespace-only name', () {
      expect(ValidationUtils.isValidRegistration('   ', 'j@e.com', 'p'), false);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  //  2. PET MANAGEMENT MODULE
  // ──────────────────────────────────────────────────────────────────
  group('Pet Management Module', () {
    trackedTest('TC-07', 'Pet', 'Reject negative pet weight', () {
      expect(ValidationUtils.isValidPetWeight(-2.5), false);
    });

    trackedTest('TC-08', 'Pet', 'Reject zero pet weight', () {
      expect(ValidationUtils.isValidPetWeight(0.0), false);
    });

    trackedTest('TC-09', 'Pet', 'Accept positive pet weight', () {
      expect(ValidationUtils.isValidPetWeight(4.2), true);
    });

    trackedTest('TC-10', 'Pet', 'Reject missing pet breed', () {
      expect(
        ValidationUtils.isValidPetDetails('Bella', 'Dog', '', 'Female'),
        false,
      );
    });

    trackedTest('TC-11', 'Pet', 'Accept complete pet details', () {
      expect(
        ValidationUtils.isValidPetDetails('Bella', 'Dog', 'Poodle', 'Female'),
        true,
      );
    });

    trackedTest('TC-12', 'Pet', 'Calculate age in years', () {
      final dob = DateTime(2023, 1, 1);
      final now = DateTime(2026, 3, 2);
      expect(ValidationUtils.calculateAge(dob, now), '3Y');
    });

    trackedTest('TC-13', 'Pet', 'Calculate age in months', () {
      final dob = DateTime(2025, 12, 1);
      final now = DateTime(2026, 3, 2);
      expect(ValidationUtils.calculateAge(dob, now), '3M');
    });

    trackedTest('TC-14', 'Pet', 'Calculate age in days', () {
      final dob = DateTime(2026, 2, 20);
      final now = DateTime(2026, 3, 2);
      expect(ValidationUtils.calculateAge(dob, now), '10D');
    });
  });

  // ──────────────────────────────────────────────────────────────────
  //  3. CALENDAR & SCHEDULE MODULE
  // ──────────────────────────────────────────────────────────────────
  group('Calendar & Schedule Module', () {
    trackedTest('TC-15', 'Schedule', 'Reject end before start', () {
      final start = DateTime(2026, 3, 10, 14, 0);
      final end = DateTime(2026, 3, 10, 13, 0);
      expect(ValidationUtils.isValidScheduleTime(start, end), false);
    });

    trackedTest('TC-16', 'Schedule', 'Accept end after start', () {
      final start = DateTime(2026, 3, 10, 14, 0);
      final end = DateTime(2026, 3, 10, 15, 0);
      expect(ValidationUtils.isValidScheduleTime(start, end), true);
    });

    trackedTest('TC-17', 'Schedule', 'Reject equal start and end', () {
      final dt = DateTime(2026, 3, 10, 14, 0);
      expect(ValidationUtils.isValidScheduleTime(dt, dt), false);
    });

    trackedTest('TC-18', 'Schedule', 'Reject past event', () {
      final now = DateTime(2026, 2, 28);
      final past = DateTime(2026, 1, 15);
      expect(ValidationUtils.isFutureSchedule(past, now), false);
    });

    trackedTest('TC-19', 'Schedule', 'Accept future event', () {
      final now = DateTime(2026, 2, 28);
      final future = DateTime(2026, 4, 1);
      expect(ValidationUtils.isFutureSchedule(future, now), true);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  //  4. AI SCANNER MODULE
  // ──────────────────────────────────────────────────────────────────
  group('AI Scanner Module', () {
    trackedTest('TC-20', 'AI Scan', 'Reject low confidence (48.5%)', () {
      expect(ValidationUtils.isAcceptableConfidence(0.485), false);
    });

    trackedTest('TC-21', 'AI Scan', 'Accept high confidence (89.2%)', () {
      expect(ValidationUtils.isAcceptableConfidence(0.892), true);
    });

    trackedTest('TC-22', 'AI Scan', 'Accept boundary confidence (50%)', () {
      expect(ValidationUtils.isAcceptableConfidence(0.50), true);
    });

    trackedTest('TC-23', 'AI Scan', 'Reject zero confidence', () {
      expect(ValidationUtils.isAcceptableConfidence(0.0), false);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  //  5. ADMIN DASHBOARD MODULE
  // ──────────────────────────────────────────────────────────────────
  group('Admin Dashboard Module', () {
    trackedTest('TC-24', 'Admin', 'Format "Just now" (<60s)', () {
      final now = DateTime(2026, 3, 2, 12, 0, 0);
      final ts = DateTime(2026, 3, 2, 11, 59, 30);
      expect(ValidationUtils.formatActivityTime(ts, now), 'Just now');
    });

    trackedTest('TC-25', 'Admin', 'Format minutes ago', () {
      final now = DateTime(2026, 3, 2, 12, 0);
      final ts = DateTime(2026, 3, 2, 11, 45);
      expect(ValidationUtils.formatActivityTime(ts, now), '15m ago');
    });

    trackedTest('TC-26', 'Admin', 'Format hours ago', () {
      final now = DateTime(2026, 3, 2, 12, 0);
      final ts = DateTime(2026, 3, 2, 9, 0);
      expect(ValidationUtils.formatActivityTime(ts, now), '3h ago');
    });

    trackedTest('TC-27', 'Admin', 'Format days ago', () {
      final now = DateTime(2026, 3, 2, 12, 0);
      final ts = DateTime(2026, 2, 27, 12, 0);
      expect(ValidationUtils.formatActivityTime(ts, now), '3d ago');
    });
  });

  // ──────────────────────────────────────────────────────────────────
  //  6. MODEL: UserAccount
  // ──────────────────────────────────────────────────────────────────
  group('Model — UserAccount', () {
    trackedTest('TC-28', 'UserAccount', 'Create from constructor', () {
      final u = UserAccount(
        id: 'u1',
        name: 'Ali',
        email: 'ali@mail.com',
        joinDate: '2025-01-01',
        status: 'Active',
      );
      expect(u.name, 'Ali');
      expect(u.petsCount, 0);
    });

    trackedTest('TC-29', 'UserAccount', 'copyWith updates fields', () {
      final u = UserAccount(
        id: 'u1',
        name: 'Ali',
        email: 'ali@mail.com',
        joinDate: '2025-01-01',
        status: 'Active',
      );
      final u2 = u.copyWith(name: 'Abu', petsCount: 3);
      expect(u2.name, 'Abu');
      expect(u2.petsCount, 3);
      expect(u2.email, 'ali@mail.com'); // unchanged
    });

    trackedTest('TC-30', 'UserAccount', 'fromMap handles defaults', () {
      final u = UserAccount.fromMap('id1', {});
      expect(u.name, 'User');
      expect(u.status, 'Active');
      expect(u.petsCount, 0);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  //  7. MODEL: ScheduleType
  // ──────────────────────────────────────────────────────────────────
  group('Model — ScheduleType', () {
    trackedTest('TC-31', 'ScheduleType', 'displayName correct', () {
      expect(ScheduleType.vaccination.displayName, 'Vaccination');
      expect(ScheduleType.checkUp.displayName, 'Check-Up');
    });

    trackedTest('TC-32', 'ScheduleType', 'toFirestore round-trip', () {
      final str = ScheduleType.grooming.toFirestore();
      expect(ScheduleType.fromFirestore(str), ScheduleType.grooming);
    });

    trackedTest('TC-33', 'ScheduleType', 'fromFirestore null → other', () {
      expect(ScheduleType.fromFirestore(null), ScheduleType.other);
    });

    trackedTest('TC-34', 'ScheduleType', 'fromFirestore invalid → other', () {
      expect(ScheduleType.fromFirestore('xyz'), ScheduleType.other);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  //  8. MODEL: ReminderDuration
  // ──────────────────────────────────────────────────────────────────
  group('Model — ReminderDuration', () {
    trackedTest('TC-35', 'Reminder', 'fromString round-trip', () {
      expect(
        ReminderDurationExtension.fromString('tenMinutes'),
        ReminderDuration.tenMinutes,
      );
    });

    trackedTest('TC-36', 'Reminder', 'fromString null → null', () {
      expect(ReminderDurationExtension.fromString(null), isNull);
    });

    trackedTest('TC-37', 'Reminder', 'duration value correct', () {
      expect(
        ReminderDuration.thirtyMinutes.duration,
        const Duration(minutes: 30),
      );
    });

    trackedTest('TC-38', 'Reminder', 'calculateReminderTime', () {
      final start = DateTime(2026, 3, 10, 14, 0);
      final reminder = ReminderDuration.oneHour.calculateReminderTime(start);
      expect(reminder, DateTime(2026, 3, 10, 13, 0));
    });

    trackedTest('TC-39', 'Reminder', 'isCustom flag', () {
      expect(ReminderDuration.customTime.isCustom, true);
      expect(ReminderDuration.oneHour.isCustom, false);
    });

    trackedTest('TC-40', 'Reminder', 'toFirestore value', () {
      expect(ReminderDuration.fiveMinutes.toFirestore(), 'fiveMinutes');
    });
  });

  // ──────────────────────────────────────────────────────────────────
  //  9. MODEL: ScanPrediction
  // ──────────────────────────────────────────────────────────────────
  group('Model — ScanPrediction', () {
    trackedTest('TC-41', 'ScanPrediction', 'Constructor & fields', () {
      final p = ScanPrediction(label: 'Ringworm', confidence: 0.91);
      expect(p.label, 'Ringworm');
      expect(p.confidence, 0.91);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // 10. MODEL: PetInfo
  // ──────────────────────────────────────────────────────────────────
  group('Model — PetInfo', () {
    trackedTest('TC-42', 'PetInfo', 'Constructor defaults', () {
      final p = PetInfo(name: 'Max', species: 'Dog', breed: 'Husky', age: '2Y');
      expect(p.name, 'Max');
      expect(p.photoUrls, isEmpty);
      expect(p.galleryImages, isEmpty);
      expect(p.weightKg, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // 11. MODEL: BreedOption
  // ──────────────────────────────────────────────────────────────────
  group('Model — BreedOption', () {
    trackedTest('TC-43', 'BreedOption', 'Constructor & fields', () {
      final b = BreedOption(id: 'b1', name: 'Siamese');
      expect(b.id, 'b1');
      expect(b.name, 'Siamese');
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // 12. MODEL: CalendarEvent
  // ──────────────────────────────────────────────────────────────────
  group('Model — CalendarEvent', () {
    trackedTest('TC-44', 'CalendarEvent', 'Constructor defaults', () {
      final e = CalendarEvent(
        day: 10,
        petName: 'Buddy',
        activity: 'Grooming',
        location: 'PetShop',
        time: '2:00 PM',
      );
      expect(e.reminderEnabled, false);
      expect(e.isCompleted, false);
      expect(e.scheduleType, ScheduleType.other);
      expect(e.scheduleId, isNull);
    });

    trackedTest('TC-45', 'CalendarEvent', 'All optional fields populated', () {
      final start = DateTime(2026, 3, 10, 14, 0);
      final end = DateTime(2026, 3, 10, 15, 0);
      final reminderDt = DateTime(2026, 3, 10, 13, 0);
      final e = CalendarEvent(
        day: 10,
        petName: 'Buddy',
        activity: 'Vaccination',
        location: 'Vet Clinic',
        time: '2:00 PM',
        scheduleId: 'sch-001',
        startDateTime: start,
        endDateTime: end,
        reminderEnabled: true,
        reminderDateTime: reminderDt,
        reminderDuration: ReminderDuration.oneHour,
        petId: 'pet-001',
        isCompleted: true,
        scheduleType: ScheduleType.vaccination,
      );
      expect(e.reminderEnabled, true);
      expect(e.isCompleted, true);
      expect(e.scheduleId, 'sch-001');
      expect(e.petId, 'pet-001');
      expect(e.scheduleType, ScheduleType.vaccination);
      expect(e.startDateTime, start);
      expect(e.endDateTime, end);
      expect(e.reminderDateTime, reminderDt);
      expect(e.reminderDuration, ReminderDuration.oneHour);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // 13. MODEL: FeedbackModel
  // ──────────────────────────────────────────────────────────────────
  group('Model — FeedbackModel', () {
    trackedTest('TC-46', 'FeedbackModel', 'Constructor & required fields', () {
      final fb = FeedbackModel(
        id: 'fb1',
        userId: 'u1',
        userEmail: 'user@mail.com',
        category: 'Bug',
        title: 'App crash',
        message: 'Crashes on scan page',
        rating: 4,
        status: 'Pending',
        createdAt: DateTime(2026, 3, 1),
      );
      expect(fb.id, 'fb1');
      expect(fb.userId, 'u1');
      expect(fb.userEmail, 'user@mail.com');
      expect(fb.category, 'Bug');
      expect(fb.title, 'App crash');
      expect(fb.rating, 4);
      expect(fb.status, 'Pending');
    });

    trackedTest('TC-47', 'FeedbackModel', 'Optional reply fields null', () {
      final fb = FeedbackModel(
        id: 'fb2',
        userId: 'u2',
        userEmail: 'admin@mail.com',
        category: 'Feature',
        title: 'Dark mode',
        message: 'Please add dark mode',
        rating: 5,
        status: 'Pending',
        createdAt: DateTime(2026, 3, 2),
      );
      expect(fb.messageReply, isNull);
      expect(fb.replyBy, isNull);
      expect(fb.replyAt, isNull);
    });

    trackedTest('TC-48', 'FeedbackModel', 'With admin reply fields', () {
      final fb = FeedbackModel(
        id: 'fb3',
        userId: 'u3',
        userEmail: 'user3@mail.com',
        category: 'Bug',
        title: 'Login issue',
        message: 'Cannot login',
        rating: 2,
        status: 'Resolved',
        createdAt: DateTime(2026, 2, 28),
        messageReply: 'Fixed in v2.1',
        replyBy: 'admin@petscan.com',
        replyAt: DateTime(2026, 3, 1),
      );
      expect(fb.messageReply, 'Fixed in v2.1');
      expect(fb.replyBy, 'admin@petscan.com');
      expect(fb.replyAt, DateTime(2026, 3, 1));
      expect(fb.status, 'Resolved');
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // 14. MODEL: ScanType
  // ──────────────────────────────────────────────────────────────────
  group('Model — ScanType', () {
    trackedTest('TC-49', 'ScanType', 'Enum has expected values', () {
      expect(ScanType.values.length, 2);
      expect(ScanType.values.contains(ScanType.skinDisease), true);
      expect(ScanType.values.contains(ScanType.breed), true);
    });

    trackedTest('TC-50', 'ScanType', 'Enum name strings', () {
      expect(ScanType.skinDisease.name, 'skinDisease');
      expect(ScanType.breed.name, 'breed');
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // 15. EDGE CASES — Authentication
  // ──────────────────────────────────────────────────────────────────
  group('Edge Cases — Authentication', () {
    trackedTest('TC-51', 'Auth-Edge', 'Accept email with + tag', () {
      expect(ValidationUtils.isValidEmail('user+tag@mail.com'), true);
    });

    trackedTest('TC-52', 'Auth-Edge', 'Reject email missing @ symbol', () {
      expect(ValidationUtils.isValidEmail('usermail.com'), false);
    });

    trackedTest('TC-53', 'Auth-Edge', 'Reject registration all empty', () {
      expect(ValidationUtils.isValidRegistration('', '', ''), false);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // 16. EDGE CASES — Pet Management
  // ──────────────────────────────────────────────────────────────────
  group('Edge Cases — Pet Management', () {
    trackedTest('TC-54', 'Pet-Edge', 'Accept very large weight', () {
      expect(ValidationUtils.isValidPetWeight(9999.9), true);
    });

    trackedTest('TC-55', 'Pet-Edge', 'Age when DOB is today = 0D', () {
      final today = DateTime(2026, 3, 3);
      expect(ValidationUtils.calculateAge(today, today), '0D');
    });

    trackedTest('TC-56', 'Pet-Edge', 'Reject all-empty pet details', () {
      expect(ValidationUtils.isValidPetDetails('', '', '', ''), false);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // 17. EDGE CASES — AI Scanner
  // ──────────────────────────────────────────────────────────────────
  group('Edge Cases — AI Scanner', () {
    trackedTest('TC-57', 'AI-Edge', 'Accept confidence above 1.0', () {
      // Values >1.0 should still pass the >=0.50 check
      expect(ValidationUtils.isAcceptableConfidence(1.5), true);
    });

    trackedTest('TC-58', 'AI-Edge', 'Reject negative confidence', () {
      expect(ValidationUtils.isAcceptableConfidence(-0.1), false);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // 18. EDGE CASES — Admin Dashboard
  // ──────────────────────────────────────────────────────────────────
  group('Edge Cases — Admin Dashboard', () {
    trackedTest('TC-59', 'Admin-Edge', 'Same timestamp → Just now', () {
      final now = DateTime(2026, 3, 3, 12, 0);
      expect(ValidationUtils.formatActivityTime(now, now), 'Just now');
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // 19. EDGE CASES — UserAccount
  // ──────────────────────────────────────────────────────────────────
  group('Edge Cases — UserAccount', () {
    trackedTest('TC-60', 'UserAccount', 'fromMap with partial data', () {
      final u = UserAccount.fromMap('id2', {'userName': 'Siti'});
      expect(u.name, 'Siti');
      expect(u.email, ''); // default
      expect(u.status, 'Active'); // default
      expect(u.petsCount, 0); // default
    });
  });
}
