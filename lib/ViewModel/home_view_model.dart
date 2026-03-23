// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'base_view_model.dart';

class HomeViewModel extends BaseViewModel {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  // --- ADD THIS FUNCTION ---
  void setInitialTab(int index) {
    _selectedIndex = index;
  }
  // ------------------------

  void selectTab(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void goToScanTab() => selectTab(2);
  void goToCalendarTab() => selectTab(1);
  void goToPetsTab() => selectTab(3);
  void goToProfileTab() => selectTab(4);
}
