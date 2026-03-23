// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';

/// Reusable bottom navigation bar with a center Scan action.
class PetBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onScanPressed;

  const PetBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // background bar
              Positioned.fill(
                top: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NavIconButton(
                        // Provide both filled and outlined icons
                        filledIcon: Icons.home,
                        outlinedIcon: Icons.home_outlined,
                        label: 'Home',
                        isActive: currentIndex == 0,
                        onTap: () => onTabSelected(0),
                      ),
                      _NavIconButton(
                        filledIcon: Icons.calendar_today,
                        outlinedIcon: Icons.calendar_today_outlined,
                        label: 'Calendar',
                        isActive: currentIndex == 1,
                        onTap: () => onTabSelected(1),
                      ),
                      const SizedBox(width: 64), // Spacer for Scan button
                      _NavIconButton(
                        filledIcon: Icons.pets,
                        outlinedIcon: Icons.pets_outlined,
                        label: 'Pets',
                        isActive: currentIndex == 3,
                        onTap: () => onTabSelected(3),
                      ),
                      _NavIconButton(
                        filledIcon: Icons.person,
                        outlinedIcon: Icons.person_outline,
                        label: 'Profile',
                        isActive: currentIndex == 4,
                        onTap: () => onTabSelected(4),
                      ),
                    ],
                  ),
                ),
              ),
              // Center Scan Button
              Positioned(
                top: -6,
                child: GestureDetector(
                  onTap: onScanPressed,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // --- CHANGED: Use Theme Primary Color (Cobalt Blue) ---
                      color: colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'images/assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  // Changed to accept both icon types
  final IconData filledIcon;
  final IconData outlinedIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIconButton({
    required this.filledIcon,
    required this.outlinedIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use the darker, deeper blue for the active state
    final Color color = isActive
        ? const Color.fromARGB(255, 6, 15, 176)
        : colorScheme.onSurface.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Switch between filled and outlined icon based on state
            Icon(isActive ? filledIcon : outlinedIcon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
