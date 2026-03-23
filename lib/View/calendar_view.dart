// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../calendar_event.dart';
import '../models/schedule_type.dart';
import '../ViewModel/calendar_view_model.dart';

class CalendarView extends StatelessWidget {
  final DateTime? initialDate;
  const CalendarView({super.key, this.initialDate});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarViewModel(initialDate: initialDate),
      child: const _CalendarBody(),
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final viewModel = context.watch<CalendarViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () => viewModel.onAddSchedulePressed(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      body: Column(
        children: [
          // ── Gradient header ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendar',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        viewModel.monthYearLabel,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Today button
                GestureDetector(
                  onTap: () => viewModel.jumpToToday(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Today',
                      style: textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ──────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => viewModel.fetchSchedules(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calendar card
                    _CalendarCard(viewModel: viewModel),

                    const SizedBox(height: 20),

                    // Monthly Overview
                    _SectionLabel(label: 'Monthly Overview'),
                    const SizedBox(height: 10),
                    _MonthStatsCard(viewModel: viewModel),

                    const SizedBox(height: 20),

                    // Events for selected day
                    _SelectedDayEventsSection(viewModel: viewModel),

                    // Bottom padding so FAB doesn't overlap last card
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade700,
      ),
    );
  }
}

// ── Monthly stats card ─────────────────────────────────────────────────────────

class _MonthStatsCard extends StatelessWidget {
  const _MonthStatsCard({required this.viewModel});
  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MonthStat(
            icon: Icons.event_note_rounded,
            value: '${viewModel.totalEventsThisMonth}',
            label: 'Total',
            color: colorScheme.primary,
          ),
          _Divider(),
          _MonthStat(
            icon: Icons.upcoming_rounded,
            value: '${viewModel.upcomingEvents}',
            label: 'Upcoming',
            color: const Color(0xFF4ECDC4),
          ),
          _Divider(),
          _MonthStat(
            icon: Icons.check_circle_outline_rounded,
            value: '${viewModel.completedEventsThisMonth}',
            label: 'Done',
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: Colors.grey.shade200);
}

// ── Events for selected day ────────────────────────────────────────────────────

class _SelectedDayEventsSection extends StatelessWidget {
  const _SelectedDayEventsSection({required this.viewModel});
  final CalendarViewModel viewModel;

  String _dayLabel(BuildContext context) {
    final now = DateTime.now();
    final sel = DateTime(
      viewModel.currentYear,
      viewModel.currentMonth,
      viewModel.selectedDay,
    );
    final diff = DateTime(
      sel.year,
      sel.month,
      sel.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dayName = weekdays[sel.weekday - 1];
    final monthName = months[sel.month - 1];
    if (diff == 0) return 'Today \u2014 $dayName, $monthName ${sel.day}';
    if (diff == 1) return 'Tomorrow \u2014 $dayName, $monthName ${sel.day}';
    if (diff == -1) return 'Yesterday \u2014 $dayName, $monthName ${sel.day}';
    return '$dayName, $monthName ${sel.day}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final events = viewModel.selectedEvents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _SectionLabel(label: _dayLabel(context))),
            if (events.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${events.length} event${events.length == 1 ? "" : "s"}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (viewModel.isLoadingSchedules)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (events.isEmpty)
          _EmptyEventsCard()
        else
          ...events.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EventCard(
                event: e,
                onTap: () => viewModel.openEvent(context, e),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyEventsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 36,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No events on this day',
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the + button to add a schedule',
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── Event card ────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, this.onTap});
  final CalendarEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isCompleted = event.isCompleted;

    return Opacity(
      opacity: isCompleted ? 0.6 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 5,
                height: 78,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.grey.shade400
                      : event.scheduleType.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.grey.shade100
                      : event.scheduleType.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : event.scheduleType.icon,
                  color: isCompleted
                      ? Colors.grey.shade500
                      : event.scheduleType.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity title
                      Text(
                        event.activity.isNotEmpty
                            ? event.activity
                            : 'Untitled event',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted ? Colors.grey.shade500 : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Time + location row
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.time,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (event.location.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                event.location,
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Pet badge + Type badge
                      if (event.petName.isNotEmpty ||
                          event.scheduleType != ScheduleType.other) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (event.petName.isNotEmpty) ...[
                              Icon(
                                Icons.pets,
                                size: 12,
                                color: colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.petName,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (event.petName.isNotEmpty &&
                                event.scheduleType != ScheduleType.other)
                              const SizedBox(width: 8),
                            if (event.scheduleType != ScheduleType.other)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: event.scheduleType.color.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  event.scheduleType.displayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: event.scheduleType.color,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Status chip
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: isCompleted
                    ? Icon(Icons.chevron_right, color: Colors.grey.shade400)
                    : Icon(
                        Icons.chevron_right,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Calendar card ─────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.viewModel});
  final CalendarViewModel viewModel;

  bool _isEventDay(int day) {
    return viewModel.events.any((event) {
      if (event.startDateTime == null) return event.day == day;
      return event.startDateTime!.day == day &&
          event.startDateTime!.month == viewModel.currentMonth &&
          event.startDateTime!.year == viewModel.currentYear;
    });
  }

  bool _areAllEventsCompleted(int day) {
    final dayEvents = viewModel.events.where((event) {
      if (event.startDateTime == null) return event.day == day;
      return event.startDateTime!.day == day &&
          event.startDateTime!.month == viewModel.currentMonth &&
          event.startDateTime!.year == viewModel.currentYear;
    });
    if (dayEvents.isEmpty) return false;
    return dayEvents.every((event) => event.isCompleted);
  }

  /// Builds compact week rows without trailing empty rows.
  static List<Widget> _buildWeekRows({
    required List<int?> days,
    required CalendarViewModel viewModel,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool Function(int) isEventDay,
    required bool Function(int) areAllEventsCompleted,
  }) {
    final now = DateTime.now();
    final numWeeks = (days.length / 7).ceil();
    return List.generate(numWeeks, (week) {
      return Padding(
        padding: EdgeInsets.only(bottom: week < numWeeks - 1 ? 2 : 0),
        child: Row(
          children: List.generate(7, (col) {
            final idx = week * 7 + col;
            final day = idx < days.length ? days[idx] : null;
            if (day == null) {
              return const Expanded(child: SizedBox(height: 40));
            }
            final hasEvent = isEventDay(day);
            final allCompleted = areAllEventsCompleted(day);
            final isSelected = day == viewModel.selectedDay;
            final isToday =
                day == now.day &&
                viewModel.currentMonth == now.month &&
                viewModel.currentYear == now.year;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => viewModel.selectDay(day),
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: isSelected
                        ? _PawSelectedDay(
                            day: day,
                            hasEvent: hasEvent,
                            allCompleted: allCompleted,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          )
                        : Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? colorScheme.primary.withValues(alpha: 0.08)
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                              border: isToday
                                  ? Border.all(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: (col >= 5)
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    color: (col >= 5)
                                        ? Colors.grey.shade500
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                if (hasEvent)
                                  Positioned(
                                    bottom: 3,
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: allCompleted
                                            ? Colors.grey.shade400
                                            : colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final days = viewModel.days;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: viewModel.goToPreviousMonth,
                  splashRadius: 20,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      viewModel.monthYearLabel,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: viewModel.goToNextMonth,
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          // Calendar grid
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                // Weekday row
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: const [
                      _WeekdayLabel(label: 'Mo'),
                      _WeekdayLabel(label: 'Tu'),
                      _WeekdayLabel(label: 'We'),
                      _WeekdayLabel(label: 'Th'),
                      _WeekdayLabel(label: 'Fr'),
                      _WeekdayLabel(label: 'Sa'),
                      _WeekdayLabel(label: 'Su'),
                    ],
                  ),
                ),
                // Day rows – built manually for compact sizing
                ..._buildWeekRows(
                  days: days,
                  viewModel: viewModel,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  isEventDay: _isEventDay,
                  areAllEventsCompleted: _areAllEventsCompleted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paw selected day ─────────────────────────────────────────────────────────

class _PawSelectedDay extends StatelessWidget {
  final int day;
  final bool hasEvent;
  final bool allCompleted;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _PawSelectedDay({
    required this.day,
    required this.hasEvent,
    required this.allCompleted,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(36, 36),
          painter: _PawPainter(color: colorScheme.primary),
        ),
        Text(
          '$day',
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (hasEvent)
          Positioned(
            bottom: 2,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: allCompleted ? Colors.grey.shade300 : Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Paw painter ───────────────────────────────────────────────────────────────

class _PawPainter extends CustomPainter {
  final Color color;
  _PawPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.52),
        width: w * 0.52,
        height: h * 0.48,
      ),
      paint,
    );

    void drawToe(
      double x,
      double y,
      double width,
      double height,
      double angle,
    ) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: width, height: height),
        paint,
      );
      canvas.restore();
    }

    final toeW = w * 0.15;
    final toeH = h * 0.22;
    drawToe(w * 0.20, h * 0.25, toeW, toeH, -0.4);
    drawToe(w * 0.38, h * 0.10, toeW, toeH, -0.15);
    drawToe(w * 0.62, h * 0.10, toeW, toeH, 0.15);
    drawToe(w * 0.80, h * 0.25, toeW, toeH, 0.4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Weekday label ─────────────────────────────────────────────────────────────

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isWeekend = label == 'Sa' || label == 'Su';
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isWeekend ? Colors.grey.shade400 : Colors.grey.shade500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Month stat widget ─────────────────────────────────────────────────────────

class _MonthStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MonthStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
