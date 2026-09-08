import 'package:flutter/material.dart';

class AddressEntry {
  final String id;
  final String label;
  final String fullAddress;
  final String? houseNumber;
  final String? floorNumber;
  final String? landmark;
  final String city;
  final String? district;
  final String pincode;
  final String? phone;
  final String? email;
  final String type; // 'pickup' or 'received'
  final IconData icon;

  AddressEntry({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.houseNumber,
    this.floorNumber,
    this.landmark,
    required this.city,
    this.district,
    required this.pincode,
    this.phone,
    this.email,
    required this.type,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'fullAddress': fullAddress,
      'houseNumber': houseNumber ?? '',
      'floorNumber': floorNumber ?? '',
      'landmark': landmark ?? '',
      'city': city,
      'district': district ?? '',
      'pincode': pincode,
      'phone': phone ?? '',
      'email': email ?? '',
      'type': type,
      'iconCode': icon.codePoint,
    };
  }

  factory AddressEntry.fromJson(Map<String, dynamic> json) {
    return AddressEntry(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      fullAddress: json['fullAddress']?.toString() ?? '',
      houseNumber: json['houseNumber']?.toString(),
      floorNumber: json['floorNumber']?.toString(),
      landmark: json['landmark']?.toString(),
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString(),
      pincode: json['pincode']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      type: json['type']?.toString() ?? 'pickup',
      icon: _getIconFromCode(json['iconCode'] as int?),
    );
  }

  static IconData _getIconFromCode(int? code) {
    if (code == null) return Icons.location_on_rounded;
    if (code == Icons.home_rounded.codePoint) return Icons.home_rounded;
    if (code == Icons.work_rounded.codePoint) return Icons.work_rounded;
    if (code == Icons.location_on_rounded.codePoint) return Icons.location_on_rounded;
    if (code == Icons.star_rounded.codePoint) return Icons.star_rounded;
    if (code == Icons.favorite_rounded.codePoint) return Icons.favorite_rounded;
    return Icons.location_on_rounded;
  }
}
