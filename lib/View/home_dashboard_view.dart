// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Ensure these imports point to your actual files
import '../models/pet_info.dart';
import '../ViewModel/home_dashboard_view_model.dart';
import '../ViewModel/home_view_model.dart';
import 'pet_detail_view.dart';
import 'schedule_detail_view.dart';

class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Try to access HomeViewModel - it may not exist if accessed directly
    final homeViewModel = context.read<HomeViewModel?>();

    return ChangeNotifierProvider(
      create: (_) => HomeDashboardViewModel(),
      child: _HomeDashboardContent(homeViewModel: homeViewModel),
    );
  }
}

class _HomeDashboardContent extends StatelessWidget {
  const _HomeDashboardContent({this.homeViewModel});

  final HomeViewModel? homeViewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dashboardViewModel = context.watch<HomeDashboardViewModel>();

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: dashboardViewModel.isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Loading your dashboard...',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: dashboardViewModel.refreshDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // --- Gradient Header ---
                      _buildHeader(
                        context,
                        colorScheme,
                        textTheme,
                        dashboardViewModel,
                      ),

                      const SizedBox(height: 70),

                      // --- Main Content ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Upcoming Card ---
                            const _SectionHeader(
                              title: 'Upcoming',
                              icon: Icons.event_note,
                            ),
                            const SizedBox(height: 12),
                            _buildUpcomingCard(
                              context,
                              colorScheme,
                              dashboardViewModel,
                            ),

                            const SizedBox(height: 28),

                            // --- Your Pets (DYNAMIC) ---
                            const _SectionHeader(
                              title: 'Your Pets',
                              icon: Icons.pets,
                            ),
                            const SizedBox(height: 14),

                            if (dashboardViewModel.pets.isEmpty)
                              _buildEmptyPetsState(context, dashboardViewModel)
                            else
                              SizedBox(
                                height:
                                    215, // Adjusted to fit the bigger avatar
                                child: Builder(
                                  builder: (context) {
                                    final petsList = dashboardViewModel.pets;
                                    final bool showMoreCard =
                                        petsList.length > 3;
                                    final int itemCount = showMoreCard
                                        ? 4
                                        : petsList.length;

                                    return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: itemCount,
                                      itemBuilder: (context, index) {
                                        // If we reach the 4th item, render the "+X More" card
                                        if (showMoreCard && index == 3) {
                                          final remaining = petsList.length - 3;
                                          return _ViewMorePetsCard(
                                            remainingCount: remaining,
                                            onTap: () =>
                                                dashboardViewModel.openPetsList(
                                                  context,
                                                  homeViewModel,
                                                ),
                                          );
                                        }

                                        final pet = petsList[index];
                                        final colors = _getPetCardColors(index);
                                        return _PetHomeCard(
                                          pet: pet,
                                          colors: colors,
                                          onTap: () => _openPetDetail(
                                            context,
                                            pet,
                                            dashboardViewModel,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                            const SizedBox(height: 28),

                            // --- Community Tips (DYNAMIC) ---
                            const _SectionHeader(
                              title: 'Community Tips',
                              icon: Icons.local_library_outlined,
                            ),
                            const SizedBox(height: 12),

                            if (dashboardViewModel.randomTips.isEmpty)
                              _buildEmptyTipsState(context)
                            else ...[
                              SizedBox(
                                height: 180,
                                child: PageView.builder(
                                  controller:
                                      dashboardViewModel.tipPageController,
                                  itemCount:
                                      dashboardViewModel.randomTips.length,
                                  itemBuilder: (context, index) {
                                    final tip =
                                        dashboardViewModel.randomTips[index];
                                    return _CommunityTipCard(
                                      tip: tip,
                                      onTap: () => _showTipDetail(context, tip),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: SmoothPageIndicator(
                                  controller:
                                      dashboardViewModel.tipPageController,
                                  count: dashboardViewModel.randomTips.length,
                                  effect: ExpandingDotsEffect(
                                    dotHeight: 8,
                                    dotWidth: 8,
                                    activeDotColor: colorScheme.primary,
                                    dotColor: Colors.grey.shade300,
                                    expansionFactor: 3,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    HomeDashboardViewModel vm,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          width: double.infinity,
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
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: -40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => homeViewModel?.goToProfileTab(),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              backgroundImage: vm.profileImageUrl != null
                                  ? NetworkImage(vm.profileImageUrl!)
                                  : null,
                              child: vm.profileImageUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Welcome back,',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${vm.userName} 👋',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => vm.openNotifications(context),
                        icon: Stack(
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 26,
                            ),
                            if (vm.hasUnreadNotifications)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: -55,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickActionButton(
                  icon: Icons.center_focus_strong,
                  label: 'Scan',
                  gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                  onTap: () => homeViewModel?.goToScanTab(),
                ),
                _QuickActionButton(
                  icon: Icons.pets,
                  label: 'Add Pet',
                  gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                  onTap: () => vm.addPet(context),
                ),
                _QuickActionButton(
                  icon: Icons.calendar_month,
                  label: 'Calendar',
                  gradient: const [Color(0xFFFF8008), Color(0xFFFFC837)],
                  onTap: () => homeViewModel?.goToCalendarTab(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingCard(
    BuildContext context,
    ColorScheme colorScheme,
    HomeDashboardViewModel vm,
  ) {
    return GestureDetector(
      onTap: () => _openUpcomingSchedule(context, vm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary.withValues(alpha: 0.08), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Today's Focus",
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vm.upcomingItem,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPetsState(BuildContext context, HomeDashboardViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.pets, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No pets added yet',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => vm.addPet(context),
            child: const Text('Add your first pet'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTipsState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No community tips available right now.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getPetCardColors(int index) {
    final colorSets = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFFFF8008), const Color(0xFFFFC837)],
      [const Color(0xFFEB3349), const Color(0xFFF45C43)],
      [const Color(0xFF4568DC), const Color(0xFFB06AB3)],
    ];
    return colorSets[index % colorSets.length];
  }

  void _openPetDetail(
    BuildContext context,
    PetHomeInfo pet,
    HomeDashboardViewModel vm,
  ) {
    final petInfo = PetInfo(
      id: pet.id,
      name: pet.name,
      species: pet.speciesRaw,
      breed: pet.species, // display subtitle is the breed name
      age: pet.age,
      gender: pet.gender,
      colour: pet.colour,
      dateOfBirth: pet.dateOfBirth,
      breedId: pet.breedId,
      userId: pet.userId,
      photoUrl: pet.photoUrl,
      photoUrls: pet.photoUrls,
      weightKg: pet.weightKg,
      galleryImages: pet.galleryImages,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PetDetailView(pet: petInfo)),
    ).then((_) => vm.refreshDashboard());
  }

  void _openUpcomingSchedule(BuildContext context, HomeDashboardViewModel vm) {
    final event = vm.upcomingEvent;
    if (event != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScheduleDetailView(event: event)),
      ).then((_) => vm.refreshDashboard());
    } else {
      // No specific event, go to calendar tab
      homeViewModel?.goToCalendarTab();
    }
  }

  void _showTipDetail(BuildContext context, CommunityTip tip) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.55,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tip.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tip.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tip.description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Section Header Widget ---
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurface),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// --- Quick Action Button Widget ---
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Pet Card Widget (Original Layout, Adjusted Sizes) ---
class _PetHomeCard extends StatelessWidget {
  final PetHomeInfo pet;
  final List<Color> colors;
  final VoidCallback? onTap;

  const _PetHomeCard({required this.pet, required this.colors, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = pet.photoUrl != null && pet.photoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 14, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Gradient top background
            Container(
              height: 80, // Slightly taller to fit the bigger avatar
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              // Subtle decorative circles
              child: Stack(
                children: [
                  Positioned(
                    top: -12,
                    right: -12,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -8,
                    left: -8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content below the avatar (Moved down)
            Positioned.fill(
              top: 115, // Increased top padding to push text down
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    // Pet name
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF2D3142),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Breed badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.first.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pet.species,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.first,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating avatar (Made larger)
            Positioned(
              left: 0,
              right: 0,
              top: 30,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ), // Thicker border
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 36, // INCREASED FROM 28 TO 36
                    backgroundColor: colors.first.withValues(alpha: 0.2),
                    backgroundImage: hasPhoto
                        ? NetworkImage(pet.photoUrl!)
                        : null,
                    child: !hasPhoto
                        ? const Icon(
                            Icons.pets_rounded,
                            color: Colors.white,
                            size: 32, // Made placeholder icon bigger too
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Age badge (top-right corner)
            if (pet.age.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    pet.age,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.first,
                    ),
                  ),
                ),
              ),

            // Chevron indicator (bottom-right)
            Positioned(
              bottom: 14,
              right: 14,
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colors.first.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- View More Pets Card (NEW WIDGET) ---
class _ViewMorePetsCard extends StatelessWidget {
  final int remainingCount;
  final VoidCallback onTap;

  const _ViewMorePetsCard({required this.remainingCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120, // Slightly slimmer than the standard 150 card
        margin: const EdgeInsets.only(right: 14, bottom: 8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.04), // soft background
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'View All',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Community Tip Card Widget ---
class _CommunityTipCard extends StatelessWidget {
  final CommunityTip tip;
  final VoidCallback? onTap;

  const _CommunityTipCard({required this.tip, this.onTap});

  // Helper Logic moved inside widget to auto-style based on category string
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hydration':
        return const Color(0xFF45B7D1);
      case 'exercise':
        return const Color(0xFF4ECDC4);
      case 'health check':
        return const Color(0xFFFF6B6B);
      case 'grooming':
        return const Color(0xFFFFBE0B);
      case 'nutrition':
        return const Color(0xFF667EEA);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hydration':
        return Icons.water_drop_outlined;
      case 'exercise':
        return Icons.fitness_center_outlined;
      case 'health check':
        return Icons.medical_services_outlined;
      case 'grooming':
        return Icons.clean_hands_outlined;
      case 'nutrition':
        return Icons.restaurant_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic styles based on data
    final iconColor = _getCategoryColor(tip.category);
    final icon = _getCategoryIcon(tip.category);
    final gradient = [iconColor.withValues(alpha: 0.1), Colors.white];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tip.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tip.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                tip.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
