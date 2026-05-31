import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String role;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phoneNumber;
  final String profileImage;
  final String status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  AppUser({
    required this.uid,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.profileImage,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      role: data['role'] ?? 'buyer',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profileImage: data['profileImage'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
