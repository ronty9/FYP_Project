import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../calendar_event.dart';
import '../models/pet_info.dart';
import '../models/reminder_duration.dart';
import '../services/notification_service.dart';
import 'base_view_model.dart';

class EditScheduleViewModel extends BaseViewModel {
  EditScheduleViewModel(this.originalEvent) {
    titleController = TextEditingController(text: originalEvent.activity);
    descriptionController = TextEditingController(text: originalEvent.location);

    _startDateTime = originalEvent.startDateTime ?? _buildDateTimeFromEvent();
    _endDateTime = originalEvent.endDateTime ?? _startDateTime;
    _reminderEnabled = originalEvent.reminderEnabled;
    _reminderDateTime = originalEvent.reminderDateTime;
    _reminderDuration =
        originalEvent.reminderDuration ?? ReminderDuration.fifteenMinutes;
  }

  final CalendarEvent originalEvent;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  PetInfo? _selectedPet;
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;

  late DateTime _startDateTime;
  late DateTime _endDateTime;
  bool _reminderEnabled = false;
  DateTime? _reminderDateTime;
  late ReminderDuration _reminderDuration;

  PetInfo? get selectedPet => _selectedPet;

  set selectedPet(PetInfo? value) {
    _selectedPet = value;
    notifyListeners();
  }

  String get startLabel =>
      DateFormat('EEE, d MMM yyyy • h:mm a').format(_startDateTime);
  String get endLabel =>
      DateFormat('EEE, d MMM yyyy • h:mm a').format(_endDateTime);
  String get reminderLabel => _reminderDuration.displayName;
  bool get reminderEnabled => _reminderEnabled;
  ReminderDuration get reminderDuration => _reminderDuration;
  DateTime? get reminderDateTime => _reminderDateTime;

  void setReminderEnabled(bool value) {
    if (_reminderEnabled == value) return;
    _reminderEnabled = value;
    // Auto-calculate reminder time when enabled (skip for customTime)
    if (value && !_reminderDuration.isCustom) {
      _reminderDateTime = _reminderDuration.calculateReminderTime(
        _startDateTime,
      );
    }
    notifyListeners();
  }

  void setReminderDuration(ReminderDuration duration) {
    _reminderDuration = duration;
    // Recalculate for presets; customTime requires manual selection
    if (!duration.isCustom && _reminderEnabled) {
      _reminderDateTime = duration.calculateReminderTime(_startDateTime);
    } else if (duration.isCustom) {
      _reminderDateTime = null;
    }
    notifyListeners();
  }

  void syncSelectedPet(List<PetInfo> pets) {
    if (_selectedPet != null) return;
    for (final pet in pets) {
      if (pet.name == originalEvent.petName) {
        _selectedPet = pet;
        notifyListeners();
        return;
      }
    }
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initialDateTime,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate == null || !context.mounted) return null;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );

    if (selectedTime == null || !context.mounted) return null;

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  Future<void> pickStartDateTime(BuildContext context) async {
    final picked = await _pickDateTime(context, _startDateTime);
    if (picked == null) return;

    _startDateTime = picked;
    if (_endDateTime.isBefore(picked)) {
      _endDateTime = picked;
    }
    if (_reminderDateTime != null && _reminderDateTime!.isAfter(picked)) {
      _reminderDateTime = null;
    }
    notifyListeners();
  }

  Future<void> pickEndDateTime(BuildContext context) async {
    final picked = await _pickDateTime(context, _endDateTime);
    if (picked == null) return;

    _endDateTime = picked; // Auto-update reminder time when end time changes
    if (_reminderEnabled && !_reminderDuration.isCustom) {
      _reminderDateTime = _reminderDuration.calculateReminderTime(
        _startDateTime,
      );
    }
    notifyListeners();
  }

  Future<void> pickReminderDateTime(BuildContext context) async {
    final initial = _reminderDateTime ?? _startDateTime;
    final picked = await _pickDateTime(context, initial);
    if (picked == null) return;

    _reminderDateTime = picked;
    notifyListeners();
  }

  CalendarEvent get updatedEvent {
    final timeString = DateFormat('h:mm a').format(_startDateTime);

    return CalendarEvent(
      day: _startDateTime.day,
      petName: _selectedPet?.name ?? originalEvent.petName,
      activity: titleController.text.trim(),
      location: descriptionController.text.trim(),
      time: timeString,
      scheduleId: originalEvent.scheduleId,
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      reminderEnabled: _reminderEnabled,
      reminderDateTime: _reminderDateTime,
      reminderDuration: _reminderDuration,
      petId: _selectedPet?.id,
    );
  }

  void saveChanges(BuildContext context) {
    if (formKey.currentState?.validate() != true) return;

    if (_endDateTime.isBefore(_startDateTime)) {
      _showSnack(context, 'End time cannot be before start time.');
      return;
    }

    if (_reminderEnabled && _reminderDateTime == null) {
      _showSnack(context, 'Please select a reminder date & time.');
      return;
    }

    if (_reminderEnabled &&
        _reminderDateTime != null &&
        _reminderDateTime!.isAfter(_startDateTime)) {
      _showSnack(context, 'Reminder must be before the start time.');
      return;
    }

    showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(
                  ctx,
                ).colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.save_rounded,
                color: Theme.of(ctx).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Save Changes?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to save these changes to the schedule?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      if (!context.mounted) return;

      runAsync(() async {
        final scheduleId = originalEvent.scheduleId;
        if (scheduleId == null || scheduleId.isEmpty) {
          if (context.mounted) {
            _showSnack(context, 'Schedule id not found.');
          }
          return;
        }

        final updates = _buildScheduleUpdateMap(
          scheTitle: titleController.text.trim(),
          scheDescription: descriptionController.text.trim(),
          startDateTime: _startDateTime,
          endDateTime: _endDateTime,
          reminderEnabled: _reminderEnabled,
          reminderDateTime: _reminderDateTime,
          reminderDuration: _reminderDuration,
          petId: _selectedPet?.id,
        );

        await FirebaseFirestore.instance
            .collection('schedules')
            .doc(scheduleId)
            .update(updates);

        // Handle notification updates
        await _updateNotification(
          scheduleId: scheduleId,
          title: titleController.text.trim(),
          petName: _selectedPet?.name ?? originalEvent.petName,
          reminderEnabled: _reminderEnabled,
          reminderDateTime: _reminderDateTime,
        );

        if (!context.mounted) return;

        await Future.delayed(const Duration(milliseconds: 120));
        if (context.mounted) {
          Navigator.pop(context, updatedEvent);
        }
      });
    });
  }

  DateTime _buildDateTimeFromEvent() {
    final now = DateTime.now();
    final time = _parseTimeString(originalEvent.time);
    return DateTime(
      now.year,
      now.month,
      originalEvent.day,
      time.hour,
      time.minute,
    );
  }

  Map<String, dynamic> _buildScheduleUpdateMap({
    required String scheTitle,
    required String scheDescription,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool reminderEnabled,
    required DateTime? reminderDateTime,
    required ReminderDuration reminderDuration,
    required String? petId,
  }) {
    return {
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
      'petId': petId,
    };
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPM = parts.length > 1 && parts[1].toUpperCase() == 'PM';

      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  Future<void> _updateNotification({
    required String scheduleId,
    required String title,
    required String petName,
    required bool reminderEnabled,
    required DateTime? reminderDateTime,
  }) async {
    try {
      // Always cancel the old notification first
      await NotificationService().cancelReminder(scheduleId);

      // If reminder is enabled and has a datetime, schedule new notification
      if (reminderEnabled && reminderDateTime != null) {
        await NotificationService().scheduleReminder(
          scheduleId: scheduleId,
          title: 'Reminder: $title',
          body: '$petName has "$title" scheduled soon.',
          scheduledTime: reminderDateTime,
        );
      }
    } catch (e) {
      debugPrint('Error updating notification: $e');
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
