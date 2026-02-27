enum ReminderDuration {
  oneMinute,
  threeMinutes,
  fiveMinutes,
  tenMinutes,
  fifteenMinutes,
  thirtyMinutes,
  oneHour,
  twoHours,
  customTime,
  oneDay, // kept for backward compatibility with existing Firestore data
}

extension ReminderDurationExtension on ReminderDuration {
  String get displayName {
    switch (this) {
      case ReminderDuration.oneMinute:
        return '1 minute before';
      case ReminderDuration.threeMinutes:
        return '3 minutes before';
      case ReminderDuration.fiveMinutes:
        return '5 minutes before';
      case ReminderDuration.tenMinutes:
        return '10 minutes before';
      case ReminderDuration.fifteenMinutes:
        return '15 minutes before';
      case ReminderDuration.thirtyMinutes:
        return '30 minutes before';
      case ReminderDuration.oneHour:
        return '1 hour before';
      case ReminderDuration.twoHours:
        return '2 hours before';
      case ReminderDuration.customTime:
        return 'Custom time';
      case ReminderDuration.oneDay:
        return '1 day before';
    }
  }

  String get shortName {
    switch (this) {
      case ReminderDuration.oneMinute:
        return '1 min';
      case ReminderDuration.threeMinutes:
        return '3 min';
      case ReminderDuration.fiveMinutes:
        return '5 min';
      case ReminderDuration.tenMinutes:
        return '10 min';
      case ReminderDuration.fifteenMinutes:
        return '15 min';
      case ReminderDuration.thirtyMinutes:
        return '30 min';
      case ReminderDuration.oneHour:
        return '1 hour';
      case ReminderDuration.twoHours:
        return '2 hours';
      case ReminderDuration.customTime:
        return 'Custom';
      case ReminderDuration.oneDay:
        return '1 day';
    }
  }

  /// Returns the duration offset for preset options.
  /// Not valid for [customTime] — guard with [isCustom] before calling.
  Duration get duration {
    switch (this) {
      case ReminderDuration.oneMinute:
        return const Duration(minutes: 1);
      case ReminderDuration.threeMinutes:
        return const Duration(minutes: 3);
      case ReminderDuration.fiveMinutes:
        return const Duration(minutes: 5);
      case ReminderDuration.tenMinutes:
        return const Duration(minutes: 10);
      case ReminderDuration.fifteenMinutes:
        return const Duration(minutes: 15);
      case ReminderDuration.thirtyMinutes:
        return const Duration(minutes: 30);
      case ReminderDuration.oneHour:
        return const Duration(hours: 1);
      case ReminderDuration.twoHours:
        return const Duration(hours: 2);
      case ReminderDuration.customTime:
        return Duration.zero; // handled separately via custom time picker
      case ReminderDuration.oneDay:
        return const Duration(days: 1);
    }
  }

  bool get isCustom => this == ReminderDuration.customTime;

  DateTime calculateReminderTime(DateTime startDateTime) {
    return startDateTime.subtract(duration);
  }

  static ReminderDuration? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'oneMinute':
        return ReminderDuration.oneMinute;
      case 'threeMinutes':
        return ReminderDuration.threeMinutes;
      case 'fiveMinutes':
        return ReminderDuration.fiveMinutes;
      case 'tenMinutes':
        return ReminderDuration.tenMinutes;
      case 'fifteenMinutes':
        return ReminderDuration.fifteenMinutes;
      case 'thirtyMinutes':
        return ReminderDuration.thirtyMinutes;
      case 'oneHour':
        return ReminderDuration.oneHour;
      case 'twoHours':
        return ReminderDuration.twoHours;
      case 'customTime':
        return ReminderDuration.customTime;
      case 'oneDay':
        return ReminderDuration.oneDay;
      default:
        return null;
    }
  }

  String toFirestore() {
    return toString().split('.').last;
  }
}
