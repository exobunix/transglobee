// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? fullName;
  String? slug;
  String? id;
  String? email;
  String? loginType;
  String? profilePic;
  String? dateOfBirth;
  String? fcmToken;
  String? countryCode;
  String? phoneNumber;
  String? walletAmount;
  String? gender;
  bool? isActive;
  Timestamp? createdAt;
  String? password;
  List<UserRouteModel>? assignedRoutes;

  UserModel(
      {this.fullName,
      this.slug,
      this.id,
      this.isActive,
      this.dateOfBirth,
      this.email,
      this.loginType,
      this.profilePic,
      this.fcmToken,
      this.countryCode,
      this.phoneNumber,
      this.walletAmount,
      this.gender,
      this.createdAt,
      this.password,
      this.assignedRoutes});

  @override
  String toString() {
    return 'UserModel{fullName: $fullName, slug: $slug, id: $id, email: $email, loginType: $loginType, profilePic: $profilePic, dateOfBirth: $dateOfBirth, fcmToken: $fcmToken, countryCode: $countryCode, phoneNumber: $phoneNumber, walletAmount: $walletAmount, gender: $gender, isActive: $isActive, createdAt: $createdAt, password: $password}';
  }

  UserModel.fromJson(Map<String, dynamic> json) {
    fullName = json['fullName'] ?? json['name'] ?? "";
    slug = json['slug'] ?? "";
    id = json['id'] ?? json['_id'] ?? "";
    email = json['email'];
    loginType = json['loginType'];
    profilePic = json['profilePic'] ?? json['imageUrl'];
    fcmToken = json['fcmToken'];
    countryCode = json['countryCode'];
    phoneNumber = json['phoneNumber'] ?? json['mobileNumber'] ?? "";
    walletAmount = json['walletAmount']?.toString() ?? json['walletBalance']?.toString() ?? "0";
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        try {
          createdAt = Timestamp.fromDate(DateTime.parse(json['createdAt']));
        } catch (_) {}
      } else if (json['createdAt'] is Timestamp) {
        createdAt = json['createdAt'];
      }
    }
    gender = json['gender'];
    dateOfBirth = json['dateOfBirth'] ?? '';
    isActive = json['isActive'] ?? (json['status'] == 'active');
    password = json['password'] ?? json['plainPassword'] ?? "";
    if (json['assignedRoutes'] != null) {
      assignedRoutes = [];
      json['assignedRoutes'].forEach((v) {
        if (v is Map) {
          assignedRoutes!.add(UserRouteModel.fromJson(Map<String, dynamic>.from(v)));
        } else if (v is String) {
          assignedRoutes!.add(UserRouteModel(id: v, name: v));
        }
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fullName'] = fullName;
    data['slug'] = slug;
    data['id'] = id;
    data['email'] = email;
    data['loginType'] = loginType;
    data['profilePic'] = profilePic;
    data['fcmToken'] = fcmToken;
    data['countryCode'] = countryCode;
    data['phoneNumber'] = phoneNumber;
    data['walletAmount'] = walletAmount;
    data['createdAt'] = createdAt;
    data['gender'] = gender;
    data['dateOfBirth'] = dateOfBirth;
    data['isActive'] = isActive;
    data['password'] = password;
    if (assignedRoutes != null) {
      data['assignedRoutes'] = assignedRoutes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class UserRouteModel {
  String? id;
  String? name;
  String? source;
  String? destination;

  UserRouteModel({this.id, this.name, this.source, this.destination});

  UserRouteModel.fromJson(Map<String, dynamic> json) {
    id = json['_id'] ?? json['id'] ?? "";
    name = json['name'] ?? "";
    source = json['source'] ?? "";
    destination = json['destination'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = id;
    data['name'] = name;
    data['source'] = source;
    data['destination'] = destination;
    return data;
  }
}
