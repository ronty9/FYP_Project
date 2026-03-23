// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/foundation.dart';

/// Provides shared loading, message and error state for all view models.
enum MessageType { error, success, info, warning }

abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Whether this ViewModel has been disposed.
  bool get disposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void runAsync(Future<void> Function() operation) async {
    setLoading(true);
    setError(null);
    try {
      await operation();
    } catch (error) {
      setError(error.toString());
    } finally {
      setLoading(false);
    }
  }
}
