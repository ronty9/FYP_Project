import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'base_view_model.dart';

class FeedbackViewModel extends BaseViewModel {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  final List<String> categories = const [
    'General feedback',
    'Bug report',
    'Feature request',
    'UI/UX',
    'Performance',
  ];

  String _selectedCategory = 'General feedback';
  int _rating = 0; // Added rating state
  bool _isLoading = false;

  String get selectedCategory => _selectedCategory;
  int get rating => _rating;
  @override
  bool get isLoading => _isLoading;

  void selectCategory(String value) {
    if (_selectedCategory == value) return;
    _selectedCategory = value;
    notifyListeners();
  }

  void setRating(int value) {
    _rating = value;
    notifyListeners();
  }

  void onSubmitFeedbackPressed(BuildContext context) {
    submitFeedback(context);
  }

  Future<void> submitFeedback(BuildContext context) async {
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    // 1. Validation
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in subject and message.')),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    final firestore = FirebaseFirestore.instance;
    final counterRef = firestore.collection('counters').doc('feedbackCounter');

    try {
      await firestore.runTransaction((transaction) async {
        // 2. Generate Custom ID (FB000001)
        DocumentSnapshot counterSnapshot = await transaction.get(counterRef);
        int currentCount = 0;

        if (counterSnapshot.exists) {
          final data = counterSnapshot.data() as Map<String, dynamic>;
          currentCount = data['count'] ?? 0;
        }

        int newCount = currentCount + 1;
        String customId = 'FB${newCount.toString().padLeft(6, '0')}';

        // 3. Prepare Data
        final feedbackRef = firestore.collection('feedback').doc(customId);

        final feedbackData = {
          'feedbackId': customId,
          'userId': user.uid,
          'userEmail':
              user.email, // Optional: helpful for admin to see who sent it
          'feedbackCategory': _selectedCategory,
          'feedbackTitle': subject,
          'feedbackDesc': message,
          'rating': _rating,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Pending',
          'messageReply': null,
          'replyBy': null,
          'replyAt': null,
        };

        // 4. Write to DB
        transaction.set(counterRef, {'count': newCount});
        transaction.set(feedbackRef, feedbackData);
      });

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback sent successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error submitting feedback: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending feedback: $e')));
      }
    }
  }

  @override
  void dispose() {
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
