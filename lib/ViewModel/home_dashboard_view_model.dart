import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../calendar_event.dart';
import '../View/add_pet_view.dart';
import '../View/notifications_view.dart';
import 'base_view_model.dart';
import 'home_view_model.dart';

class HomeDashboardViewModel extends BaseViewModel {
  final PageController tipPageController = PageController();
  Timer? _timer;

  // --- State Variables ---
  List<PetHomeInfo> _pets = [];
  List<CommunityTip> _randomTips = [];
  String _upcomingItem = 'No upcoming events today';
  String? _upcomingScheduleId;
  CalendarEvent? _upcomingEvent;
  bool _isLoading = true;
  String _userName = '';
  String? _profileImageUrl;

  // --- Getters ---
  List<PetHomeInfo> get pets => List.unmodifiable(_pets);
  List<CommunityTip> get randomTips => List.unmodifiable(_randomTips);
  String get upcomingItem => _upcomingItem;
  String? get upcomingScheduleId => _upcomingScheduleId;
  CalendarEvent? get upcomingEvent => _upcomingEvent;
  String get userName => _userName;
  String? get profileImageUrl => _profileImageUrl;
  @override
  bool get isLoading => _isLoading;

  HomeDashboardViewModel() {
    _loadDashboardData();
  }

  Future<void> refreshDashboard() async {
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _fetchUserProfile(),
      _fetchUserPets(),
      _fetchRandomTips(),
      _fetchUpcomingSchedule(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  // --- 0. Fetch User Profile (name + avatar) ---
  Future<void> _fetchUserProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      _userName = 'Guest';
      return;
    }

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('user')
          .where('providerId', isEqualTo: authUser.uid)
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        final data = userSnap.docs.first.data();
        _userName = data['userName'] ?? 'User';
        _profileImageUrl = (data['profileImageUrl'] ?? data['photoUrl'])
            ?.toString();
      } else {
        _userName = authUser.displayName ?? 'User';
      }
    } catch (e) {
      _userName = authUser.displayName ?? 'User';
    }
  }

  // --- 1. Fetch User Pets (Mirroring PetProfileViewModel logic) ---
  Future<void> _fetchUserPets() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    try {
      // Step A: Resolve Custom User ID (U0000X)
      // The pets are stored under the custom user ID, NOT the Auth UID.
      final userSnap = await FirebaseFirestore.instance
          .collection('user')
          .where('providerId', isEqualTo: authUser.uid)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) return;
      final customUserId = userSnap.docs.first.id;

      // Step B: Load Breeds Map (ID -> Name) to display "Golden Retriever" instead of "Dog"
      final breedSnap = await FirebaseFirestore.instance
          .collection('breed')
          .get();
      final Map<String, String> breedMap = {
        for (final doc in breedSnap.docs)
          doc.id: (doc.data()['breedName'] as String?) ?? '',
      };

      // Step C: Query 'pet' collection (singular)
      final petsSnap = await FirebaseFirestore.instance
          .collection('pet')
          .where('userId', isEqualTo: customUserId)
          .get();

      // Step D: Map data to UI Model
      _pets = petsSnap.docs.map((doc) {
        final data = doc.data();

        // 1. Calculate Age
        String ageString = 'N/A';
        if (data['dateOfBirth'] != null) {
          // Correct field name: 'dateOfBirth'
          try {
            DateTime dob;
            if (data['dateOfBirth'] is Timestamp) {
              dob = (data['dateOfBirth'] as Timestamp).toDate();
            } else {
              dob = DateTime.parse(data['dateOfBirth'].toString());
            }
            ageString = _calculateAge(dob);
          } catch (e) {
            debugPrint("Error parsing date: $e");
          }
        }

        // 2. Determine Display Species (Breed Name)
        // If we have a breedId, use the breed name. Otherwise fallback to species or "Pet".
        String displaySubtitle = data['species'] ?? 'Pet';
        final breedId = data['breedId'] as String?;
        if (breedId != null && breedMap.containsKey(breedId)) {
          displaySubtitle = breedMap[breedId]!;
        }

        // Parse dateOfBirth for the model
        DateTime? dob;
        if (data['dateOfBirth'] != null) {
          try {
            if (data['dateOfBirth'] is Timestamp) {
              dob = (data['dateOfBirth'] as Timestamp).toDate();
            } else {
              dob = DateTime.parse(data['dateOfBirth'].toString());
            }
          } catch (_) {}
        }

        // Parse gallery images
        final List<String> gallery =
            (data['galleryImages'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        // Parse photo URLs list
        final List<String> photoUrlsList =
            (data['photoUrls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        return PetHomeInfo(
          id: doc.id,
          name: data['petName'] ?? 'Unknown',
          species: displaySubtitle,
          speciesRaw: data['species'] ?? 'Pet',
          lastScan: 'No scans yet',
          age: ageString,
          gender: data['gender'] as String?,
          colour: data['colour'] as String?,
          dateOfBirth: dob,
          breedId: breedId,
          userId: customUserId,
          photoUrl: data['photoUrl'] as String?,
          photoUrls: photoUrlsList,
          weightKg: (data['weightKg'] as num?)?.toDouble(),
          galleryImages: gallery,
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching pets: $e");
    }
  }

  // Helper: Calculate Age (e.g., 2Y, 5M)
  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final days = difference.inDays;

    if (days >= 365) {
      return '${(days / 365).floor()}Y'; // Years
    } else if (days >= 30) {
      return '${(days / 30).floor()}M'; // Months
    } else {
      return '${days}D'; // Days
    }
  }

  // --- 2. Fetch Random Tips (Existing Logic) ---
  Future<void> _fetchRandomTips() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('community_tips')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final allTips = snapshot.docs
            .map((doc) => CommunityTip.fromFirestore(doc))
            .toList();

        allTips.shuffle(Random());
        _randomTips = allTips.take(5).toList();

        if (_randomTips.isNotEmpty) {
          _startAutoScroll();
        }
      }
    } catch (e) {
      debugPrint("Error fetching random tips: $e");
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (disposed || _randomTips.isEmpty || !tipPageController.hasClients) {
        return;
      }
      int nextPage = (tipPageController.page?.round() ?? 0) + 1;
      if (nextPage >= _randomTips.length) nextPage = 0;

      tipPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  // --- 3. Fetch Upcoming Schedule ---
  Future<void> _fetchUpcomingSchedule() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('user')
          .where('providerId', isEqualTo: authUser.uid)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) return;
      final customUserId = userSnap.docs.first.id;

      final now = DateTime.now();
      final schedulesSnap = await FirebaseFirestore.instance
          .collection('schedules')
          .where('userId', isEqualTo: customUserId)
          .get();

      // Find the nearest upcoming (non-completed) schedule
      DateTime? nearestDate;
      String? nearestTitle;
      String? nearestId;

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
          nearestTitle = data['scheTitle'] as String? ?? 'Untitled';
          nearestId = doc.id;
        }
      }

      if (nearestTitle != null && nearestDate != null) {
        final diff = nearestDate.difference(now);
        String when;
        if (diff.inDays == 0) {
          when = 'Today';
        } else if (diff.inDays == 1) {
          when = 'Tomorrow';
        } else {
          when = 'In ${diff.inDays} days';
        }
        _upcomingItem = '$nearestTitle — $when';
        _upcomingScheduleId = nearestId;

        // Build the CalendarEvent for direct navigation
        if (nearestId != null) {
          final nearestDoc = schedulesSnap.docs.firstWhere(
            (d) => d.id == nearestId,
          );
          final nData = nearestDoc.data();
          final startTs = nData['startDateTime'] as Timestamp?;
          final endTs = nData['endDateTime'] as Timestamp?;
          _upcomingEvent = CalendarEvent(
            day: nearestDate.day,
            petName: nData['petName'] as String? ?? '',
            activity: nData['scheTitle'] as String? ?? 'Untitled',
            location: nData['scheLocation'] as String? ?? '',
            time: _formatTime(startTs?.toDate()),
            scheduleId: nearestId,
            startDateTime: startTs?.toDate(),
            endDateTime: endTs?.toDate(),
            isCompleted: nData['isCompleted'] as bool? ?? false,
            petId: nData['petId'] as String?,
          );
        }
      } else {
        _upcomingItem = 'No upcoming events';
        _upcomingScheduleId = null;
        _upcomingEvent = null;
      }
    } catch (e) {
      _upcomingItem = 'No upcoming events';
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour;
    final m = dt.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:${m.toString().padLeft(2, '0')} $period';
  }

  // --- Navigation Actions ---
  void openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsView()),
    );
  }

  void addPet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPetView()),
    ).then((_) => _loadDashboardData()); // Refresh list when returning
  }

  void openPetsList(BuildContext context, HomeViewModel? homeViewModel) {
    if (homeViewModel != null) {
      homeViewModel.goToPetsTab();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Go to "Pets" tab to view details.')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    tipPageController.dispose();
    super.dispose();
  }
}

// --- Data Models (Internal) ---

class PetHomeInfo {
  final String? id;
  final String name;
  final String species;
  final String speciesRaw;
  final String lastScan;
  final String age;
  final String? gender;
  final String? colour;
  final DateTime? dateOfBirth;
  final String? breedId;
  final String? userId;
  final String? photoUrl;
  final List<String> photoUrls;
  final double? weightKg;
  final List<String> galleryImages;

  const PetHomeInfo({
    this.id,
    required this.name,
    required this.species,
    this.speciesRaw = '',
    required this.lastScan,
    this.age = '',
    this.gender,
    this.colour,
    this.dateOfBirth,
    this.breedId,
    this.userId,
    this.photoUrl,
    this.photoUrls = const [],
    this.weightKg,
    this.galleryImages = const [],
  });
}

class CommunityTip {
  final String id;
  final String category;
  final String title;
  final String description;

  CommunityTip({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
  });

  factory CommunityTip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityTip(
      id: doc.id,
      category: data['tipsCategory'] ?? 'General',
      title: data['tipsTitle'] ?? '',
      description: data['tipsDesc'] ?? '',
    );
  }
}
