// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pet_bottom_nav.dart';
import '../View/calendar_view.dart';
import '../View/pet_profile_view.dart';
import '../View/profile_view.dart';
import '../View/scan_view.dart';
import '../ViewModel/home_view_model.dart';
import 'home_dashboard_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    int initialIndex = 0;
    DateTime? calendarDate;

    // --- SAFE ARGUMENT PARSING ---
    if (args is int) {
      // If we just passed a number (e.g. 1)
      initialIndex = args;
    } else if (args is Map) {
      // If we passed complex data (e.g. {'tab': 1, 'date': ...})
      if (args['tab'] is int) initialIndex = args['tab'];
      if (args['date'] is DateTime) calendarDate = args['date'];
    }

    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = HomeViewModel();
        if (initialIndex != 0) {
          viewModel.setInitialTab(initialIndex);
        }
        return viewModel;
      },
      // Pass the date down to the Scaffold
      child: _HomeScaffold(initialCalendarDate: calendarDate),
    );
  }
}

class _HomeScaffold extends StatefulWidget {
  final DateTime? initialCalendarDate;

  const _HomeScaffold({this.initialCalendarDate});

  @override
  State<_HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<_HomeScaffold> {
  int _previousIndex = 0;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final currentIndex = viewModel.selectedIndex;
    final goingForward = currentIndex >= _previousIndex;

    // Update previous index after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_previousIndex != currentIndex) {
        _previousIndex = currentIndex;
      }
    });

    final pages = [
      const HomeDashboardView(),
      CalendarView(initialDate: widget.initialCalendarDate),
      const ScanView(),
      const PetProfileView(),
      const ProfileView(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final isEntering = child.key == ValueKey(currentIndex);

          // Slide + Fade transition
          final slideOffset = isEntering
              ? (goingForward ? const Offset(0.15, 0) : const Offset(-0.15, 0))
              : (goingForward ? const Offset(-0.15, 0) : const Offset(0.15, 0));

          return SlideTransition(
            position: Tween<Offset>(
              begin: slideOffset,
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(currentIndex),
          child: pages[currentIndex],
        ),
      ),
      bottomNavigationBar: PetBottomNavBar(
        currentIndex: currentIndex,
        onTabSelected: viewModel.selectTab,
        onScanPressed: viewModel.goToScanTab,
      ),
    );
  }
}
