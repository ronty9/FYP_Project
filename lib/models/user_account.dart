// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.joinDate,
    required this.status,
    this.phone,
    this.petsCount = 0,
  });

  final String id;
  final String name;
  final String email;
  final String joinDate;
  final String status;
  final String? phone;
  final int petsCount;

  UserAccount copyWith({
    String? id,
    String? name,
    String? email,
    String? joinDate,
    String? status,
    String? phone,
    int? petsCount,
  }) {
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      petsCount: petsCount ?? this.petsCount,
    );
  }

  factory UserAccount.fromMap(String id, Map<String, dynamic> data) {
    return UserAccount(
      id: id,
      name: (data['userName'] ?? 'User').toString(),
      email: (data['userEmail'] ?? '').toString(),
      joinDate: (data['joinDate'] ?? '').toString(),
      status: (data['accountStatus'] ?? 'Active').toString(),
      phone: data['userPhone']?.toString(),
      petsCount: data['petsCount'] is int ? data['petsCount'] as int : 0,
    );
  }
}
