// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final String userEmail; // Added this
  final String category;
  final String title;
  final String message;
  final int rating;
  final String status;
  final DateTime createdAt;
  
  // Admin Reply Fields
  final String? messageReply;
  final String? replyBy;
  final DateTime? replyAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userEmail, // Added this
    required this.category,
    required this.title,
    required this.message,
    required this.rating,
    required this.status,
    required this.createdAt,
    this.messageReply,
    this.replyBy,
    this.replyAt,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? 'Anonymous', // Fetch from DB
      category: data['feedbackCategory'] ?? '',
      title: data['feedbackTitle'] ?? '',
      message: data['feedbackDesc'] ?? '',
      rating: (data['rating'] ?? 0).toInt(),
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      messageReply: data['messageReply'],
      replyBy: data['replyBy'],
      replyAt: data['replyAt'] != null ? (data['replyAt'] as Timestamp).toDate() : null,
    );
  }
}