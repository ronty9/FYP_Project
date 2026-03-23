// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'base_view_model.dart';
import '../models/feedback_model.dart';

class AdminFeedbackDetailViewModel extends BaseViewModel {
  FeedbackModel? _feedback;
  bool _isMarkedReviewed = false;
  bool _showReplyField = false;
  final TextEditingController replyController = TextEditingController();

  // For displaying the reply in UI after sending
  String? _currentReplyMessage;
  String? _currentReplyDate;

  FeedbackModel? get feedback => _feedback;
  bool get isMarkedReviewed => _isMarkedReviewed;
  bool get showReplyField => _showReplyField;
  String? get currentReplyMessage => _currentReplyMessage;
  String? get currentReplyDate => _currentReplyDate;

  void initialize(FeedbackModel feedback) {
    _feedback = feedback;
    _isMarkedReviewed = feedback.status == 'Reviewed';
    // If already replied, populate the view
    _currentReplyMessage = feedback.messageReply;
    if (feedback.replyAt != null) {
      _currentReplyDate =
          "${feedback.replyAt!.day}/${feedback.replyAt!.month}/${feedback.replyAt!.year}";
    }
    notifyListeners();
  }

  void toggleReplyField() {
    _showReplyField = !_showReplyField;
    notifyListeners();
  }

  Future<void> sendReply(BuildContext context) async {
    final text = replyController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply message')),
      );
      return;
    }

    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      final adminName =
          adminUser?.displayName ?? 'Admin'; // Or fetch from your admin profile

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(_feedback!.id)
          .update({
            'messageReply': text,
            'replyBy': adminName,
            'replyAt': FieldValue.serverTimestamp(),
            'status': 'Replied',
          });

      // Update Local State for UI
      final now = DateTime.now();
      _currentReplyMessage = text;
      _currentReplyDate = "${now.day}/${now.month}/${now.year}";
      _showReplyField = false;
      replyController.clear();
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error replying: $e')));
      }
    }
  }

  Future<void> markAsReviewed(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(_feedback!.id)
          .update({'status': 'Reviewed'});

      _isMarkedReviewed = true;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as reviewed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteFeedback(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(_feedback!.id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context); // Go back to list
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }
}
