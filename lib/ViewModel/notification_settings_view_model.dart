import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_view_model.dart';
// IMPORTANT: Update this import to point to your actual NotificationService file!
import '../services/notification_service.dart';

class NotificationSettingsViewModel extends BaseViewModel {
  // --- Global Device States ---
  bool _allowPushNotifications = true;
  bool _playSound = true;
  bool _vibrate = true;

  // --- Getters ---
  bool get allowPushNotifications => _allowPushNotifications;
  bool get playSound => _playSound;
  bool get vibrate => _vibrate;

  // Constructor: Load settings immediately when the page opens
  NotificationSettingsViewModel() {
    _loadSettings();
  }

  // --- Load Settings from Local Storage ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // If a setting doesn't exist yet, it defaults to 'true'
    _allowPushNotifications = prefs.getBool('allowPushNotifications') ?? true;
    _playSound = prefs.getBool('playSound') ?? true;
    _vibrate = prefs.getBool('vibrate') ?? true;

    notifyListeners();
  }

  // --- Toggles (Saving to Local Storage & Calling Service) ---
  Future<void> togglePushNotifications(bool value) async {
    _allowPushNotifications = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allowPushNotifications', value);

    // If the user turns off master notifications, disable sound and vibration too,
    // AND cancel all currently pending notifications in the system!
    if (!value) {
      _playSound = false;
      _vibrate = false;
      await prefs.setBool('playSound', false);
      await prefs.setBool('vibrate', false);

      // Cancel all existing scheduled reminders immediately
      await NotificationService().cancelAllReminders();
    }

    notifyListeners();
  }

  Future<void> togglePlaySound(bool value) async {
    // Only allow turning on sound if master notifications are enabled
    if (_allowPushNotifications) {
      _playSound = value;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('playSound', value);

      notifyListeners();
    }
  }

  Future<void> toggleVibrate(bool value) async {
    // Only allow turning on vibration if master notifications are enabled
    if (_allowPushNotifications) {
      _vibrate = value;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vibrate', value);

      notifyListeners();
    }
  }

  void onShowInfoPressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'These settings control how schedule reminders appear on your device.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
