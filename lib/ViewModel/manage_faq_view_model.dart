// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_view_model.dart';

// 1. Data Model for FAQ
class AdminFaqItem {
  final String id;
  final String question;
  final String answer;
  final String categoryTitle;

  AdminFaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.categoryTitle,
  });

  factory AdminFaqItem.fromMap(Map<String, dynamic> data, String docId) {
    return AdminFaqItem(
      id: docId,
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      categoryTitle: data['category'] ?? 'General Questions',
    );
  }
}

// 2. Visual Style Definition
class FaqCategoryDef {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;

  FaqCategoryDef({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class ManageFAQViewModel extends BaseViewModel {
  // --- Visual Definitions ---
  final List<FaqCategoryDef> _categoryDefinitions = [
    FaqCategoryDef(
      title: 'Breed Identifier',
      icon: Icons.pets,
      color: Colors.orange,
      bgColor: const Color(0xFFFFF3E0),
    ),
    FaqCategoryDef(
      title: 'Skin Disease Identifier',
      icon: Icons.healing,
      color: Colors.red,
      bgColor: const Color(0xFFFFEBEE),
    ),
    FaqCategoryDef(
      title: 'Schedule & Reminders',
      icon: Icons.calendar_today,
      color: Colors.blue,
      bgColor: const Color(0xFFE3F2FD),
    ),
    FaqCategoryDef(
      title: 'Pet Profiles',
      icon: Icons.badge_outlined,
      color: Colors.purple,
      bgColor: const Color(0xFFF3E5F5),
    ),
    FaqCategoryDef(
      title: 'Account & Security',
      icon: Icons.security,
      color: Colors.teal,
      bgColor: const Color(0xFFE0F2F1),
    ),
    FaqCategoryDef(
      title: 'General Questions',
      icon: Icons.help_outline,
      color: Colors.indigo,
      bgColor: const Color(0xFFE8EAF6),
    ),
  ];

  // --- Data State ---
  List<AdminFaqItem> _faqs = [];
  bool _isLoading = true;

  List<FaqCategoryDef> get categoryDefinitions => _categoryDefinitions;
  List<AdminFaqItem> get faqs => _faqs;
  @override
  bool get isLoading => _isLoading;

  ManageFAQViewModel() {
    fetchFAQs();
  }

  // --- 1. FETCH FAQs ---
  Future<void> fetchFAQs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('faq')
          .orderBy(
            'id',
          ) // Optional: Order by ID to keep FA000001, FA000002... sorted
          .get();

      _faqs = snapshot.docs
          .map((doc) => AdminFaqItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching FAQs: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  List<AdminFaqItem> getFaqsByCategory(String categoryTitle) {
    return _faqs.where((faq) => faq.categoryTitle == categoryTitle).toList();
  }

  // --- 2. ADD FAQ (With Custom ID "FA000001") ---
  Future<void> addFAQ(String question, String answer, String category) async {
    final firestore = FirebaseFirestore.instance;
    // We use a separate collection to keep track of the count
    final counterRef = firestore.collection('counters').doc('faqCounter');

    try {
      await firestore.runTransaction((transaction) async {
        // A. Read the current count
        DocumentSnapshot counterSnapshot = await transaction.get(counterRef);

        int currentCount = 0;
        if (counterSnapshot.exists) {
          // Safely read the 'count' field
          final data = counterSnapshot.data() as Map<String, dynamic>;
          currentCount = data['count'] ?? 0;
        }

        // B. Calculate new ID
        int newCount = currentCount + 1;
        // Format: "FA" + 6 digits (padded with zeros) -> "FA000001"
        String customId = 'FA${newCount.toString().padLeft(6, '0')}';

        // C. Reference for the new FAQ document
        final faqRef = firestore.collection('faq').doc(customId);

        // D. Write operations (Must happen last in a transaction)
        // Update the counter
        transaction.set(counterRef, {'count': newCount});

        // Create the FAQ
        transaction.set(faqRef, {
          'id': customId, // Optional: Store ID inside the doc too
          'question': question,
          'answer': answer,
          'category': category,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Refresh UI logic
      fetchFAQs();
    } catch (e) {
      debugPrint("Error adding FAQ: $e");
    }
  }

  // --- 3. EDIT FAQ ---
  Future<void> editFAQ(
    String id,
    String question,
    String answer,
    String category,
  ) async {
    try {
      // Logic is the same, we just reference the existing ID
      await FirebaseFirestore.instance.collection('faq').doc(id).update({
        'question': question,
        'answer': answer,
        'category': category,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      fetchFAQs();
    } catch (e) {
      debugPrint("Error editing FAQ: $e");
    }
  }

  // --- 4. DELETE FAQ ---
  Future<void> deleteFAQ(String id) async {
    try {
      await FirebaseFirestore.instance.collection('faq').doc(id).delete();

      _faqs.removeWhere((f) => f.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting FAQ: $e");
    }
  }

  void onBackPressed(BuildContext context) {
    Navigator.pop(context);
  }
}
