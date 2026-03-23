// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'base_view_model.dart';

class PrivacyPolicyItem {
  final String title;
  final String content;

  PrivacyPolicyItem({required this.title, required this.content});
}

class PrivacyPolicyViewModel extends BaseViewModel {
  final List<PrivacyPolicyItem> _policies = [
    PrivacyPolicyItem(
      title: '1. Data Collection',
      content:
          'We collect personal information such as your name, email address, and pet details to provide our services effectively. This data is stored securely on our servers.',
    ),
    PrivacyPolicyItem(
      title: '2. Usage of Information',
      content:
          'Your information is used to personalize your experience, provide health insights for your pets, and communicate important updates regarding our services.',
    ),
    PrivacyPolicyItem(
      title: '3. Data Sharing',
      content:
          'We do not sell your personal data to third parties. We may share anonymized data for research purposes or if required by law.',
    ),
    PrivacyPolicyItem(
      title: '4. Security Measures',
      content:
          'We implement industry-standard security measures, including encryption and secure socket layer technology, to protect your personal information.',
    ),
    PrivacyPolicyItem(
      title: '5. Your Rights',
      content:
          'You have the right to access, correct, or delete your personal data at any time. Contact our support team for assistance with these requests.',
    ),
  ];

  List<PrivacyPolicyItem> get policies => List.unmodifiable(_policies);
}
