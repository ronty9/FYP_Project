import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../View/add_schedule_view.dart';
import '../View/schedule_detail_view.dart';
import '../calendar_event.dart';
import '../models/reminder_duration.dart';
import 'base_view_model.dart';

class CalendarViewModel extends BaseViewModel {
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<CalendarEvent> _events = [];
  bool _isLoadingSchedules = false;

  late int _selectedDay;
  late int _currentMonth;
  late int _currentYear;

  CalendarViewModel({DateTime? initialDate}) {
    final now = DateTime.now();
    if (initialDate != null) {
      _selectedDay = initialDate.day;
      _currentMonth = initialDate.month;
      _currentYear = initialDate.year;
    } else {
      _selectedDay = now.day;
      _currentMonth = now.month;
      _currentYear = now.year;
    }
    // Fetch schedules from Firestore on initialization
    fetchSchedules();
  }

  // --- Fetch Schedules from Firestore ---
  Future<void> fetchSchedules() async {
    _isLoadingSchedules = true;
    notifyListeners();

    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _isLoadingSchedules = false;
        notifyListeners();
        return;
      }

      // Get userId from Firestore
      final userSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('providerId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        _isLoadingSchedules = false;
        notifyListeners();
        return;
      }

      final userId = userSnapshot.docs.first.id;

      // Fetch schedules for this user (removed orderBy to avoid index requirement)
      final schedulesSnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('userId', isEqualTo: userId)
          .get();

      // Clear existing events and load from Firestore
      _events.clear();

      for (final doc in schedulesSnapshot.docs) {
        final data = doc.data();

        // Parse startDateTime
        final startTimestamp = data['startDateTime'] as Timestamp?;
        if (startTimestamp == null) continue;
        final startDateTime = startTimestamp.toDate();

        // Parse endDateTime
        final endTimestamp = data['endDateTime'] as Timestamp?;
        final endDateTime = endTimestamp?.toDate();

        // Parse reminderDateTime
        final reminderTimestamp = data['reminderDateTime'] as Timestamp?;
        final reminderDateTime = reminderTimestamp?.toDate();

        // Parse reminderDuration
        final reminderDurationString = data['reminderDuration'] as String?;
        final reminderDuration = ReminderDurationExtension.fromString(
          reminderDurationString,
        );

        // Format time string
        final timeString = DateFormat('h:mm a').format(startDateTime);

        // Get pet name if petId exists
        String petName = '';
        final petId = data['petId'] as String?;
        if (petId != null && petId.isNotEmpty) {
          try {
            final petDoc = await FirebaseFirestore.instance
                .collection('pets')
                .doc(petId)
                .get();
            if (petDoc.exists) {
              petName = petDoc.data()?['petName'] ?? '';
            }
          } catch (e) {
            debugPrint('Error fetching pet name: $e');
          }
        }

        final event = CalendarEvent(
          day: startDateTime.day,
          petName: petName,
          activity: data['scheTitle'] as String? ?? '',
          location: data['scheDescription'] as String? ?? '',
          time: timeString,
          scheduleId: doc.id,
          reminderDuration: reminderDuration,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          reminderEnabled: data['reminderEnabled'] as bool? ?? false,
          reminderDateTime: reminderDateTime,
          petId: petId,
          isCompleted: data['isCompleted'] as bool? ?? false,
        );

        _events.add(event);
      }

      // Sort events by startDateTime (since we removed orderBy from query)
      _events.sort((a, b) {
        if (a.startDateTime == null || b.startDateTime == null) return 0;
        return a.startDateTime!.compareTo(b.startDateTime!);
      });
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
    }

    _isLoadingSchedules = false;
    notifyListeners();
  }

  int get selectedDay => _selectedDay;
  int get currentMonth => _currentMonth;
  int get currentYear => _currentYear;
  String get monthYearLabel =>
      '${_monthNames[_currentMonth - 1]} $_currentYear';
  List<CalendarEvent> get events => List.unmodifiable(_events);
  bool get isLoadingSchedules => _isLoadingSchedules;

  CalendarEvent? get selectedEvent {
    return _events.where((event) {
      if (event.startDateTime == null) return event.day == _selectedDay;
      return event.startDateTime!.day == _selectedDay &&
          event.startDateTime!.month == _currentMonth &&
          event.startDateTime!.year == _currentYear;
    }).firstOrNull;
  }

  /// All events for the currently selected day (may be multiple).
  List<CalendarEvent> get selectedEvents {
    return _events.where((event) {
      if (event.startDateTime == null) return event.day == _selectedDay;
      return event.startDateTime!.day == _selectedDay &&
          event.startDateTime!.month == _currentMonth &&
          event.startDateTime!.year == _currentYear;
    }).toList();
  }

  List<int?> get days => _buildDays();

  // Month statistics
  int get totalEventsThisMonth {
    return _events.where((event) {
      if (event.startDateTime == null) return false;
      return event.startDateTime!.month == _currentMonth &&
          event.startDateTime!.year == _currentYear;
    }).length;
  }

  int get upcomingEvents {
    final now = DateTime.now();
    return _events.where((event) {
      if (event.startDateTime == null) return false;
      return event.startDateTime!.isAfter(now) ||
          event.startDateTime!.isAtSameMomentAs(now);
    }).length;
  }

  int get petsWithEvents {
    final currentMonthEvents = _events.where((event) {
      if (event.startDateTime == null) return false;
      return event.startDateTime!.month == _currentMonth &&
          event.startDateTime!.year == _currentYear;
    });
    return currentMonthEvents.map((event) => event.petName).toSet().length;
  }

  int get completedEventsThisMonth {
    return _events.where((event) {
      if (event.startDateTime == null) return false;
      return event.startDateTime!.month == _currentMonth &&
          event.startDateTime!.year == _currentYear &&
          event.isCompleted;
    }).length;
  }

  List<CalendarEvent> get upcomingEventsList {
    final now = DateTime.now();
    final upcoming = _events.where((event) {
      if (event.startDateTime == null) return false;
      return event.startDateTime!.isAfter(now) ||
          event.startDateTime!.isAtSameMomentAs(now);
    }).toList();
    upcoming.sort((a, b) {
      if (a.startDateTime == null || b.startDateTime == null) return 0;
      return a.startDateTime!.compareTo(b.startDateTime!);
    });
    return List.unmodifiable(upcoming);
  }

  void selectDay(int day) {
    if (_selectedDay == day) return;
    _selectedDay = day;
    notifyListeners();
  }

  void goToPreviousMonth() {
    if (_currentMonth == 1) {
      _currentMonth = 12;
      _currentYear--;
    } else {
      _currentMonth--;
    }
    _selectedDay = 1;
    notifyListeners();
  }

  void goToNextMonth() {
    if (_currentMonth == 12) {
      _currentMonth = 1;
      _currentYear++;
    } else {
      _currentMonth++;
    }
    _selectedDay = 1;
    notifyListeners();
  }

  /// Jump the calendar selection to today.
  void jumpToToday() {
    final now = DateTime.now();
    _selectedDay = now.day;
    _currentMonth = now.month;
    _currentYear = now.year;
    notifyListeners();
  }

  void onAddSchedulePressed(BuildContext context) {
    addSchedule(context);
  }

  Future<void> addSchedule(BuildContext context) async {
    final newEvent = await Navigator.push<CalendarEvent>(
      context,
      MaterialPageRoute(builder: (_) => const AddScheduleView()),
    );

    if (newEvent == null) return;

    // Refresh schedules from Firestore to include the newly added event
    await fetchSchedules();

    // Select the day of the new event
    if (newEvent.startDateTime != null) {
      _selectedDay = newEvent.startDateTime!.day;
      _currentMonth = newEvent.startDateTime!.month;
      _currentYear = newEvent.startDateTime!.year;
    } else {
      _selectedDay = newEvent.day;
    }
    notifyListeners();
  }

  void onOpenSelectedEventPressed(BuildContext context) {
    openSelectedEvent(context);
  }

  /// Open a specific event in the detail view.
  Future<void> openEvent(BuildContext context, CalendarEvent event) async {
    final result = await Navigator.push<Object>(
      context,
      MaterialPageRoute(builder: (_) => ScheduleDetailView(event: event)),
    );
    if (result == true || result is CalendarEvent) {
      await fetchSchedules();
      notifyListeners();
    }
  }

  Future<void> openSelectedEvent(BuildContext context) async {
    final event = selectedEvent;
    if (event == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No event for this day.')));
      return;
    }

    final result = await Navigator.push<Object>(
      context,
      MaterialPageRoute(builder: (_) => ScheduleDetailView(event: event)),
    );

    // Refresh schedules from Firestore after editing or deleting
    if (result == true || result is CalendarEvent) {
      await fetchSchedules();
      notifyListeners();
    }
  }

  List<int?> _buildDays() {
    // Get the number of days in the current month
    final daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    // Get the weekday of the first day (1=Monday, 7=Sunday)
    final firstWeekday = DateTime(_currentYear, _currentMonth, 1).weekday;
    // Padding for days before the 1st
    final leadingPadding = List<int?>.filled(firstWeekday - 1, null);
    // Actual days
    final days = List<int?>.generate(daysInMonth, (index) => index + 1);
    // Combine and add trailing padding to fill grid
    final allDays = [...leadingPadding, ...days];
    final totalSlots = ((allDays.length / 7).ceil()) * 7;
    final trailingPadding = List<int?>.filled(
      totalSlots - allDays.length,
      null,
    );
    return [...allDays, ...trailingPadding];
  }
}

// Helper extension if you are on an older Dart version
extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
