import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../calendar_event.dart';
import '../models/pet_info.dart';
import '../models/reminder_duration.dart';
import '../models/schedule_type.dart';
import '../View/edit_pet_view.dart';
import '../View/pet_gallery_view.dart';
import '../View/schedule_detail_view.dart';
import 'base_view_model.dart';

class PetDetailViewModel extends BaseViewModel {
  PetDetailViewModel(PetInfo pet) : _pet = pet {
    _fetchNextSchedule();
    _loadNotes();
  }

  PetInfo _pet;
  PetInfo get pet => _pet;

  // --- Next Schedule ---
  CalendarEvent? _nextScheduleEvent;
  CalendarEvent? get nextScheduleEvent => _nextScheduleEvent;

  String _nextScheduleLabel = '';
  String get nextScheduleLabel => _nextScheduleLabel;

  bool _isLoadingSchedule = true;
  bool get isLoadingSchedule => _isLoadingSchedule;

  // --- Notes ---
  String _notes = '';
  String get notes => _notes;

  bool _isLoadingNotes = true;
  bool get isLoadingNotes => _isLoadingNotes;

  bool get isDog => _pet.species.toLowerCase() == 'dog';

  Future<void> refreshPet() async {
    final petId = _pet.id;
    if (petId == null || petId.isEmpty) return;

    setLoading(true);
    setError(null);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pet')
          .doc(petId)
          .get();
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final dobValue = data['dateOfBirth'];
      final DateTime? dateOfBirth = dobValue is Timestamp
          ? dobValue.toDate()
          : null;
      final breedId = data['breedId'] as String?;
      String breedName = _pet.breed;
      if (breedId != null && breedId.isNotEmpty) {
        final breedDoc = await FirebaseFirestore.instance
            .collection('breed')
            .doc(breedId)
            .get();
        if (breedDoc.exists) {
          final breedData = breedDoc.data();
          final name = breedData?['breedName'] as String?;
          if (name != null && name.isNotEmpty) {
            breedName = name;
          }
        }
      }

      final photoUrls = (data['photoUrls'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList();
      final weightValue = data['weightKg'];
      final double? weightKg = weightValue is num
          ? weightValue.toDouble()
          : null;

      _pet = PetInfo(
        id: data['petId'] as String? ?? petId,
        name: (data['petName'] as String?) ?? _pet.name,
        species: (data['species'] as String?) ?? _pet.species,
        gender: data['gender'] as String?,
        colour: data['colour'] as String?,
        dateOfBirth: dateOfBirth,
        breed: breedName,
        breedId: breedId,
        userId: data['userId'] as String?,
        photoUrl: data['photoUrl'] as String?,
        photoUrls: photoUrls,
        weightKg: weightKg,
        age: dateOfBirth != null ? _formatAge(dateOfBirth) : _pet.age,
        galleryImages: _pet.galleryImages,
        notes: data['notes'] as String?,
      );

      _notes = _pet.notes ?? '';
      notifyListeners();

      // Refresh schedule too
      await _fetchNextSchedule();
    } catch (error) {
      setError(error.toString());
    } finally {
      setLoading(false);
    }
  }

  // --- Schedule Fetching ---
  Future<void> _fetchNextSchedule() async {
    _isLoadingSchedule = true;
    notifyListeners();

    try {
      final petId = _pet.id;
      if (petId == null || petId.isEmpty) {
        _nextScheduleLabel = 'No upcoming schedule';
        _nextScheduleEvent = null;
        _isLoadingSchedule = false;
        notifyListeners();
        return;
      }

      final now = DateTime.now();
      final schedulesSnap = await FirebaseFirestore.instance
          .collection('schedules')
          .where('petId', isEqualTo: petId)
          .get();

      DateTime? nearestDate;
      QueryDocumentSnapshot<Map<String, dynamic>>? nearestDoc;

      for (final doc in schedulesSnap.docs) {
        final data = doc.data();
        final isCompleted = data['isCompleted'] as bool? ?? false;
        if (isCompleted) continue;

        final ts = data['startDateTime'] as Timestamp?;
        if (ts == null) continue;
        final dt = ts.toDate();
        if (dt.isBefore(now)) continue;

        if (nearestDate == null || dt.isBefore(nearestDate)) {
          nearestDate = dt;
          nearestDoc = doc;
        }
      }

      if (nearestDoc != null && nearestDate != null) {
        final data = nearestDoc.data();
        final title = data['scheTitle'] as String? ?? 'Untitled';
        final diff = nearestDate.difference(now);
        String when;
        if (diff.inDays == 0) {
          when = 'Today';
        } else if (diff.inDays == 1) {
          when = 'Tomorrow';
        } else {
          when = 'In ${diff.inDays} days';
        }
        _nextScheduleLabel = '$title — $when';

        final startTs = data['startDateTime'] as Timestamp?;
        final endTs = data['endDateTime'] as Timestamp?;
        final reminderTs = data['reminderDateTime'] as Timestamp?;

        _nextScheduleEvent = CalendarEvent(
          day: nearestDate.day,
          petName: _pet.name,
          activity: title,
          location: data['scheDescription'] as String? ?? '',
          time: _formatTime(startTs?.toDate()),
          scheduleId: nearestDoc.id,
          startDateTime: startTs?.toDate(),
          endDateTime: endTs?.toDate(),
          isCompleted: data['isCompleted'] as bool? ?? false,
          petId: petId,
          scheduleType: ScheduleType.fromFirestore(
            data['scheduleType'] as String?,
          ),
          reminderEnabled: data['reminderEnabled'] as bool? ?? false,
          reminderDateTime: reminderTs?.toDate(),
          reminderDuration: ReminderDurationExtension.fromString(
            data['reminderDuration'] as String?,
          ),
        );
      } else {
        _nextScheduleLabel = 'No upcoming schedule';
        _nextScheduleEvent = null;
      }
    } catch (e) {
      _nextScheduleLabel = 'No upcoming schedule';
      _nextScheduleEvent = null;
      debugPrint('Error fetching next schedule: $e');
    } finally {
      _isLoadingSchedule = false;
      notifyListeners();
    }
  }

  // --- Notes ---
  Future<void> _loadNotes() async {
    _isLoadingNotes = true;
    notifyListeners();

    try {
      final petId = _pet.id;
      if (petId == null || petId.isEmpty) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('pet')
          .doc(petId)
          .get();
      if (!snapshot.exists) return;

      final data = snapshot.data();
      _notes = (data?['notes'] as String?) ?? '';
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoadingNotes = false;
      notifyListeners();
    }
  }

  Future<void> saveNotes(String notes) async {
    final petId = _pet.id;
    if (petId == null || petId.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('pet').doc(petId).update({
        'notes': notes,
      });

      _notes = notes;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving notes: $e');
    }
  }

  void navigateToSchedule(BuildContext context) {
    if (_nextScheduleEvent == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleDetailView(event: _nextScheduleEvent!),
      ),
    ).then((_) => _fetchNextSchedule());
  }

  // --- Navigation ---
  void onBackPressed(BuildContext context) {
    Navigator.pop(context);
  }

  void onEditPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPetView(pet: pet)),
    );
  }

  void onViewGalleryPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PetGalleryView(pet: pet)),
    );
  }

  void onConfirmRemovalPressed(BuildContext context) {
    confirmRemoval(context);
  }

  Future<void> confirmRemoval(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove pet'),
        content: Text('Are you sure you want to remove ${pet.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) {
        return;
      }
      Navigator.pop(context, true);
    }
  }

  // --- Helpers ---
  String _formatAge(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (now.day < dob.day) {
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    if (years <= 0) {
      return '$months months';
    }
    if (months == 0) {
      return '$years years';
    }
    return '$years years $months months';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
