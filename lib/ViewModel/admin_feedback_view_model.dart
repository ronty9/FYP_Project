import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_view_model.dart';
import '../models/feedback_model.dart';
import '../View/admin_feedback_detail_view.dart'; // <--- IMPORT YOUR DETAIL VIEW HERE

class AdminFeedbackViewModel extends BaseViewModel {
  List<FeedbackModel> _feedbackList = [];
  bool _isLoading = true;

  List<FeedbackModel> get feedbackList => _feedbackList;
  @override
  bool get isLoading => _isLoading;

  AdminFeedbackViewModel() {
    fetchFeedback();
  }

  Future<void> fetchFeedback() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .orderBy('createdAt', descending: true)
          .get();

      _feedbackList = snapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("Error fetching feedback: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- FIXED NAVIGATION FUNCTION ---
  Future<void> openFeedbackDetail(
    BuildContext context,
    FeedbackModel item,
  ) async {
    // We use MaterialPageRoute to directly navigate without needing main.dart routes
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminFeedbackDetailView(),
        // This passes the 'item' so ModalRoute.of(context) in the view still works
        settings: RouteSettings(arguments: item),
      ),
    );

    // Refresh list when coming back (in case status changed to 'Replied')
    fetchFeedback();
  }
}
