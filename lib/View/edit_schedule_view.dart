import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../calendar_event.dart';
import '../models/pet_info.dart';
import '../models/reminder_duration.dart';
import '../ViewModel/edit_schedule_view_model.dart';
import '../ViewModel/pet_profile_view_model.dart';
import 'add_pet_view.dart';

class EditScheduleView extends StatelessWidget {
  final CalendarEvent event;

  const EditScheduleView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditScheduleViewModel(event),
      child: const _EditScheduleBody(),
    );
  }
}

class _EditScheduleBody extends StatelessWidget {
  const _EditScheduleBody();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<EditScheduleViewModel>();
    final petVm = context.watch<PetProfileViewModel>();
    final pets = petVm.pets;
    viewModel.syncSelectedPet(pets);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Gradient Header ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 12,
                left: 20,
                right: 20,
                bottom: 24,
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
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Edit Schedule',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_calendar_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update your schedule',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Modify the details below',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // --- Form Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: viewModel.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Time Card
                      _FormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _IconBox(
                                  icon: Icons.calendar_today_rounded,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'Date & Time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => viewModel.pickStartDateTime(context),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.play_circle_outline_rounded,
                                      color: Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        viewModel.startLabel,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit_rounded,
                                      color: colorScheme.primary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => viewModel.pickEndDateTime(context),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.stop_circle_outlined,
                                      color: Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        viewModel.endLabel,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit_rounded,
                                      color: colorScheme.primary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Pet Name
                      _FormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _IconBox(
                                  icon: Icons.pets_rounded,
                                  color: Color(0xFF4ECDC4),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'Pet Name',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<PetInfo?>(
                              initialValue: viewModel.selectedPet,
                              decoration: InputDecoration(
                                hintText: 'Select pet (optional)',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              items: [
                                const DropdownMenuItem<PetInfo?>(
                                  value: null,
                                  child: Text('No pet'),
                                ),
                                ...pets.map(
                                  (pet) => DropdownMenuItem<PetInfo?>(
                                    value: pet,
                                    child: Text(pet.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  viewModel.selectedPet = value,
                            ),
                            if (pets.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'No pets found. You can keep this schedule without linking a pet.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AddPetView(),
                                    ),
                                  ),
                                  child: const Text('Add Pet'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Activity
                      _FormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _IconBox(
                                  icon: Icons.event_rounded,
                                  color: Color(0xFF667EEA),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'Activity',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: viewModel.titleController,
                              decoration: InputDecoration(
                                hintText: 'e.g. Vet checkup, Grooming',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              validator: (v) =>
                                  v?.trim().isEmpty == true ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Location
                      _FormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _IconBox(
                                  icon: Icons.location_on_rounded,
                                  color: Color(0xFFFF6B6B),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'Description / Location',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: viewModel.descriptionController,
                              decoration: InputDecoration(
                                hintText: 'Enter location',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              maxLines: 3,
                              validator: (v) =>
                                  v?.trim().isEmpty == true ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Reminder
                      _FormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _IconBox(
                                  icon: Icons.notifications_active_rounded,
                                  color: Color(0xFFFFBE0B),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'Reminder',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const Spacer(),
                                Switch(
                                  value: viewModel.reminderEnabled,
                                  onChanged: viewModel.setReminderEnabled,
                                ),
                              ],
                            ),
                            if (viewModel.reminderEnabled) ...[
                              const SizedBox(height: 12),
                              _ReminderDurationPicker(
                                selectedDuration: viewModel.reminderDuration,
                                onChanged: viewModel.setReminderDuration,
                                onCustomTimeTap: () =>
                                    viewModel.pickReminderDateTime(context),
                                customReminderTime: viewModel.reminderDateTime,
                                colorScheme: colorScheme,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () => viewModel.saveChanges(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.primary.withValues(
                                        alpha: 0.8,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// --- Helper: Reminder Duration Picker ---
class _ReminderDurationPicker extends StatelessWidget {
  final ReminderDuration selectedDuration;
  final ValueChanged<ReminderDuration> onChanged;
  final VoidCallback onCustomTimeTap;
  final DateTime? customReminderTime;
  final ColorScheme colorScheme;

  const _ReminderDurationPicker({
    required this.selectedDuration,
    required this.onChanged,
    required this.onCustomTimeTap,
    required this.customReminderTime,
    required this.colorScheme,
  });

  static const _presets = [
    ReminderDuration.oneMinute,
    ReminderDuration.threeMinutes,
    ReminderDuration.fiveMinutes,
    ReminderDuration.tenMinutes,
    ReminderDuration.fifteenMinutes,
    ReminderDuration.thirtyMinutes,
    ReminderDuration.oneHour,
    ReminderDuration.twoHours,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Preset chips ---
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final duration in _presets)
              _DurationChip(
                label: duration.shortName,
                selected: selectedDuration == duration,
                onTap: () => onChanged(duration),
                colorScheme: colorScheme,
              ),
          ],
        ),

        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 10),

        // --- Custom time row ---
        InkWell(
          onTap: () {
            onChanged(ReminderDuration.customTime);
            onCustomTimeTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selectedDuration == ReminderDuration.customTime
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedDuration == ReminderDuration.customTime
                    ? colorScheme.primary
                    : Colors.grey.shade200,
                width: selectedDuration == ReminderDuration.customTime ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: selectedDuration == ReminderDuration.customTime
                      ? colorScheme.primary
                      : Colors.grey.shade500,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedDuration == ReminderDuration.customTime &&
                            customReminderTime != null
                        ? 'At ${_formatTime(customReminderTime!)}'
                        : 'Choose a specific time…',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selectedDuration == ReminderDuration.customTime
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: selectedDuration == ReminderDuration.customTime
                          ? colorScheme.primary
                          : const Color(0xFF888888),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: selectedDuration == ReminderDuration.customTime
                      ? colorScheme.primary
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final months = [
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
    return '${months[dt.month - 1]} ${dt.day}, $hour:$minute $period';
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}
