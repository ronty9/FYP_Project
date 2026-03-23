// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../calendar_event.dart';
import '../models/reminder_duration.dart';
import '../models/schedule_type.dart';
import '../services/notification_service.dart';
import 'base_view_model.dart';
import 'notifications_view_model.dart';

class AddScheduleViewModel extends BaseViewModel {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // --- Controllers (Renamed to match the new logic) ---
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // --- State Variables ---
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  DateTime? _reminderDateTime;
  bool _reminderEnabled = false;
  ReminderDuration _reminderDuration = ReminderDuration.fifteenMinutes;

  ScheduleType _scheduleType = ScheduleType.other;

  // Placeholder for Pet object (Change 'dynamic' to 'Pet' if you have the model imported)
  dynamic _selectedPet;
  String? userId; // To store resolved User ID

  // --- Getters ---
  DateTime? get startDateTime => _startDateTime;
  DateTime? get endDateTime => _endDateTime;
  DateTime? get reminderDateTime => _reminderDateTime;
  bool get reminderEnabled => _reminderEnabled;
  ReminderDuration get reminderDuration => _reminderDuration;
  dynamic get selectedPet => _selectedPet;
  ScheduleType get scheduleType => _scheduleType;

  void setScheduleType(ScheduleType type) {
    _scheduleType = type;
    notifyListeners();
  }

  // --- Setters ---
  void setStartDate(DateTime? date) {
    _startDateTime = date;
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    _endDateTime = date;
    notifyListeners();
  }

  void setReminderDate(DateTime? date) {
    _reminderDateTime = date;
    notifyListeners();
  }

  void toggleReminder(bool value) {
    _reminderEnabled = value;
    // Auto-calculate reminder time when enabled (skip for customTime)
    if (value && _startDateTime != null && !_reminderDuration.isCustom) {
      _reminderDateTime = _reminderDuration.calculateReminderTime(
        _startDateTime!,
      );
    }
    notifyListeners();
  }

  void setReminderDuration(ReminderDuration duration) {
    _reminderDuration = duration;
    // Recalculate reminder time for presets; customTime is set via pickReminderDateTime
    if (!duration.isCustom && _reminderEnabled && _startDateTime != null) {
      _reminderDateTime = duration.calculateReminderTime(_startDateTime!);
    } else if (duration.isCustom) {
      // Clear auto-calculated time so user must pick manually
      _reminderDateTime = null;
    }
    notifyListeners();
  }

  /// Opens a date + time picker so the user can choose an exact reminder time.
  Future<void> pickReminderDateTime(BuildContext context) async {
    final now = DateTime.now();
    final initial = _reminderDateTime ?? _startDateTime ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );

    if (selectedDate == null || !context.mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (selectedTime == null) return;

    _reminderDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    notifyListeners();
  }

  void setSelectedPet(dynamic pet) {
    _selectedPet = pet;
    notifyListeners();
  }

  // --- Helper to Format Date for UI ---
  String formatDateTimeLabel(
    DateTime? value, {
    String placeholder = 'Select Date',
  }) {
    if (value == null) return placeholder;
    return DateFormat('EEE, d MMM yyyy • h:mm a').format(value);
  }

  // --- Date Picker Logic ---
  Future<void> pickDateTime(
    BuildContext context, {
    required bool isStart,
  }) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDateTime ?? now) : (_endDateTime ?? now);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedDate == null || !context.mounted) return;

    final timeInitial = TimeOfDay.fromDateTime(initial);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: timeInitial,
    );

    if (selectedTime == null || !context.mounted) return;

    final result = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (isStart) {
      _startDateTime = result;
      // Auto-update reminder time when start time changes (skip for customTime)
      if (_reminderEnabled && !_reminderDuration.isCustom) {
        _reminderDateTime = _reminderDuration.calculateReminderTime(result);
      }
    } else {
      _endDateTime = result;
    }
    notifyListeners();
  }

  // --- Main Save Logic ---
  void onSaveSchedulePressed(BuildContext context) {
    final formState = formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    // 1. Validation
    if (_startDateTime == null || _endDateTime == null) {
      _showSnack(context, 'Please select start and end date & time.');
      return;
    }

    if (_endDateTime!.isBefore(_startDateTime!)) {
      _showSnack(context, 'End time cannot be before start time.');
      return;
    }

    if (_reminderEnabled && _reminderDateTime == null) {
      if (_reminderDuration.isCustom) {
        _showSnack(context, 'Please select a custom reminder time.');
        return;
      } else if (_startDateTime != null) {
        _reminderDateTime = _reminderDuration.calculateReminderTime(
          _startDateTime!,
        );
      } else {
        _showSnack(context, 'Please select a start time first.');
        return;
      }
    }

    if (_reminderEnabled &&
        _reminderDateTime != null &&
        _reminderDateTime!.isAfter(_startDateTime!)) {
      _showSnack(context, 'Reminder must be before the start time.');
      return;
    }

    // 2. Async Save Operation
    runAsync(() async {
      await _performSave(context);
    });
  }

  Future<void> _performSave(BuildContext context) async {
    final start = _startDateTime!;
    final end = _endDateTime!;

    // 3. Resolve User ID
    final resolvedUserId = await _resolveUserId();
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      if (context.mounted) {
        _showSnack(context, 'User not found. Please log in again.');
      }
      return;
    }

    // 4. Create Payload
    final scheduleId = await _createSchedule(
      scheTitle: titleController.text.trim(),
      scheDescription: descriptionController.text.trim(),
      startDateTime: start,
      endDateTime: end,
      reminderEnabled: _reminderEnabled,
      reminderDateTime: _reminderDateTime,
      reminderDuration: _reminderDuration,
      petId: _selectedPet?.id,
      userId: resolvedUserId,
      scheduleType: _scheduleType,
    );

    if (!context.mounted) return;

    // 5. Create Local Event for Calendar (Immediate UI update)
    final timeString = DateFormat('h:mm a').format(start);
    final newEvent = CalendarEvent(
      day: start.day,
      petName: _selectedPet?.name ?? '',
      activity: titleController.text.trim(),
      location: descriptionController.text.trim(),
      time: timeString,
      scheduleId: scheduleId,
      startDateTime: start,
      endDateTime: end,
      reminderEnabled: _reminderEnabled,
      reminderDateTime: _reminderDateTime,
      petId: _selectedPet?.id,
      scheduleType: _scheduleType,
    );

    // Schedule notification if reminder is enabled
    if (_reminderEnabled && _reminderDateTime != null) {
      await _scheduleNotification(
        scheduleId: scheduleId,
        title: titleController.text.trim(),
        petName: _selectedPet?.name ?? 'Your pet',
        reminderDateTime: _reminderDateTime!,
      );
    }

    // Create notification record in Firestore
    final notifType = _mapScheduleTypeToNotificationType(_scheduleType);
    await NotificationsViewModel.createNotificationRecord(
      userId: resolvedUserId,
      title: '${_scheduleType.displayName}: ${titleController.text.trim()}',
      message:
          '${_selectedPet?.name ?? "Your pet"} has "${titleController.text.trim()}" scheduled for ${DateFormat('d MMM yyyy, h:mm a').format(start)}.',
      type: notifType,
      linkedDate: start,
    );

    if (context.mounted) {
      Navigator.pop(context, newEvent);
    }
  }

  // --- Helpers ---

  Future<String?> _resolveUserId() async {
    if (userId != null && userId!.trim().isNotEmpty) {
      return userId!.trim();
    }

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

  NotificationType _mapScheduleTypeToNotificationType(ScheduleType type) {
    switch (type) {
      case ScheduleType.vaccination:
        return NotificationType.vaccination;
      case ScheduleType.checkUp:
        return NotificationType.checkUp;
      case ScheduleType.medication:
        return NotificationType.medication;
      case ScheduleType.grooming:
        return NotificationType.grooming;
      case ScheduleType.exercise:
        return NotificationType.exercise;
      case ScheduleType.vet:
        return NotificationType.vet;
      case ScheduleType.feeding:
        return NotificationType.feeding;
      case ScheduleType.note:
        return NotificationType.note;
      case ScheduleType.other:
        return NotificationType.general;
    }
  }

  Future<String> _createSchedule({
    required String scheTitle,
    required String scheDescription,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool reminderEnabled,
    required DateTime? reminderDateTime,
    required ReminderDuration reminderDuration,
    required String? petId,
    required String userId,
    required ScheduleType scheduleType,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('schedules').doc();
    await docRef.set({
      'scheduleId': docRef.id,
      'scheTitle': scheTitle,
      'scheDescription': scheDescription,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'reminderEnabled': reminderEnabled,
      'reminderDateTime': reminderEnabled && reminderDateTime != null
          ? Timestamp.fromDate(reminderDateTime)
          : null,
      'reminderDuration': reminderEnabled
          ? reminderDuration.toFirestore()
          : null,
      'scheCreatedAt': FieldValue.serverTimestamp(),
      'petId': petId,
      'userId': userId,
      'isCompleted': false,
      'scheduleType': scheduleType.toFirestore(),
    });
    return docRef.id;
  }

  Future<void> _scheduleNotification({
    required String scheduleId,
    required String title,
    required String petName,
    required DateTime reminderDateTime,
  }) async {
    try {
      await NotificationService().scheduleReminder(
        scheduleId: scheduleId,
        title: 'Reminder: $title',
        body: '$petName has "$title" scheduled soon.',
        scheduledTime: reminderDateTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
