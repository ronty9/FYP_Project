// lib/calendar_event.dart
import 'models/reminder_duration.dart';
import 'models/schedule_type.dart';

class CalendarEvent {
  const CalendarEvent({
    required this.day,
    required this.petName,
    required this.activity,
    required this.location,
    required this.time,
    this.scheduleId,
    this.startDateTime,
    this.endDateTime,
    this.reminderEnabled = false,
    this.reminderDateTime,
    this.reminderDuration,
    this.petId,
    this.isCompleted = false,
    this.scheduleType = ScheduleType.other,
  });

  final int day;
  final String petName;
  final String activity;
  final String location;
  final String time;
  final String? scheduleId;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool reminderEnabled;
  final DateTime? reminderDateTime;
  final ReminderDuration? reminderDuration;
  final String? petId;
  final bool isCompleted;
  final ScheduleType scheduleType;
}
