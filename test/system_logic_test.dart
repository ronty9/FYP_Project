// test/system_logic_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_project/utils/validation_utils.dart';

void main() {
  setUpAll(() {
    print('======================================================');
    print('      FYP AUTOMATED SYSTEM LOGIC TEST REPORT');
    print('======================================================');
    print('Running Test Suite: Complete Application Modules');
    print('------------------------------------------------------');
  });

  group('Authentication Module', () {
    test('TC-01', () {
      expect(ValidationUtils.isValidEmail('user@com'), false);
      print('✅ TC-01 [Auth] Reject invalid email format: PASSED');
    });

    test('TC-02', () {
      expect(ValidationUtils.isValidEmail('admin@petscan.com.my'), true);
      print('✅ TC-02 [Auth] Accept valid email format: PASSED');
    });

    test('TC-03', () {
      expect(
        ValidationUtils.isValidRegistration('John', '', 'password123'),
        false,
      );
      print('✅ TC-03 [Auth] Reject empty registration fields: PASSED');
    });
  });

  group('Pet Management Module', () {
    test('TC-04', () {
      expect(ValidationUtils.isValidPetWeight(-2.5), false);
      print('✅ TC-04 [Pet] Reject negative/zero pet weight: PASSED');
    });

    test('TC-05', () {
      expect(ValidationUtils.isValidPetWeight(4.2), true);
      print('✅ TC-05 [Pet] Accept positive pet weight: PASSED');
    });

    test('TC-06', () {
      expect(
        ValidationUtils.isValidPetDetails('Bella', 'Dog', '', 'Female'),
        false,
      );
      print('✅ TC-06 [Pet] Reject missing pet required fields: PASSED');
    });
  });

  group('Calendar & Schedule Module', () {
    test('TC-07', () {
      final start = DateTime(2026, 3, 10, 14, 0);
      final end = DateTime(2026, 3, 10, 13, 0);
      expect(ValidationUtils.isValidScheduleTime(start, end), false);
      print('✅ TC-07 [Schedule] Reject end time before start time: PASSED');
    });

    test('TC-08', () {
      final now = DateTime(2026, 2, 28);
      final pastEvent = DateTime(2026, 1, 15);
      expect(ValidationUtils.isFutureSchedule(pastEvent, now), false);
      print('✅ TC-08 [Schedule] Reject scheduling events in the past: PASSED');
    });
  });

  group('AI Scanner Module', () {
    test('TC-09', () {
      expect(ValidationUtils.isAcceptableConfidence(0.485), false);
      print('✅ TC-09 [Scan] AI rejects low confidence (48.5%): PASSED');
    });

    test('TC-10', () {
      expect(ValidationUtils.isAcceptableConfidence(0.892), true);
      print('✅ TC-10 [Scan] AI accepts high confidence (89.2%): PASSED');
    });
  });
}
