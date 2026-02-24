import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_view_model.dart';

class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class FaqCategory {
  const FaqCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<FaqItem> items;
}

// Helper class to store design info for categories
class _CategoryStyle {
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _CategoryStyle(this.icon, this.color, this.bgColor);
}

class HelpFaqViewModel extends BaseViewModel {
  // Master list (Contains ALL data)
  List<FaqCategory> _allCategories = [];

  // Filtered list (Displayed in UI)
  List<FaqCategory> _filteredCategories = [];

  bool _isLoading = true;

  // UI reads from this list
  List<FaqCategory> get categories => _filteredCategories;
  @override
  bool get isLoading => _isLoading;

  // --- Visual Configuration ---
  final Map<String, _CategoryStyle> _categoryStyles = {
    'Breed Identifier': const _CategoryStyle(
      Icons.pets,
      Colors.orange,
      Color(0xFFFFF3E0),
    ),
    'Skin Disease Identifier': const _CategoryStyle(
      Icons.healing,
      Colors.red,
      Color(0xFFFFEBEE),
    ),
    'Schedule & Reminders': const _CategoryStyle(
      Icons.calendar_today,
      Colors.blue,
      Color(0xFFE3F2FD),
    ),
    'Pet Profiles': const _CategoryStyle(
      Icons.badge_outlined,
      Colors.purple,
      Color(0xFFF3E5F5),
    ),
    'Account & Security': const _CategoryStyle(
      Icons.security,
      Colors.teal,
      Color(0xFFE0F2F1),
    ),
    'General Questions': const _CategoryStyle(
      Icons.help_outline,
      Colors.indigo,
      Color(0xFFE8EAF6),
    ),
  };

  final _CategoryStyle _defaultStyle = const _CategoryStyle(
    Icons.info_outline,
    Colors.grey,
    Color(0xFFF5F5F5),
  );

  HelpFaqViewModel() {
    fetchFaqs();
  }

  Future<void> fetchFaqs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('faq')
          .orderBy('updatedAt', descending: true)
          .get();

      final Map<String, List<FaqItem>> groupedItems = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final categoryTitle =
            data['category'] as String? ?? 'General Questions';
        final question = data['question'] as String? ?? '';
        final answer = data['answer'] as String? ?? '';

        if (!groupedItems.containsKey(categoryTitle)) {
          groupedItems[categoryTitle] = [];
        }

        groupedItems[categoryTitle]!.add(
          FaqItem(question: question, answer: answer),
        );
      }

      _allCategories = groupedItems.entries.map((entry) {
        final title = entry.key;
        final items = entry.value;
        final style = _categoryStyles[title] ?? _defaultStyle;

        return FaqCategory(
          title: title,
          icon: style.icon,
          color: style.color,
          bgColor: style.bgColor,
          items: items,
        );
      }).toList();

      // Sort categories
      _allCategories.sort((a, b) {
        final keys = _categoryStyles.keys.toList();
        final indexA = keys.indexOf(a.title);
        final indexB = keys.indexOf(b.title);
        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
        return a.title.compareTo(b.title);
      });

      // Initially, filtered list is the same as the master list
      _filteredCategories = List.from(_allCategories);
    } catch (e) {
      print("Error fetching FAQs: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- SEARCH FUNCTIONALITY ---
  void search(String query) {
    if (query.isEmpty) {
      // Reset to show all
      _filteredCategories = List.from(_allCategories);
    } else {
      final lowerQuery = query.toLowerCase();

      // Filter logic:
      // 1. Go through each category.
      // 2. Filter the items INSIDE that category.
      // 3. If a category has matching items, keep it. If empty, remove it.

      _filteredCategories = _allCategories
          .map((category) {
            final matchingItems = category.items.where((item) {
              return item.question.toLowerCase().contains(lowerQuery) ||
                  item.answer.toLowerCase().contains(lowerQuery);
            }).toList();

            if (matchingItems.isEmpty) {
              return null; // Drop category if no matches
            }

            // Return a copy of the category with ONLY matching items
            return FaqCategory(
              title: category.title,
              icon: category.icon,
              color: category.color,
              bgColor: category.bgColor,
              items: matchingItems,
            );
          })
          .whereType<FaqCategory>()
          .toList(); // Filter out the nulls
    }
    notifyListeners();
  }
}
