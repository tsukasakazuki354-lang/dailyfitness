import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String addressId;
  final String userId;
  final String region;
  final String provinceCity;
  final String municipality;
  final String barangay;
  final String streetAddress;
  final String zipCode;
  final bool isDefault;
  final Timestamp createdAt;

  Address({
    required this.addressId,
    required this.userId,
    required this.region,
    required this.provinceCity,
    required this.municipality,
    required this.barangay,
    required this.streetAddress,
    required this.zipCode,
    required this.isDefault,
    required this.createdAt,
  });

  factory Address.fromMap(Map<String, dynamic> data) {
    return Address(
      addressId: data['addressId'] ?? '',
      userId: data['userId'] ?? '',
      region: data['region'] ?? '',
      provinceCity: data['provinceCity'] ?? '',
      municipality: data['municipality'] ?? '',
      barangay: data['barangay'] ?? '',
      streetAddress: data['streetAddress'] ?? '',
      zipCode: data['zipCode'] ?? '',
      isDefault: data['isDefault'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addressId': addressId,
      'userId': userId,
      'region': region,
      'provinceCity': provinceCity,
      'municipality': municipality,
      'barangay': barangay,
      'streetAddress': streetAddress,
      'zipCode': zipCode,
      'isDefault': isDefault,
      'createdAt': createdAt,
    };
  }
}
