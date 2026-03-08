import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'guardian' or 'patient'
  final String? name;
  final int? age;
  final double? height; // in cm
  final double? weight; // in kg
  final String? bloodGroup;
  final String? profileImageBase64;
  final String? address;
  final String? phone;
  final String? linkCode; // For guardians to share
  final List<String> linkedUids; // List of linked patient UIDs (for guardians)
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.age,
    this.height,
    this.weight,
    this.bloodGroup,
    this.profileImageBase64,
    this.address,
    this.phone,
    this.linkCode,
    this.linkedUids = const [],
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'blood_group': bloodGroup,
      'profile_image_base64': profileImageBase64,
      'address': address,
      'phone': phone,
      'link_code': linkCode,
      'linked_uids': linkedUids,
      'created_at': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'patient',
      name: map['name'],
      age: map['age'],
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      bloodGroup: map['blood_group'],
      profileImageBase64: map['profile_image_base64'],
      address: map['address'],
      phone: map['phone'],
      linkCode: map['link_code'],
      linkedUids: List<String>.from(map['linked_uids'] ?? []),
      createdAt: map['created_at'] is Timestamp ? (map['created_at'] as Timestamp).toDate() : null,
    );
  }
}
